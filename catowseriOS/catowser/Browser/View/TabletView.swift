//
//  TabletView.swift
//  catowser
//
//  Created by Andrei Ermoshin on 1/13/23.
//  Copyright © 2023 Cotton (former Catowser). All rights reserved.
//

import SwiftUI
import CoreBrowser
import FeaturesFlagsKit
import CottonData

struct TabletView<W: WebViewModel, S: SearchSuggestionsViewModel, SB: SearchBarViewModelProtocol>: View {
    // MARK: - view models of subviews

    /// Search bar view model
    @ObservedObject private var searchBarVM: SB
    /// A reference to created vm in main view
    @EnvironmentObject private var browserContentVM: BrowserContentViewModel
    /// Toolbar model needed by both UI modes
    @StateObject private var toolbarVM: BrowserToolbarViewModel = .init()
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
        #warning("TODO: searchSuggestionsVM is not used")
        self.searchSuggestionsVM = searchVM
        self.searchBarVM = searchBarVM
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
            let searchBarDelegate: UISearchBarDelegate = searchBarVM
            TabletTabsView(mode)
            TabletSearchBarLegacyView(searchBarDelegate, searchBarAction, webViewInterface)
                .frame(height: .toolbarViewHeight)
            // this should be the same with the value in `SearchBarBaseViewController`
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
        }
        .ignoresSafeArea(.keyboard)
        .onReceive(toolbarVM.$showProgress) { showProgress = $0 }
        .onReceive(toolbarVM.$websiteLoadProgress) { websiteLoadProgress = $0 }
        .onReceive(toolbarVM.$webViewInterface) { webViewInterface = $0 }
        .onReceive(searchBarVM.$showSearchSuggestions) { showSearchSuggestions = $0 }
        .onReceive(searchBarVM.$searchQuery) { searchQuery = $0 }
        .onReceive(searchBarVM.$action.dropFirst()) { searchBarAction = $0 }
        .onReceive(toolbarVM.$stopWebViewReuseAction.dropFirst()) { webViewNeedsUpdate = false }
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
            webVM.siteNavigation = toolbarVM
        }
    }

    private var fullySwiftUIView: some View {
        VStack {
            TabletTabsView(mode)
            TabletSearchBarViewV2($showingMenu, $showSearchSuggestions, $searchQuery, $searchBarAction)
                .frame(height: .toolbarViewHeight)
                .environmentObject(toolbarVM)
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
        }
        .sheet(isPresented: $showingMenu) {
            BrowserMenuView(menuModel)
        }
        .ignoresSafeArea(.keyboard)
        .onReceive(toolbarVM.$showProgress) { showProgress = $0 }
        .onReceive(toolbarVM.$websiteLoadProgress) { websiteLoadProgress = $0 }
        .onReceive(toolbarVM.$webViewInterface) { webViewInterface = $0 }
        .onReceive(searchBarVM.$showSearchSuggestions) { showSearchSuggestions = $0 }
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
}
