//
//  PhoneView.swift
//  catowser
//
//  Created by Andrei Ermoshin on 1/13/23.
//  Copyright © 2023 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import SwiftUI
import CoreBrowser
import FeatureFlagsKit
import CottonViewModels
import ViewModelKit

struct PhoneView<
    W: WebViewModel,
    S: SearchSuggestionsViewModel,
    SB: SearchBarViewModel
>: View {
    // MARK: - view models of subviews

    /// Search bar view model, can't be environment object (always nil for some reason)
    @ObservedObject private var searchBarVM: SB
    /// Separate field for the delegate (environment object for Search bar view model can't compile with it)
    private let delegatesHolder: SearchBarDelegateHolder
    /// A reference to created view model
    @EnvironmentObject private var browserContentVM: BrowserContentViewModel
    /// Toolbar model needed by both UI modes
    @EnvironmentObject private var toolbarVM: BrowserToolbarViewModel
    /// Top sites view model is async dependency, so, can only be injected from outside
    @EnvironmentObject private var topSitesVM: TopSitesViewModel
    /// Search suggestions view model has async init
    @ObservedObject private var searchSuggestionsVM: S
    /// Web view model without a specific site
    @ObservedObject private var webVM: W

    // MARK: - search bar state

    /// Search bar action is only needed for SwiftUI UIKit wrapper
    @State private var searchBarAction: SearchBarAction
    /// Search suggestion visibility state
    @State private var showSearchSuggestions: Bool = false
    /// Search query string state which is set by SearchBar and used by SearchSuggestions
    @State private var searchQuery: String = ""
    /// Needs to be fetched from global actor in task to know current value
    @State private var searchProviderType: CoreBrowser.WebAutoCompletionSource

    // MARK: - web content loading state

    @State private var showProgress: Bool = false

    // MARK: - browser content state

    @State private var isLoading: Bool = true
    @State private var contentType: CoreBrowser.Tab.ContentType
    /// A workaround to avoid unnecessary web view updates
    @State private var webViewNeedsUpdate: Bool = false

    // MARK: - constants

    private let mode: SwiftUIMode

    // MARK: - toolbar

    @State private var toolbarVisibility: Visibility
    @State private var showingMenu: Bool = false
    @State private var showingTabs: Bool = false
    @State private var tabsCount: Int = 0

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
        searchBarAction = .clearView
        self.mode = mode
        self.contentType = defaultContentType
        switch mode {
        case .compatible:
            toolbarVisibility = .hidden
        case .full:
            toolbarVisibility = .visible
        }

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
            PhoneSearchBarLegacyView(
                searchBarDelegate,
                searchBarAction,
                searchBarVM
            )
                .frame(minWidth: 0, maxWidth: .infinity, maxHeight: CGFloat.searchViewHeight)
            if toolbarVM.state.showProgress {
                ProgressView(value: toolbarVM.state.loadingProgress)
            }
            if showSearchSuggestions {
                let delegate = delegatesHolder.searchSuggestionsDelegate
                SearchSuggestionsView<S>(searchQuery, delegate, mode)
            } else {
                let jsPlugins = browserContentVM.jsPluginsBuilder
                // swiftlint:disable:next force_cast
                let siteNavigation = toolbarVM as! SiteExternalNavigationDelegate
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
            ToolbarView()
        }
        .ignoresSafeArea(.keyboard, edges: [.bottom])
        .ignoresSafeArea(.container, edges: [.leading, .trailing])
        .onReceive(toolbarVM.$state) { value in
            if value.stopWebViewReusage {
                webViewNeedsUpdate = false
            }
        }
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
        .onReceive(browserContentVM.$webViewNeedsUpdate.dropFirst()) { webViewNeedsUpdate = true }
        .onReceive(browserContentVM.$contentType) { value in
            showSearchSuggestions = false
            contentType = value
        }
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
            webVM.siteNavigation = toolbarVM as? SiteExternalNavigationDelegate
        }
    }

    private var fullySwiftUIView: some View {
        NavigationView {
            VStack {
                SearchBarViewV2(
                    $searchQuery,
                    $searchBarAction,
                    searchBarVM
                ).frame(minWidth: 0, maxWidth: .infinity)
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
            .toolbar {
                ToolbarViewV2(
                    tabsCount,
                    $showingMenu,
                    $showingTabs,
                    $showSearchSuggestions
                )
            }
        }
        .sheet(isPresented: $showingMenu) {
            BrowserMenuView(menuModel)
        }
        .sheet(isPresented: $showingTabs) {
            TabsPreviewsLegacyView()
        }
        .ignoresSafeArea(.keyboard, edges: [.bottom])
        .onReceive(searchBarVM.$state) { value in
            switch value {
            case is SearchBarInViewMode<SearchBarStateContextProxy>:
                showSearchSuggestions = false
            case is SearchBarInSearchMode<SearchBarStateContextProxy>:
                showSearchSuggestions = true
            default:
                break
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
        .onChange(of: showingTabs) { newValue in
            // Reset the search bar from editing mode
            // when new modal screen is about to get shown
            if newValue {
                searchBarAction = .cancelSearch
            }
        }
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
