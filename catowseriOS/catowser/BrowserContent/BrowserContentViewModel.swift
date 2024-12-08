//
//  BrowserContentViewModel.swift
//  catowser
//
//  Created by Andrei Ermoshin on 12/17/22.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import SwiftUI
import CoreBrowser
import CottonPlugins
import FeatureFlagsKit
import CottonDataServices

/// Content view model which observes for the currently selected tab content type.
/// This reference type should be used to update the view if content changes.
@MainActor final class BrowserContentViewModel: ObservableObject {
    /// View content type. https://stackoverflow.com/a/56724174
    @Published var contentType: CoreBrowser.Tab.ContentType
    /// Tab's content loading
    @Published var loading: Bool
    /// Web view needs an update after changing selected tab content.
    /// Void type can be used because this model only can set it to true.
    @Published var webViewNeedsUpdate: Void
    /// Tabs count
    @Published var tabsCount: Int
    /// JS plugins builder reference
    let jsPluginsBuilder: any JSPluginsSource
    /// Not initialized, will be initialized after `TabsListManager`
    /// during tab opening. Used only during tab opening for optimization
    private var previousTabContent: CoreBrowser.Tab.ContentType?
    /// To avoid app start case
    private var firstTabContentSelect: Bool
    /// Feature manager to determine which observing method to use
    private let featureManager: FeatureManager.StateHolder
    /// UI service registry
    private let uiServiceRegistry: UIServiceRegistry

    init(
        _ jsPluginsBuilder: any JSPluginsSource,
        _ defaultContentType: CoreBrowser.Tab.ContentType,
        _ featureManager: FeatureManager.StateHolder,
        _ uiServiceRegistry: UIServiceRegistry
    ) {
        firstTabContentSelect = true
        self.jsPluginsBuilder = jsPluginsBuilder
        self.contentType = defaultContentType
        self.featureManager = featureManager
        self.uiServiceRegistry = uiServiceRegistry
        loading = true
        webViewNeedsUpdate = ()
        tabsCount = 0
        
        Task {
            let observingType = await featureManager.observingApiTypeValue()
            if #available(iOS 17.0, *), observingType.isSystemObservation {
                startTabsObservation()
                await readTabsState()
            } else {
                // handled in `MainBrowserView`
            }
        }
        // Fallback for before iOS 17 is outside in
        // `MainBrowserView.onAppear` by calling `attach`
    }
    
    @available(iOS 17.0, *)
    private func readTabsState() async {
        await handleSelectedTabChange()
        await handleTabsCountChange()
    }
    
    @available(iOS 17.0, *)
    @MainActor
    private func startTabsObservation() {
        withObservationTracking {
            _ = uiServiceRegistry.tabsSubject.selectedTabId
        } onChange: {
            Task { [weak self] in
                await self?.handleSelectedTabChange()
            }
        }
        withObservationTracking {
            _ = uiServiceRegistry.tabsSubject.tabsCount
        } onChange: {
            Task { [weak self] in
                await self?.handleTabsCountChange()
            }
        }
        withObservationTracking {
            _ = uiServiceRegistry.tabsSubject.replacedTabIndex
        } onChange: {
            Task { [weak self] in
                await self?.handleReplacedTabChange()
            }
        }
    }
    
    
    @available(iOS 17.0, *)
    @MainActor
    private func handleSelectedTabChange() async {
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
    private func handleTabsCountChange() async {
        let count = uiServiceRegistry.tabsSubject.tabsCount
        await updateTabsCount(with: count)
    }
    
    @available(iOS 17.0, *)
    @MainActor
    private func handleReplacedTabChange() async {
        let subject = uiServiceRegistry.tabsSubject
        guard let index = subject.replacedTabIndex else {
            return
        }
        await tabDidReplace(subject.tabs[index], at: index)
    }
}

extension BrowserContentViewModel: TabsObserver {
    func tabDidSelect(
        _ index: Int,
        _ content: CoreBrowser.Tab.ContentType,
        _ identifier: UUID
    ) async {
        if let previousValue = previousTabContent, previousValue.isStatic && previousValue == content {
            // Optimization to not do remove & insert of the same static view
            return
        }
        if loading {
            loading = false
        }
        // This is the only good place where to determine
        // if web view which can only be re-used in SwiftUI
        // and not re-created that it needs an update
        // because selected tab content was changed.
        // This can't be safely determined by comparing
        // currently used tab content with selected one
        if firstTabContentSelect {
            firstTabContentSelect = false
        } else {
            webViewNeedsUpdate = ()
        }

        if contentType != content {
            contentType = content
        }
    }

    func tabDidReplace(
        _ tab: CoreBrowser.Tab,
        at index: Int
    ) async {
        if loading {
            loading = false
        }
        if contentType != tab.contentType {
            contentType = tab.contentType
        }
    }

    func updateTabsCount(with tabsCount: Int) async {
        self.tabsCount = tabsCount
    }
}
