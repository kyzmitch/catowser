//
//  TabsListManager.swift
//  CottonDataServices
//
//  Created by Andrei Ermoshin on 28/01/2019.
//  Copyright © 2019 Cotton (former Catowser). All rights reserved.
//

import CoreBrowser
import DataServiceKit
import Foundation

/// Tabs list data service which can be used as a subject for observers.
actor TabsDataService: TabsDataServiceProtocol {
    
    typealias UUIDStream = AsyncStream<Tab.ID>
    typealias IntStream = AsyncStream<Int>

    /// Tabs selection strategy
    private let selectionStrategy: TabSelectionStrategy
    /// Async stream for the selected tab id instead of using Combine's @Published
    private var selectedTabIdStream: UUIDStream!
    /// Async's stream continuation to notify about new id
    private var selectedTabIdInput: UUIDStream.Continuation!
    /// Tabs count stream
    private var tabsCountStream: IntStream!
    /// Tabs count input for the async stream
    private var tabsCountInput: IntStream.Continuation!
    /// Database interface
    private let tabsRepository: TabsRepository
    /// Default positioning settings
    private let positioning: TabsStatesInterface
    /// A list of observers, usually some views which need to observer tabs count or changes to the tabs list
    private var tabObservers: [TabsObserverProxy]
    /// A subject for observing. Should be optional to be able to support iOS < 17.0
    private let tabsSubject: TabsDataSubjectProtocol?
    /// Type of observation, should be passed from the client app, change should require restart
    /// because subscribing usually happens in init or viewDidLoad during app start.
    private let observingType: ObservingApiType
    /// Service data
    public var serviceData: ServiceData
    
    /// tabs computed property
    var tabs: [CoreBrowser.Tab] {
        guard
            case let .finished(allTabsValue) = serviceData.allTabs,
            case let .success(tabs) = allTabsValue
        else {
            fatalError("Fail to fetch tabs array")
        }
        return tabs
    }
    
    /// Selected tab id computed property
    var selectedTabIdentifier: CoreBrowser.Tab.ID {
        guard
            case let .finished(value) = serviceData.selectedTabId,
            case let .success(identifier) = value
        else {
            return positioning.defaultSelectedTabId
        }
        return identifier
    }
    
    init(
        _ tabsRepository: TabsRepository,
        _ positioning: TabsStatesInterface,
        _ selectionStrategy: TabSelectionStrategy,
        _ tabsSubject: TabsDataSubjectProtocol?,
        _ observingType: ObservingApiType = .observerDesignPattern
    ) async {
        self.tabsRepository = tabsRepository
        self.positioning = positioning
        self.selectionStrategy = selectionStrategy
        self.tabsSubject = tabsSubject
        self.tabObservers = []
        self.observingType = observingType
        serviceData = .init()
        serviceData.selectedTabId = .finished(
            output: .success(
                positioning.defaultSelectedTabId
            )
        )

        #if swift(>=5.9)
        let (tabIdStream, tabIdContinuation) = AsyncStream.makeStream(of: Tab.ID.self)
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
        case .replaceContent(let value):
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
        guard let tabsSubject else {
            return
        }
        tabsSubject.tabs = tabs
        tabsSubject.addedTabIndex = addedIndex
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
        guard let tabsSubject else {
            return
        }
        tabsSubject.tabs[tabIndex] = newTab
        tabsSubject.replacedTabIndex = tabIndex
    }
}

// MARK: - Private functions

private extension TabsDataService {
    func handleTabsCountCommand() -> TabsServiceData {
        return serviceData
    }

    func handleSelectedTabIdCommand() -> TabsServiceData {
        return serviceData
    }

    func handleFetchAllTabsCommand() -> TabsServiceData {
        return serviceData
    }

    func handleAddTabCommand(_ tab: CoreBrowser.Tab) async -> TabsServiceData {
        let positionType = await positioning.addPosition
        guard
            case let .finished(allTabsValue) = serviceData.allTabs,
            case var .success(tabs) = allTabsValue,
            case let .finished(selectedTabValue) = serviceData.selectedTabId,
            case let .success(selectedTabIdentifier) = selectedTabValue
        else {
            serviceData.tabAdded = .finished(output: .failure(.noAnyTabs))
            return serviceData
        }
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
            serviceData.tabAdded = .finished(output: .success(newIndex))
        } catch {
            // It doesn't matter, on view level it must be added right away
            print("Failed to add this tab to cache: \(error)")
            serviceData.tabAdded = .finished(output: .failure(.repositoryFailure(error as NSError)))
        }
        return serviceData
    }

    func handleCloseTabCommand(_ tab: CoreBrowser.Tab) async -> TabsServiceData {
        do {
            let removedTabs = try await tabsRepository.remove(tabs: [tab])
            guard let removedTab = removedTabs.first else {
                throw TabsListError.failToRemoveTab
            }
            let newSelectedId = try await handleCachedTabRemove(removedTab)
            serviceData.tabClosed = .finished(output: .success(newSelectedId))
        } catch {
            // tab view should be removed immediately on view level anyway
            print("Failure to remove tab from cache: \(error)")
            serviceData.tabClosed = .finished(
                output: .failure(.repositoryFailure(error as NSError))
            )
        }
        return serviceData
    }

    func handleCloseTabWithIdCommand(_ tabId: Tab.ID) async -> TabsServiceData {
        guard
            case let .finished(allTabsValue) = serviceData.allTabs,
            case let .success(tabs) = allTabsValue
        else {
            serviceData.tabClosed = .finished(output: .failure(.noAnyTabs))
            return serviceData
        }
        let tabToRemove = tabs.first(where: { $0.id == tabId })
        guard let tabToRemove else {
            serviceData.tabClosed = .finished(output: .success(tabId))
            return serviceData
        }
        return await handleCloseTabCommand(tabToRemove)
    }

    func handleCloseAllCommand() async -> TabsServiceData {
        let contentState = await positioning.contentState
        guard
            case let .finished(allTabsValue) = serviceData.allTabs,
            case let .success(tabsCopy) = allTabsValue
        else {
            serviceData.allTabsClosed = .finished(output: .failure(.noAnyTabs))
            return serviceData
        }
        do {
            // because `tabs` field isolated to data service actor
            // and observer is another actor (main)
            //
            // workaround at https://forums.swift.org/t/
            // why-does-sending-a-sendable-value-risk-causing-data-races/73074/4
            //
            // need to create a local copy to unlink data from the actor
            _ = try await tabsRepository.remove(tabs: tabsCopy)
            // removing all the tabs
            serviceData.allTabs = .finished(output: .success([]))
            serviceData.tabsCount = .finished(output: .success(0))
            if observingType.isSystemObservation {
                await notifyAboutClearedTabs()
            } else {
                tabsCountInput.yield(0)
            }
            let tab: CoreBrowser.Tab = .init(contentType: contentState)
            _ = try await tabsRepository.add(tab, select: true)
            serviceData.allTabs = .finished(output: .success([tab]))
        } catch {
            // tab view should be removed immediately on view level anyway
            print("Failure to remove tab and reset to one tab: \(error)")
        }
        let void: Void = ()
        serviceData.allTabsClosed = .finished(output: .success(void))
        serviceData.tabsCount = .finished(output: .success(1))
        return serviceData
    }

    func handleSelectTabCommand(_ tab: CoreBrowser.Tab) async -> TabsServiceData {
        guard
            case let .finished(selectedTabValue) = serviceData.selectedTabId,
            case let .success(selectedTabIdentifier) = selectedTabValue
        else {
            serviceData.tabSelected = .finished(output: .failure(.selectedNotFound))
            return serviceData
        }
        do {
            let identifier = try await tabsRepository.select(tab: tab)
            let void: Void = ()
            guard identifier != selectedTabIdentifier else {
                print("Tab is already selected")
                serviceData.tabSelected = .finished(output: .success(void))
                return serviceData
            }
            serviceData.selectedTabId = .finished(output: .success(identifier))
            serviceData.tabSelected = .finished(output: .success(void))
            if observingType.isSystemObservation {
                await notifyAboutNewSelectedTab(identifier)
            } else {
                selectedTabIdInput.yield(identifier)
            }
        } catch {
            print("Failed to select tab with id \(tab.id) \(error)")
            serviceData.tabSelected = .finished(output: .failure(.repositoryFailure(error as NSError)))
        }
        return serviceData
    }

    func handleReplaceTabContentCommand(
        _ tabContent: CoreBrowser.Tab.ContentType
    ) async -> TabsServiceData {
        guard
            case let .finished(selectedTabValue) = serviceData.selectedTabId,
            case let .success(selectedTabIdentifier) = selectedTabValue
        else {
            serviceData.tabContentReplaced = .finished(output: .failure(.selectedNotFound))
            return serviceData
        }
        guard
            case let .finished(allTabsValue) = serviceData.allTabs,
            case var .success(tabs) = allTabsValue
        else {
            serviceData.tabContentReplaced = .finished(output: .failure(.noAnyTabs))
            return serviceData
        }
        guard let tabTuple = tabs.element(by: selectedTabIdentifier) else {
            serviceData.tabContentReplaced = .finished(output: .failure(.selectedNotFound))
            return serviceData
        }
        let void: Void = ()
        guard tabTuple.tab.contentType != tabContent else {
            serviceData.tabContentReplaced = .finished(output: .success(void))
            return serviceData
        }
        var newTab = tabTuple.tab
        let tabIndex = tabTuple.index
        newTab.contentType = tabContent
        newTab.previewData = nil

        do {
            _ = try tabsRepository.update(tab: newTab)
            tabs[tabIndex] = newTab
            serviceData.allTabs = .finished(output: .success(tabs))
            if observingType.isSystemObservation {
                await notifyAboutReplacedTab(at: tabIndex, newTab: newTab)
            } else {
                // Need to notify observers to allow them to update title for tab view
                removeWeakObserversIfNeeded()
                for observer in tabObservers {
                    await observer.tabDidReplace(newTab, at: tabIndex)
                }
            }
            serviceData.tabContentReplaced = .finished(output: .success(void))
            return serviceData
        } catch {
            print("Failed to update tab content to storage \(error)")
            serviceData.tabContentReplaced = .finished(output: .failure(.repositoryFailure(error as NSError)))
            return serviceData
        }
    }

    func handleUpdateSelectedTabPreviewCommand(_ image: Data?) async -> TabsServiceData {
        guard
            case let .finished(selectedTabValue) = serviceData.selectedTabId,
            case let .success(selectedTabIdentifier) = selectedTabValue
        else {
            serviceData.tabContentReplaced = .finished(output: .failure(.selectedNotFound))
            return serviceData
        }
        let defaultValue = positioning.defaultSelectedTabId
        guard selectedTabIdentifier != defaultValue else {
            serviceData.tabPreviewUpdated = .finished(output: .failure(.onlyDefaultTabPresent))
            return serviceData
        }
        guard
            case let .finished(allTabsValue) = serviceData.allTabs,
            case var .success(tabs) = allTabsValue
        else {
            serviceData.tabPreviewUpdated = .finished(output: .failure(.noAnyTabs))
            return serviceData
        }
        guard let tabTuple = tabs.element(by: selectedTabIdentifier) else {
            serviceData.tabPreviewUpdated = .finished(output: .failure(.selectedNotFound))
            return serviceData
        }
        var tab = tabTuple.tab
        guard let tabTuple = tabs.element(by: selectedTabIdentifier) else {
            serviceData.tabPreviewUpdated = .finished(output: .failure(.selectedNotFound))
            return serviceData
        }
        let tabIndex = tabTuple.index
        if case .site = tab.contentType, image == nil {
            serviceData.tabPreviewUpdated = .finished(output: .failure(.wrongTabContent))
            return serviceData
        }
        tab.previewData = image
        guard tabIndex >= 0 && tabIndex < tabs.count else {
            serviceData.tabPreviewUpdated = .finished(output: .failure(.wrongTabIndexToReplace))
            return serviceData
        }
        tabs[tabIndex] = tab
        serviceData.allTabs = .finished(output: .success(tabs))
        if observingType.isSystemObservation {
            await notifyAboutReplacedTab(at: tabIndex, newTab: tab)
        } else {
            // Most likely need to notify observers to allow them to update preview image?
            removeWeakObserversIfNeeded()
            for observer in tabObservers {
                await observer.tabDidReplace(tab, at: tabIndex)
            }
        }
        let void: Void = ()
        serviceData.tabPreviewUpdated = .finished(output: .success(void))
        return serviceData
    }
    
    func removeWeakObserversIfNeeded() {
        guard !tabObservers.isEmpty else {
            return
        }
        var indexToCopy = tabObservers.endIndex - 1
        // find first non-nil observer from the tail
        while true {
            guard tabObservers[indexToCopy].realSubject == nil else {
                break
            }
            indexToCopy -= 1
        }
        guard indexToCopy >= 0 else {
            // if all observers are nil, then do nothing
            return
        }
        var removedAmount = tabObservers.endIndex - indexToCopy
        // order of observers doesn't matter, so,
        // moving them from the tail of collection
        var foundNilObservers = false
        for pair in tabObservers.enumerated() where pair.element.realSubject == nil {
            foundNilObservers = true
            let elementToMove = tabObservers[indexToCopy]
            tabObservers[pair.offset] = elementToMove
            indexToCopy -= 1
            removedAmount += 1
        }
        if foundNilObservers {
            tabObservers.removeLast(removedAmount)
        }
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
        await observer.tabDidSelect(
            tabTuple.index,
            tabTuple.tab.contentType,
            tabTuple.tab.id
        )
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
                serviceData.selectedTabId = .finished(output: .success(tab.id))
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
                        serviceData.selectedTabId = .finished(output: .success(tab.id))
                        selectedTabIdInput.yield(tab.id)
                    }
                }
            } catch {
                print("Failed to wait before adding a new tab: \(error)")
            }
        }
    }

    /// Handles tab removal and returns new selected tab id if needed
    func handleCachedTabRemove(
        _ tab: CoreBrowser.Tab
    ) async throws(TabsListError) -> Tab.ID? {
        // if it is a last tab - replace it with a tab with default content
        // browser can't function without at least one tab
        // so, this is kind of a side effect of removing the only one last tab
        var tabs = tabs
        if tabs.count == 1 {
            tabs.removeAll()
            serviceData.selectedTabId = .finished(output: .success(positioning.defaultSelectedTabId))
            serviceData.allTabs = .finished(output: .success(tabs))
            serviceData.tabsCount = .finished(output: .success(0))
            if observingType.isSystemObservation {
                await notifyAboutClearedTabs()
            } else {
                tabsCountInput.yield(0)
            }
            let contentState = await positioning.contentState
            let tab = CoreBrowser.Tab(contentType: contentState)
            let updatedData = await sendCommand(.addTab(tab))
            guard case let .finished(result) = updatedData.tabAdded else {
                throw .failToAddDefaultTab
            }
            guard case .success = result else {
                throw .failToAddDefaultTab
            }
            return tab.id
        } else {
            guard let closedTabIndex = tabs.firstIndex(of: tab) else {
                throw .closingNonExistingTab
            }
            let newIndex = await selectionStrategy.autoSelectedIndexAfterTabRemove(
                context: self,
                removedIndex: closedTabIndex
            )
            // need to remove it before changing selected index
            // otherwise in one case the handler will select closed tab
            tabs.remove(at: closedTabIndex)
            serviceData.allTabs = .finished(output: .success(tabs))
            serviceData.tabsCount = .finished(output: .success(tabs.count))
            if observingType.isSystemObservation {
                await notifyAboutNewTabs(tabs, nil)
            } else {
                tabsCountInput.yield(tabs.count)
            }
            if let newIndex {
                // closed tab was selected, need to update the index
                guard let selectedTab = tabs[safe: newIndex] else {
                    throw .failToFindNewSelectedTab
                }
                serviceData.selectedTabId = .finished(output: .success(selectedTab.id))
                if observingType.isSystemObservation {
                    await notifyAboutNewSelectedTab(selectedTab.id)
                } else {
                    selectedTabIdInput.yield(selectedTab.id)
                }
                serviceData.selectedTabId = .finished(output: .success(selectedTab.id))
                return selectedTab.id
            } else {
                // selected tab and selected index stay the same
                return nil
            }
        }
    }

    func fetchTabs() async throws {
        async let cachedTabs = tabsRepository.fetchAllTabs()
        async let defaultContentType = positioning.contentState
        var cachedData = try await TabsAppStartInfo(
            cachedTabs,
            defaultContentType
        )
        let selectedTabId: Tab.ID
        if cachedData.tabs.isEmpty {
            let tab = CoreBrowser.Tab(contentType: cachedData.defaultContentType)
            let savedTab = try await tabsRepository.add(tab, select: true)
            cachedData.tabs = [savedTab]
            selectedTabId = tab.id
        } else {
            selectedTabId = try await tabsRepository.fetchSelectedTabId()
        }
        serviceData.allTabs = .finished(output: .success(cachedData.tabs))
        serviceData.tabsCount = .finished(output: .success(cachedData.tabs.count))
        serviceData.selectedTabId = .finished(output: .success(selectedTabId))
        if observingType.isSystemObservation {
            await notifyAboutNewTabs(cachedData.tabs, nil)
            await notifyAboutNewSelectedTab(selectedTabId)
        } else {
            tabsCountInput.yield(cachedData.tabs.count)
            selectedTabIdInput.yield(selectedTabId)
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
    func element(by id: Tab.ID) -> (tab: CoreBrowser.Tab, index: Int)? {
        for (ix, tab) in self.enumerated() where tab.id == id {
            return (tab, ix)
        }
        return nil
    }
}

// MARK: - AddedTabPosition extension

private extension AddedTabPosition {
    func addTab(
        _ tab: CoreBrowser.Tab,
        to tabs: inout [CoreBrowser.Tab],
        _ currentlySelectedId: UUID
    ) -> Int {
        let newIndex: Int
        switch self {
        case .listEnd:
            tabs.append(tab)
            newIndex = tabs.endIndex - 1
        case .afterSelected:
            guard let tabTuple = tabs.element(by: currentlySelectedId) else {
                /// no previously selected tab, probably when reset to one tab happend
                tabs.append(tab)
                return tabs.endIndex - 1
            }
            newIndex = tabTuple.index + 1
            tabs.insert(tab, at: newIndex)
        }
        return newIndex
    }
}

/// App start initial tabs data, this value type
/// is very usseful because it allows to
/// fetch tabs & default content in parallel
struct TabsAppStartInfo {
    /// tabs array
    var tabs: [Tab]
    /// default tab content
    let defaultContentType: Tab.ContentType
    
    init(
        _ tabs: [Tab],
        _ defaultContentType: Tab.ContentType
    ) {
        self.tabs = tabs
        self.defaultContentType = defaultContentType
    }
}
