//
//  TabsListManager.swift
//  catowser
//
//  Created by Andrei Ermoshin on 28/01/2019.
//  Copyright © 2019 Cotton (former Catowser). All rights reserved.
//

import DataServiceKit
import Foundation

/**
 Tabs list data service which can be used as a subject for observers.
 */
public actor TabsDataService: GenericDataServiceProtocol {
    public typealias Command = TabsServiceCommand
    public typealias ServiceData = TabsServiceDataOutput
    
    typealias UUIDStream = AsyncStream<UUID>
    typealias IntStream = AsyncStream<Int>

    /// Tabs selection strategy
    private let selectionStrategy: TabSelectionStrategy
    /// In memory storage for the tabs
    private var tabs: [CoreBrowser.Tab] = []
    /// Async stream for the selected tab id instead of using Combine's @Published
    private var selectedTabIdStream: UUIDStream!
    /// Async's stream continuation to notify about new id
    private var selectedTabIdInput: UUIDStream.Continuation!
    ///  Simple variable needed for direct sync access and for async getter
    private var selectedTabIdentifier: UUID
    /// Tabs count stream
    private var tabsCountStream: IntStream!
    /// Tabs count input for the async stream
    private var tabsCountInput: IntStream.Continuation!
    /// Database interface
    private let tabsRepository: TabsRepository
    /// Default positioning settings
    private let positioning: TabsStates
    /// A list of observers, usually some views which need to observer tabs count or changes to the tabs list
    private var tabObservers: [TabsObserverProxy]
    /// A subject for observing. Should be optional to be able to support iOS < 17.0
    private let tabsSubject: TabsDataSubjectProtocol?
    /// Type of observation, should be passed from the client app, change should require restart
    /// because subscribing usually happens in init or viewDidLoad during app start.
    private let observingType: ObservingApiType

    public init(
        _ tabsRepository: TabsRepository,
        _ positioning: TabsStates,
        _ selectionStrategy: TabSelectionStrategy,
        _ tabsSubject: TabsDataSubjectProtocol?,
        _ observingType: ObservingApiType = .observerDesignPattern
    ) async {
        self.tabsRepository = tabsRepository
        self.positioning = positioning
        self.selectionStrategy = selectionStrategy
        self.tabsSubject = tabsSubject
        self.tabObservers = []
        self.selectedTabIdentifier = positioning.defaultSelectedTabId
        self.observingType = observingType

        #if swift(>=5.9)
        let (tabIdStream, tabIdContinuation) = AsyncStream.makeStream(of: UUID.self)
        selectedTabIdStream = tabIdStream
        selectedTabIdInput = tabIdContinuation
        tabIdContinuation.yield(positioning.defaultSelectedTabId)
        let (countStream, countContinuation) = AsyncStream.makeStream(of: Int.self)
        tabsCountStream = countStream
        tabsCountInput = countContinuation
        #else
        self.selectedTabIdStream = UUIDStream { continuation in
            // A hack to be able to send values outside of the closure
            selectedTabIdInput = continuation
            continuation.yield(positioning.defaultSelectedTabId)
        }
        self.tabsCountStream = IntStream { continuation in
            tabsCountInput = continuation
        }
        #endif

        subscribeForTabsCountChange()
        subscribeForSelectedTabIdChange()

        do {
            try await fetchTabs()
        } catch {
            if ProcessInfo.unitTesting {
                print("Failed to init tabs data service: \(error)")
            } else {
                fatalError("Failed to init tabs data service: \(error)")
            }
        }
    }

    public func sendCommand(
        _ command: Command,
        _ input: ServiceData? = nil
    ) async -> ServiceData {
        switch command {
        case .getTabsCount:
            return handleTabsCountCommand()
        case .getSelectedTabId:
            return handleSelectedTabIdCommand()
        case .getAllTabs:
            return handleFetchAllTabsCommand()
        case .addTab(let value):
            return await handleAddTabCommand(value)
        case .closeTab(let value):
            return await handleCloseTabCommand(value)
        case .closeTabWithId(let value):
            return await handleCloseTabWithIdCommand(value)
        case .closeAll:
            return await handleCloseAllCommand()
        case .selectTab(let value):
            return await handleSelectTabCommand(value)
        case .replaceSelectedContent(let value):
            return await handleReplaceTabContentCommand(value)
        case .updateSelectedTabPreview(let value):
            return await handleUpdateSelectedTabPreviewCommand(value)
        }
    }
}

// MARK: - Main actor methods

private extension TabsDataService {
    /// If addedIndex is nil then it is an initial load
    @MainActor func notifyAboutNewTabs(
        _ tabs: [CoreBrowser.Tab],
        _ addedIndex: Int?
    ) async {
        tabsSubject?.tabs = tabs
        tabsSubject?.addedTabIndex = addedIndex
    }

    @MainActor func notifyAboutClearedTabs() async {
        tabsSubject?.tabs.removeAll()
    }

    @MainActor func notifyAboutNewSelectedTab(
        _ tabId: CoreBrowser.Tab.ID
    ) async {
        tabsSubject?.selectedTabId = tabId
    }

    @MainActor func notifyAboutReplacedTab(
        at tabIndex: Int,
        newTab: CoreBrowser.Tab
    ) async {
        tabsSubject?.tabs[tabIndex] = newTab
        tabsSubject?.replacedTabIndex = tabIndex
    }
}

// MARK: - Private functions

private extension TabsDataService {
    func handleTabsCountCommand() -> TabsServiceDataOutput {
        return .tabsCount(tabs.count)
    }

    func handleSelectedTabIdCommand() -> TabsServiceDataOutput {
        return .selectedTabId(selectedTabIdentifier)
    }

    func handleFetchAllTabsCommand() -> TabsServiceDataOutput {
        return .allTabs(tabs)
    }

    func handleAddTabCommand(_ tab: CoreBrowser.Tab) async -> TabsServiceDataOutput {
        let positionType = await positioning.addPosition
        let newIndex = positionType.addTab(tab, to: &tabs, selectedTabIdentifier)
        if observingType.isSystemObservation {
            await notifyAboutNewTabs(tabs, newIndex)
        } else {
            tabsCountInput.yield(tabs.count)
        }
        let needSelect = selectionStrategy.makeTabActiveAfterAdding
        do {
            let addedTab = try await tabsRepository.add(tab, select: needSelect)
            await handleTabAdded(addedTab, index: newIndex, select: needSelect)
        } catch {
            // It doesn't matter, on view level it must be added right away
            print("Failed to add this tab to cache: \(error)")
        }
        return .tabAdded
    }

    func handleCloseTabCommand(_ tab: CoreBrowser.Tab) async -> TabsServiceDataOutput {
        do {
            let removedTabs = try await tabsRepository.remove(tabs: [tab])
            // swiftlint:disable:next force_unwrapping
            await handleCachedTabRemove(removedTabs.first!)
        } catch {
            // tab view should be removed immediately on view level anyway
            print("Failure to remove tab from cache: \(error)")
        }
        return .tabClosed(tab.id)
    }

    func handleCloseTabWithIdCommand(_ tabId: UUID) async -> TabsServiceDataOutput {
        guard let tabToRemove = tabs.first(where: { $0.id == tabId }) else {
            return .tabClosed(nil)
        }
        return await handleCloseTabCommand(tabToRemove)
    }

    func handleCloseAllCommand() async -> TabsServiceDataOutput {
        let contentState = await positioning.contentState
        do {
            // because `tabs` field isolated to data service actor
            // and observer is another actor (main)
            //
            // workaround at https://forums.swift.org/t/
            // why-does-sending-a-sendable-value-risk-causing-data-races/73074/4
            //
            // need to create a local copy to unlink data from the actor
            let tabsCopy = tabs
            _ = try await tabsRepository.remove(tabs: tabsCopy)
            tabs.removeAll()
            if observingType.isSystemObservation {
                await notifyAboutClearedTabs()
            } else {
                tabsCountInput.yield(0)
            }
            let tab: CoreBrowser.Tab = .init(contentType: contentState)
            _ = try await tabsRepository.add(tab, select: true)
        } catch {
            // tab view should be removed immediately on view level anyway
            print("Failure to remove tab and reset to one tab: \(error)")
        }
        return .allTabsClosed
    }

    func handleSelectTabCommand(_ tab: CoreBrowser.Tab) async -> TabsServiceDataOutput {
        do {
            let identifier = try await tabsRepository.select(tab: tab)
            guard identifier != selectedTabIdentifier else {
                return .tabSelected
            }
            selectedTabIdentifier = identifier
            if observingType.isSystemObservation {
                await notifyAboutNewSelectedTab(identifier)
            } else {
                selectedTabIdInput.yield(identifier)
            }
        } catch {
            print("Failed to select tab with id \(tab.id) \(error)")
        }
        return .tabSelected
    }

    func handleReplaceTabContentCommand(_ tabContent: CoreBrowser.Tab.ContentType) async -> TabsServiceDataOutput {
        guard let tabTuple = tabs.element(by: selectedTabIdentifier) else {
            return .tabContentReplaced(TabsListError.notInitializedYet)
        }
        guard tabTuple.tab.contentType != tabContent else {
            return .tabContentReplaced(TabsListError.tabContentAlreadySet)
        }
        var newTab = tabTuple.tab
        let tabIndex = tabTuple.index
        newTab.contentType = tabContent
        newTab.previewData = nil

        do {
            _ = try tabsRepository.update(tab: newTab)
            tabs[tabIndex] = newTab
            if observingType.isSystemObservation {
                await notifyAboutReplacedTab(at: tabIndex, newTab: newTab)
            } else {
                // Need to notify observers to allow them to update title for tab view
                removeWeakObserversIfNeeded()
                for observer in tabObservers {
                    await observer.tabDidReplace(newTab, at: tabIndex)
                }
            }
            return .tabContentReplaced(nil)
        } catch {
            print("Failed to update tab content to storage \(error)")
            return .tabContentReplaced(TabsListError.failToUpdateTabContent)
        }
    }

    func handleUpdateSelectedTabPreviewCommand(_ image: Data?) async -> TabsServiceDataOutput {
        let defaultValue = positioning.defaultSelectedTabId
        guard selectedTabIdentifier != defaultValue else {
            return .tabPreviewUpdated(TabsListError.notInitializedYet)
        }
        guard let tabTuple = tabs.element(by: selectedTabIdentifier) else {
            return .tabPreviewUpdated(TabsListError.selectedNotFound)
        }
        var tab = tabTuple.tab
        guard let tabTuple = tabs.element(by: selectedTabIdentifier) else {
            return .tabPreviewUpdated(TabsListError.notInitializedYet)
        }
        let tabIndex = tabTuple.index

        if case .site = tab.contentType, image == nil {
            return .tabPreviewUpdated(TabsListError.wrongTabContent)
        }
        tab.previewData = image
        guard tabIndex >= 0 && tabIndex < tabs.count else {
            return .tabPreviewUpdated(TabsListError.wrongTabIndexToReplace)
        }
        tabs[tabIndex] = tab
        if observingType.isSystemObservation {
            await notifyAboutReplacedTab(at: tabIndex, newTab: tab)
        } else {
            // Most likely need to notify observers to allow them to update preview image?
            removeWeakObserversIfNeeded()
            for observer in tabObservers {
                await observer.tabDidReplace(tab, at: tabIndex)
            }
        }
        return .tabPreviewUpdated(nil)
    }
    
    func removeWeakObserversIfNeeded() {
        guard !tabObservers.isEmpty else {
            return
        }
        var copiedIndex = tabObservers.endIndex
        var removedAmount = 0
        for pair in tabObservers.enumerated() where pair.element.realSubject == nil {
            let elementToMove = tabObservers[copiedIndex]
            tabObservers[pair.offset] = elementToMove
            copiedIndex -= 1
            removedAmount += 1
        }
        tabObservers.removeLast(removedAmount)
    }
}

// MARK: - IndexSelectionContext protocol conformance

extension TabsDataService: IndexSelectionContext {
    public var collectionLastIndex: Int {
        get async {
            /// -1 index is not possible because always should be at least 1 tab
            let amount = tabs.count
            /// Leaving assert even with unit tests, https://stackoverflow.com/a/410198
            assert(amount != 0, "Tabs amount shouldn't be 0")
            return amount - 1
        }
    }

    public var currentlySelectedIndex: Int {
        get async {
            /// Leaving assert even with unit tests, https://stackoverflow.com/a/410198
            assert(!tabs.isEmpty, "Tabs amount shouldn't be 0")
            if let tabTuple = tabs.element(by: selectedTabIdentifier) {
                return tabTuple.index
            }
            /// tabs collection shouldn't be empty, so, it is safe to return index of 1st element
            return 0
        }
    }
}

// MARK: - TabsSubject protocol conformance

extension TabsDataService: TabsSubject {
    public func attach(
        _ observer: TabsObserver,
        notify: Bool = false
    ) async {
        // need to check if observer is already attached
        for attachedObserver in tabObservers where attachedObserver.realSubject === observer {
            // found the same address, so that, the same observer
            // is already present in the subject
            return
        }
        // This is a new observer, need to add it.
        // Wrapping an observer to be able to store it by weak reference
        // 1). to avoid any reference cycles
        // 2). to avoid requirement to call `detach`
        let proxyWrapper = TabsObserverProxy(observer)
        tabObservers.append(proxyWrapper)
        guard notify else {
            return
        }
        await observer.updateTabsCount(with: tabs.count)
        // because `tabs` field isolated to data service actor
        // and observer is another actor (main)
        //
        // workaround at https://forums.swift.org/t/
        // why-does-sending-a-sendable-value-risk-causing-data-races/73074/4
        //
        // need to create a local copy to unlink data from the actor
        let tabsCopy = tabs
        await observer.initializeObserver(with: tabsCopy)
        let defaultValue = positioning.defaultSelectedTabId
        guard selectedTabIdentifier != defaultValue else {
            return
        }
        guard let tabTuple = tabs.element(by: selectedTabIdentifier) else {
            return
        }
        await observer.tabDidSelect(tabTuple.index, tabTuple.tab.contentType, tabTuple.tab.id)
    }
}

// MARK: - private functions

private extension TabsDataService {
    func handleTabAdded(
        _ tab: CoreBrowser.Tab,
        index: Int,
        select: Bool
    ) async {
        /// can select new tab only after adding it, this is because corresponding view should be in the list
        switch positioning.addSpeed {
        case .immediately:
            removeWeakObserversIfNeeded()
            for observer in tabObservers {
                await observer.tabDidAdd(tab, at: index)
            }
            if select {
                selectedTabIdentifier = tab.id
                if observingType.isSystemObservation {
                    await notifyAboutNewSelectedTab(tab.id)
                } else {
                    selectedTabIdInput.yield(tab.id)
                }
            }
        case .after(let interval):
            do {
                if #available(iOS 16, *) {
                    try await Task.sleep(for: interval.dispatchValue)

                } else {
                    try await Task.sleep(nanoseconds: interval.inNanoseconds)
                }
                removeWeakObserversIfNeeded()
                for observer in tabObservers {
                    await observer.tabDidAdd(tab, at: index)
                }
                if select {
                    if observingType.isSystemObservation {
                        await notifyAboutNewSelectedTab(tab.id)
                    } else {
                        selectedTabIdentifier = tab.id
                        selectedTabIdInput.yield(tab.id)
                    }
                }
            } catch {
                print("Failed to wait before adding a new tab: \(error)")
            }
        }
    }

    func handleCachedTabRemove(_ tab: CoreBrowser.Tab) async {
        /// if it is a last tab - replace it with a tab with default content
        /// browser can't function without at least one tab
        /// so, this is kind of a side effect of removing the only one last tab
        if tabs.count == 1 {
            tabs.removeAll()
            if observingType.isSystemObservation {
                await notifyAboutClearedTabs()
            } else {
                tabsCountInput.yield(0)
            }
            let contentState = await positioning.contentState
            let tab: CoreBrowser.Tab = .init(contentType: contentState)
            _ = await sendCommand(.addTab(tab))
        } else {
            guard let closedTabIndex = tabs.firstIndex(of: tab) else {
                fatalError("Closing non existing tab")
            }
            let newIndex = await selectionStrategy.autoSelectedIndexAfterTabRemove(
                self,
                removedIndex: closedTabIndex
            )
            /// need to remove it before changing selected index
            /// otherwise in one case the handler will select closed tab
            tabs.remove(at: closedTabIndex)
            if observingType.isSystemObservation {
                await notifyAboutNewTabs(tabs, nil)
            } else {
                tabsCountInput.yield(tabs.count)
            }
            guard let selectedTab = tabs[safe: newIndex] else {
                fatalError("Failed to find new selected tab")
            }
            selectedTabIdentifier = selectedTab.id
            if observingType.isSystemObservation {
                await notifyAboutNewSelectedTab(selectedTab.id)
            } else {
                selectedTabIdInput.yield(selectedTab.id)
            }
        }
    }

    func fetchTabs() async throws {
        var cachedTabs = try await tabsRepository.fetchAllTabs()
        if cachedTabs.isEmpty {
            let tab = CoreBrowser.Tab(contentType: await positioning.contentState)
            let savedTab = try await tabsRepository.add(tab, select: true)
            cachedTabs = [savedTab]
        }
        let id = try await tabsRepository.fetchSelectedTabId()
        guard !cachedTabs.isEmpty else {
            return
        }
        tabs = cachedTabs
        selectedTabIdentifier = id
        if observingType.isSystemObservation {
            await notifyAboutNewTabs(cachedTabs, nil)
            await notifyAboutNewSelectedTab(id)
        } else {
            tabsCountInput.yield(cachedTabs.count)
            selectedTabIdInput.yield(id)
        }
    }

    func subscribeForTabsCountChange() {
        /// This method can't be async, have to use new Task.
        /// ! Forgot to explain why it can't be async!! everything in it requires it, but I'm guessing the AsyncStream
        /// doesn't like it somehow.
        ///
        /// This unstructured task will use data service actor instead of global or main actors.
        Task {
            for await newTabsCount in tabsCountStream {
                for observer in self.tabObservers {
                    await observer.updateTabsCount(with: newTabsCount)
                }
            }
        }
    }

    func subscribeForSelectedTabIdChange() {
        /// This method can't be async - it blocks init,  so have to use new task to avoid this.
        let defaultValue = positioning.defaultSelectedTabId
        Task {
            let filteredId = selectedTabIdStream.drop(while: { identifier in
                return identifier == defaultValue
            })

            for await newSelectedTabId in filteredId {
                guard let tabTuple = tabs.element(by: newSelectedTabId) else {
                    continue
                }
                for observer in tabObservers {
                    await observer.tabDidSelect(
                        tabTuple.index,
                        tabTuple.tab.contentType,
                        tabTuple.tab.id
                    )
                }
            }
        }
    }
}

// MARK: - Array extension

fileprivate extension Array where Element == CoreBrowser.Tab {
    func element(by uuid: UUID) -> (tab: CoreBrowser.Tab, index: Int)? {
        for (ix, tab) in self.enumerated() where tab.id == uuid {
            return (tab, ix)
        }
        return nil
    }
}

// MARK: - AddedTabPosition extension

extension AddedTabPosition {
    func addTab(_ tab: CoreBrowser.Tab,
                to tabs: inout [CoreBrowser.Tab],
                _ currentlySelectedId: UUID) -> Int {
        let newIndex: Int
        switch self {
        case .listEnd:
            tabs.append(tab)
            newIndex = tabs.count - 1
        case .afterSelected:
            guard let tabTuple = tabs.element(by: currentlySelectedId) else {
                /// no previously selected tab, probably when reset to one tab happend
                tabs.append(tab)
                return tabs.count - 1
            }
            newIndex = tabTuple.index + 1
            tabs.insert(tab, at: newIndex)
        }
        return newIndex
    }
}
