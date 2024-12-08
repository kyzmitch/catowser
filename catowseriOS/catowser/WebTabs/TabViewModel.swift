//
//  TabViewModel.swift
//  catowser
//
//  Created by Andrei Ermoshin on 7/22/23.
//  Copyright © 2023 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import Foundation
import CottonBase
import CoreBrowser
import FeatureFlagsKit
import CottonUseCases
import CottonDataServices

@MainActor
final class TabViewModel {
    private var tab: CoreBrowser.Tab
    private let readTabUseCase: ReadTabsUseCase
    private let writeTabUseCase: WriteTabsUseCase
    private let featureManager: FeatureManager.StateHolder
    private let uiServiceRegistry: UIServiceRegistry

    @Published var state: TabViewState

    init(_ tab: CoreBrowser.Tab,
         _ readTabUseCase: ReadTabsUseCase,
         _ writeTabUseCase: WriteTabsUseCase,
         _ featureManager: FeatureManager.StateHolder,
         _ uiServiceRegistry: UIServiceRegistry
    ) {
        self.tab = tab
        self.readTabUseCase = readTabUseCase
        self.writeTabUseCase = writeTabUseCase
        self.featureManager = featureManager
        self.uiServiceRegistry = uiServiceRegistry
        _state = .init(initialValue: .deSelected(tab.title, nil))
        
        Task {
            let observingType = await featureManager.observingApiTypeValue()
            if #available(iOS 17.0, *), observingType.isSystemObservation {
                startTabsObservation()
            }
        }
    }

    // MARK: - public functions

    func load() {
        Task {
            let selectedTabId = await readTabUseCase.selectedId
            let visualState = tab.getVisualState(selectedTabId)
            let favicon: ImageSource?
            if let site = tab.site {
                favicon = await TabViewModel.loadFavicon(site)
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

    func close() {
        if let site = tab.site {
            WebViewsReuseManager.shared.removeController(for: site)
        }
        Task {
            await writeTabUseCase.close(tab: tab)
        }
    }

    func activate() {
        print("\(#function): selected tab with id: \(tab.id)")
        Task {
            await writeTabUseCase.select(tab: tab)
        }
    }

    // MARK: - private

    /// Loading of favicon doesn't depend on `self`
    private static func loadFavicon(_ site: Site) async -> ImageSource? {
        if let hqImage = site.favicon() {
            return .image(hqImage)
        }
        let resolveNeeded = await FeatureManager.shared.boolValue(of: .dnsOverHTTPSAvailable)
        let url: URL?
        do {
            url = try await site.faviconURL(resolveNeeded)
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
    func startTabsObservation() {
        withObservationTracking {
            _ = uiServiceRegistry.tabsSubject.selectedTabId
        } onChange: {
            Task { [weak self] in
                await self?.handleSelectedTabChange()
            }
        }
        withObservationTracking {
            _ = uiServiceRegistry.tabsSubject.replacedTabIndex
        } onChange: {
            Task { [weak self] in
                await self?.observeReplacedTab()
            }
        }
    }
    
    @available(iOS 17.0, *)
    @MainActor
    func handleSelectedTabChange() async {
        let subject = uiServiceRegistry.tabsSubject
        let tabId = subject.selectedTabId
        guard let index = subject.tabs
            .firstIndex(where: { $0.id == tabId }) else {
            return
        }
        await tabDidSelect(index, subject.tabs[index].contentType, tabId)

    }
    
    @available(iOS 17.0, *)
    @MainActor
    private func observeReplacedTab() async {
        let subject = uiServiceRegistry.tabsSubject
        guard let index = subject.replacedTabIndex else {
            return
        }
        await tabDidReplace(subject.tabs[index], at: index)
    }
}

// MARK: - TabsObserver

extension TabViewModel: TabsObserver {
    func tabDidSelect(
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

    func tabDidReplace(
        _ tab: CoreBrowser.Tab,
        at index: Int
    ) async {
        guard self.tab.id == tab.id else {
            return
        }
        self.tab = tab
        let favicon: ImageSource?
        if let site = tab.site {
            favicon = await TabViewModel.loadFavicon(site)
        } else {
            favicon = nil
        }

        state = state.withNew(tab.title, favicon)
    }
}
