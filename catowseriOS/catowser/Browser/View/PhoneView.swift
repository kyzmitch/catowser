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

struct PhoneView<W: WebViewModel, S: SearchSuggestionsViewModel, SB: SearchBarViewModel>: View {
    // MARK: - view models of subviews

    /// Search bar view model
    @ObservedObject private var searchBarVM: SB
    /// A reference to created view model
    @EnvironmentObject private var browserContentVM: BrowserContentViewModel
    /// Toolbar view model needed by both UI modes
    @StateObject private var toolbarVM: BrowserToolbarViewModel = .init()
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
    @State private var websiteLoadProgress: Double = 0.0

    // MARK: - browser content state

    @State private var isLoading: Bool = true
    @State private var contentType: CoreBrowser.Tab.ContentType
    /// A workaround to avoid unnecessary web view updates
    @State private var webViewNeedsUpdate: Bool = false

    // MARK: - web view related

    @State private var webViewInterface: WebViewNavigatable?

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
        if let interface = webViewInterface {
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
        _ searchBarVM: SB
    ) {
        self.webVM = webVM
        // search suggestions vm is used as a template argument later
        self.searchSuggestionsVM = searchVM
        self.searchBarVM = searchBarVM
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
            let searchBarDelegate: UISearchBarDelegate = searchBarVM
            PhoneSearchBarLegacyView(searchBarDelegate, searchBarAction)
                .frame(minWidth: 0, maxWidth: .infinity, maxHeight: CGFloat.searchViewHeight)
            if showProgress {
                ProgressView(value: websiteLoadProgress)
            }
            if showSearchSuggestions {
                let delegate: SearchSuggestionsListDelegate = searchBarVM
                SearchSuggestionsView<S>(searchQuery, delegate, mode)
            } else {
                let jsPlugins = browserContentVM.jsPluginsBuilder
                let siteNavigation: SiteExternalNavigationDelegate = toolbarVM
                BrowserContentView(jsPlugins,
                                   siteNavigation,
                                   isLoading,
                                   contentType,
                                   $webViewNeedsUpdate,
                                   mode,
                                   webVM)
            }
            ToolbarView(toolbarVM, $webViewInterface)
        }
        .ignoresSafeArea(.keyboard, edges: [.bottom])
        .ignoresSafeArea(.container, edges: [.leading, .trailing])
        .onReceive(toolbarVM.$showProgress) { showProgress = $0 }
        .onReceive(toolbarVM.$websiteLoadProgress) { websiteLoadProgress = $0 }
        .onReceive(searchBarVM.showSearchSuggestions) { showSearchSuggestions = $0 }
        .onReceive(searchBarVM.searchQuery) { searchQuery = $0 }
        .onReceive(searchBarVM.action.dropFirst()) { searchBarAction = $0 }
        .onReceive(toolbarVM.$stopWebViewReuseAction.dropFirst()) { webViewNeedsUpdate = false }
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
            webVM.siteNavigation = toolbarVM
        }
    }

    private var fullySwiftUIView: some View {
        NavigationView {
            VStack {
                SearchBarViewV2($searchQuery, $searchBarAction)
                    .frame(minWidth: 0, maxWidth: .infinity)
                if showProgress {
                    ProgressView(value: websiteLoadProgress)
                }
                if showSearchSuggestions {
                    let delegate: SearchSuggestionsListDelegate = searchBarVM
                    SearchSuggestionsView<S>(searchQuery, delegate, mode)
                } else {
                    let jsPlugins = browserContentVM.jsPluginsBuilder
                    let siteNavigation: SiteExternalNavigationDelegate = toolbarVM
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
#if swift(<6.0)
            .toolbar {
                ToolbarViewV2(
                    toolbarVM,
                    tabsCount,
                    $showingMenu,
                    $showingTabs,
                    $showSearchSuggestions
                )
            }
#else
            .toolbar(content: toolBarContent)
#endif
        }
        .sheet(isPresented: $showingMenu) {
            BrowserMenuView(menuModel)
        }
        .sheet(isPresented: $showingTabs) {
            TabsPreviewsLegacyView()
        }
        .ignoresSafeArea(.keyboard, edges: [.bottom])
        .ignoresSafeArea(.container, edges: [.leading, .trailing])
        .onReceive(toolbarVM.$showProgress) { showProgress = $0 }
        .onReceive(toolbarVM.$websiteLoadProgress) { websiteLoadProgress = $0 }
        .onReceive(searchBarVM.showSearchSuggestions) { showSearchSuggestions = $0 }
        .onChange(of: searchQuery) { value in
            let inSearchMode = searchBarAction == .startSearch
            let validQuery = !value.isEmpty && !value.looksLikeAURL()
            showSearchSuggestions = inSearchMode && validQuery
        }
        .onReceive(toolbarVM.$stopWebViewReuseAction.dropFirst()) { webViewNeedsUpdate = false }
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
                searchBarAction = .cancelTapped
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
            webVM.siteNavigation = toolbarVM
        }
    }

#if swift(>=6.0)
    /// A workaround for swift 6.0 Xcode 16 beta 4 to compile the project
    /// and use instead of `ToolbarViewV2` type
    @ToolbarContentBuilder
    func toolBarContent() -> some ToolbarContent {
        ToolbarItem(placement: .bottomBar) {
            DisableableButton(
                "nav-back",
                toolbarVM.goBackDisabled,
                toolbarVM.goBack
            )
        }
        ToolbarItem(placement: .bottomBar) {
            Spacer()
        }
        ToolbarItem(placement: .bottomBar) {
            DisableableButton(
                "nav-forward",
                toolbarVM.goForwardDisabled,
                toolbarVM.goForward
            )
        }
        ToolbarItem(placement: .bottomBar) {
            Spacer()
        }
        ToolbarItem(placement: .bottomBar) {
            DisableableButton(
                "nav-refresh",
                toolbarVM.reloadDisabled,
                toolbarVM.reload
            )
        }
        ToolbarItem(placement: .bottomBar) {
            Spacer()
        }
        ToolbarItem(placement: .bottomBar) {
            Button {
                showSearchSuggestions = false
                withAnimation(.easeInOut(duration: 1)) {
                    showingTabs.toggle()
                }
            } label: {
                Text(verbatim: "\(tabsCount)")
            }
            .foregroundColor(.black)
        }
        ToolbarItem(placement: .bottomBar) {
            Spacer()
        }
        ToolbarItem(placement: .bottomBar) {
            MenuButton($showSearchSuggestions, $showingMenu)
        }
    }
#endif
}
