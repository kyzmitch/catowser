//
//  TabViewModelImpl.swift
//  CottonViewModels
//
//  Created by Andrei Ermoshin on 7/22/23.
//  Copyright © 2023 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import Foundation
import Combine
import CottonBase
import CoreBrowser
import FeatureFlagsKit
import CottonUseCases
import CottonDataServices

/// Tab view model implementation
@MainActor final class TabViewModelImpl: TabViewModel {
    private var tab: CoreBrowser.Tab
    private let readTabUseCase: ReadTabsUseCase
    private let writeTabUseCase: WriteTabsUseCase
    private let context: TabViewModelContext
    private let featureManager: FeatureManager.StateHolder

    @Published public var state: TabViewState
    public var statePublisher: Published<TabViewState>.Publisher { $state }

    init(
        _ tab: CoreBrowser.Tab,
        _ readTabUseCase: ReadTabsUseCase,
        _ writeTabUseCase: WriteTabsUseCase,
        _ context: TabViewModelContext,
        _ featureManager: FeatureManager.StateHolder
    ) {
        self.tab = tab
        self.readTabUseCase = readTabUseCase
        self.writeTabUseCase = writeTabUseCase
        self.context = context
        self.featureManager = featureManager
        _state = .init(initialValue: .deSelected(tab.title, nil))
        
        Task {
            let observingType = await context.observingApiTypeValue
            if #available(iOS 17.0, *), observingType.isSystemObservation {
                startTabsObservation(await context.tabsSubject)
            }
        }
    }

    // MARK: - public functions

    public func load() {
        Task {
            let selectedTabId = await readTabUseCase.selectedId
            let visualState = tab.getVisualState(selectedTabId)
            let favicon: ImageSource?
            if let site = tab.site {
                favicon = await loadFavicon(site)
            } else {
                favicon = nil
            }
            switch visualState {
            case .selected:
                state = .selected(tab.title, favicon)
            case .deselected:
                state = .deSelected(tab.title, favicon)
            @unknown default:
                break
            }
        }
    }

    public func close() {
        if let site = tab.site {
            _ = context.removeWebView(for: site)
        }
        Task {
            do {
                _ = try await writeTabUseCase.close(tab: tab)
            } catch {
                print("Fail to close tab: \(error)")
            }
        }
    }

    public func activate() {
        print("\(#function): selected tab with id: \(tab.id)")
        Task {
            do {
                try await writeTabUseCase.select(tab: tab)
            } catch {
                print("Fail to select tab: \(error)")
            }
        }
    }

    // MARK: - private

    /// Loading of favicon doesn't depend on `self`
    private func loadFavicon(_ site: Site) async -> ImageSource? {
        if let hqImage = site.favicon() {
            return .image(hqImage)
        }
        let resolveNeeded = await context.isDohEnabled
        let url: URL?
        do {
            url = try await context.faviconURL(site, resolveNeeded)
        } catch {
            print("Fail to resolve favicon url: \(error)")
            url = nil
        }

        let source: ImageSource
        switch (url, site.favicon()) {
        case (let url?, nil):
            source = .url(url)
        case (nil, let image?):
            source = .image(image)
        case (let url?, let image?):
            source = .urlWithPlaceholder(url, image)
        default:
            return nil
        }
        return source
    }
    
    @available(iOS 17.0, *)
    @MainActor
    func startTabsObservation(_ tabsSubject: TabsDataSubject) {
        withObservationTracking {
            _ = tabsSubject.selectedTabId
        } onChange: {
            Task { [weak self] in
                await self?.handleSelectedTabChange(tabsSubject)
            }
        }
        withObservationTracking {
            _ = tabsSubject.replacedTabIndex
        } onChange: {
            Task { [weak self] in
                await self?.observeReplacedTab(tabsSubject)
            }
        }
    }
    
    @available(iOS 17.0, *)
    @MainActor
    func handleSelectedTabChange(_ tabsSubject: TabsDataSubject) async {
        let tabId = tabsSubject.selectedTabId
        guard let index = tabsSubject.tabs
            .firstIndex(where: { $0.id == tabId }) else {
            return
        }
        await tabDidSelect(index, tabsSubject.tabs[index].contentType, tabId)

    }
    
    @available(iOS 17.0, *)
    @MainActor
    private func observeReplacedTab(_ tabsSubject: TabsDataSubject) async {
        guard let index = tabsSubject.replacedTabIndex else {
            return
        }
        await tabDidReplace(tabsSubject.tabs[index], at: index)
    }
}

// MARK: - TabsObserver

extension TabViewModelImpl: TabsObserver {
    public func tabDidSelect(
        _ index: Int,
        _ content: CoreBrowser.Tab.ContentType,
        _ identifier: UUID
    ) async {
        if tab.contentType != content {
            /// Need to reload favicon and title as well.
            /// Not sure if it is possible during simple select?
        }
        /// Next code used to change tab's VisualState `tab.getVisualState(identifier)`
        if tab.id == identifier {
            state = state.selected()
        } else {
            state = state.deSelected()
        }
    }

    public func tabDidReplace(
        _ tab: CoreBrowser.Tab,
        at index: Int
    ) async {
        guard self.tab.id == tab.id else {
            return
        }
        self.tab = tab
        let favicon: ImageSource?
        if let site = tab.site {
            favicon = await loadFavicon(site)
        } else {
            favicon = nil
        }

        state = state.withNew(tab.title, favicon)
    }
}
