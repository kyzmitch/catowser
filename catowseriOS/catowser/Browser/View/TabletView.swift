//
//  TabletView.swift
//  catowser
//
//  Created by Andrei Ermoshin on 1/13/23.
//  Copyright © 2023 Cotton (former Catowser). All rights reserved.
//

import SwiftUI
import CoreBrowser
import FeatureFlagsKit
import CottonViewModels

struct TabletView<
    W: WebViewModel,
    S: SearchSuggestionsViewModel,
    SB: SearchBarViewModel
>: View {
    // MARK: - view models of subviews

    /// Search bar view model, can't be environment object (always nil for some reason)
    @ObservedObject private var searchBarVM: SB
    /// Separate field for the delegate (environment object for Search bar view model can't compile with it)
    private let delegatesHolder: SearchBarDelegateHolder
    /// A reference to created vm in main view
    @EnvironmentObject private var browserContentVM: BrowserContentViewModel
    /// Toolbar model needed by both UI modes
    @EnvironmentObject private var toolbarVM: BrowserToolbarViewModel
    /// Top sites view model is async dependency, so, can only be injected from outside
    @EnvironmentObject private var topSitesVM: TopSitesViewModel
    /// Search suggestions view model has async init
    @ObservedObject private var searchSuggestionsVM: S
    /// Web view model without a specific site
    @ObservedObject private var webVM: W
    /// All tabs view model specific only to table layout
    @EnvironmentObject private var allTabsVM: AllTabsViewModel

    // MARK: - Tablet search bar state

    /// Search bar action is only needed for SwiftUI UIKit wrapper
    @State private var searchBarAction: SearchBarAction = .clearView
    /// Search suggestion visibility state
    @State private var showSearchSuggestions: Bool = false
    /// Search query string state which is set by SearchBar and used by SearchSuggestions
    @State private var searchQuery: String = ""
    /// Tells if browser menu needs to be shown
    @State private var showingMenu: Bool = false
    /// Tabs counter
    @State private var tabsCount: Int = 0
    /// Needs to be fetched from global actor in task to know current value
    @State private var searchProviderType: WebAutoCompletionSource

    // MARK: - browser content state

    @State private var isLoading: Bool = true
    @State private var contentType: CoreBrowser.Tab.ContentType
    /// A workaround to avoid unnecessary web view updates
    @State private var webViewNeedsUpdate: Bool = false

    // MARK: - constants

    private let mode: SwiftUIMode

    // MARK: - menu

    @State private var isDohEnabled: Bool
    @State private var isJavaScriptEnabled: Bool
    @State private var nativeAppRedirectEnabled: Bool

    private var menuModel: MenuViewModel {
        let style: BrowserMenuStyle
        if let interface = toolbarVM.state.webViewInterface {
            style = .withSiteMenu(interface.host, interface.siteSettings)
        } else {
            style = .onlyGlobalMenu
        }

        return MenuViewModel(
            style,
            isDohEnabled,
            isJavaScriptEnabled,
            nativeAppRedirectEnabled
        )
    }

    init(
        _ mode: SwiftUIMode,
        _ defaultContentType: CoreBrowser.Tab.ContentType,
        _ webVM: W,
        _ searchVM: S,
        _ searchBarVM: SB,
        _ delegatesHolder: SearchBarDelegateHolder
    ) {
        self.webVM = webVM
        // search suggestions vm is used as a template argument later
        self.searchSuggestionsVM = searchVM
        self.searchBarVM = searchBarVM
        self.delegatesHolder = delegatesHolder
        self.contentType = defaultContentType
        self.mode = mode

        // Next states are set to some random "good" values
        // because actualy values need to be fetched from Global actor

        searchProviderType = .google
        isDohEnabled = false
        isJavaScriptEnabled = true
        nativeAppRedirectEnabled = true
    }

    var body: some View {
        switch mode {
        case .compatible:
            uiKitWrapperView
        case .full:
            fullySwiftUIView
        }
    }

    private var uiKitWrapperView: some View {
        VStack {
            let searchBarDelegate = delegatesHolder.searchBarDelegate
            TabletTabsView(mode)
            TabletSearchBarLegacyView(
                searchBarDelegate,
                searchBarAction,
                toolbarVM.state.webViewInterface
            )
                .frame(height: .toolbarViewHeight)
            // this should be the same with the value in `SearchBarBaseViewController`
            if toolbarVM.state.showProgress {
                ProgressView(value: toolbarVM.state.loadingProgress)
            }
            if showSearchSuggestions {
                let delegate = delegatesHolder.searchSuggestionsDelegate
                SearchSuggestionsView<S>(searchQuery, delegate, mode)
            } else {
                let jsPlugins = browserContentVM.jsPluginsBuilder
                let siteNavigation = toolbarVM.context?.siteExternalDelegate
                BrowserContentView(
                    jsPlugins,
                    siteNavigation,
                    isLoading,
                    contentType,
                    $webViewNeedsUpdate,
                    mode,
                    webVM
                )
            }
        }
        .ignoresSafeArea(.keyboard)
        .onReceive(searchBarVM.$state) { value in
            switch value {
            case is SearchBarInViewMode<SearchBarStateContextProxy>:
                showSearchSuggestions = false
            case is SearchBarInSearchMode<SearchBarStateContextProxy>:
                showSearchSuggestions = true
            default:
                break
            }
            if let query = value.query {
                searchQuery = query
            }
        }
        .onReceive(toolbarVM.$state) { value in
            if value.stopWebViewReusage {
                webViewNeedsUpdate = false
            }
        }
        .onReceive(browserContentVM.$webViewNeedsUpdate.dropFirst()) { webViewNeedsUpdate = true }
        .onReceive(browserContentVM.$contentType) { value in
            contentType = value
            showSearchSuggestions = false
        }
        .onReceive(browserContentVM.$contentType) { searchBarAction = .create($0) }
        .onReceive(browserContentVM.$loading.dropFirst()) { isLoading = $0 }
        .task {
            async let searchProviderType = FeatureManager.shared.webSearchAutoCompleteValue()
            async let isDohEnabled = FeatureManager.shared.boolValue(of: .dnsOverHTTPSAvailable)
            async let isJavaScriptEnabled = FeatureManager.shared.boolValue(of: .javaScriptEnabled)
            async let nativeAppRedirectEnabled = FeatureManager.shared.boolValue(of: .nativeAppRedirect)
            let combinedValue = await (
                searchProviderType: searchProviderType,
                isDohEnabled: isDohEnabled,
                isJavaScriptEnabled: isJavaScriptEnabled,
                nativeAppRedirectEnabled: nativeAppRedirectEnabled
            )
            self.searchProviderType = combinedValue.searchProviderType
            self.isDohEnabled = combinedValue.isDohEnabled
            self.isJavaScriptEnabled = combinedValue.isJavaScriptEnabled
            self.nativeAppRedirectEnabled = combinedValue.nativeAppRedirectEnabled
            webVM.siteNavigation = toolbarVM.context?.siteExternalDelegate
        }
    }

    private var fullySwiftUIView: some View {
        VStack {
            TabletTabsView(mode)
            TabletSearchBarViewV2(
                $showingMenu,
                $showSearchSuggestions,
                $searchQuery,
                $searchBarAction,
                searchBarVM
            )
                .frame(height: .toolbarViewHeight)
                .environmentObject(toolbarVM)
            if toolbarVM.state.showProgress {
                ProgressView(value: toolbarVM.state.loadingProgress)
            }
            if showSearchSuggestions {
                let delegate = delegatesHolder.searchSuggestionsDelegate
                SearchSuggestionsView<S>(searchQuery, delegate, mode)
            } else {
                let jsPlugins = browserContentVM.jsPluginsBuilder
                let siteNavigation = toolbarVM.context?.siteExternalDelegate
                BrowserContentView(
                    jsPlugins,
                    siteNavigation,
                    isLoading,
                    contentType,
                    $webViewNeedsUpdate,
                    mode,
                    webVM
                )
            }
        }
        .sheet(isPresented: $showingMenu) {
            BrowserMenuView(menuModel)
        }
        .ignoresSafeArea(.keyboard)
        .onReceive(searchBarVM.$state) { value in
            switch value {
            case is SearchBarInViewMode<SearchBarStateContextProxy>:
                showSearchSuggestions = false
            case is SearchBarInSearchMode<SearchBarStateContextProxy>:
                showSearchSuggestions = true
            default:
                break
            }
            if let query = value.query {
                searchQuery = query
            }
        }
        .onReceive(toolbarVM.$state) { value in
            if value.stopWebViewReusage {
                webViewNeedsUpdate = false
            }
        }
        .onReceive(browserContentVM.$webViewNeedsUpdate.dropFirst()) { webViewNeedsUpdate = true }
        .onReceive(browserContentVM.$contentType.dropFirst()) { value in
            showSearchSuggestions = false
            contentType = value
            searchBarAction = .create(value)
        }
        .onReceive(browserContentVM.$tabsCount) { tabsCount = $0 }
        .onReceive(browserContentVM.$loading.dropFirst()) { isLoading = $0 }
        .task {
            async let searchProviderType = FeatureManager.shared.webSearchAutoCompleteValue()
            async let isDohEnabled = FeatureManager.shared.boolValue(of: .dnsOverHTTPSAvailable)
            async let isJavaScriptEnabled = FeatureManager.shared.boolValue(of: .javaScriptEnabled)
            async let nativeAppRedirectEnabled = FeatureManager.shared.boolValue(of: .nativeAppRedirect)
            let combinedValue = await (
                searchProviderType: searchProviderType,
                isDohEnabled: isDohEnabled,
                isJavaScriptEnabled: isJavaScriptEnabled,
                nativeAppRedirectEnabled: nativeAppRedirectEnabled
            )
            self.searchProviderType = combinedValue.searchProviderType
            self.isDohEnabled = combinedValue.isDohEnabled
            self.isJavaScriptEnabled = combinedValue.isJavaScriptEnabled
            self.nativeAppRedirectEnabled = combinedValue.nativeAppRedirectEnabled
            webVM.siteNavigation = toolbarVM.context?.siteExternalDelegate
        }
    }
}
