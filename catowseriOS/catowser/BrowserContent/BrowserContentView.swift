//
//  BrowserContentView.swift
//  catowser
//
//  Created by Andrey Ermoshin on 14.12.2022.
//  Copyright © 2022 Cotton (former Catowser). All rights reserved.
//

import SwiftUI
import CoreBrowser
import Combine
import FeatureFlagsKit
import CottonPlugins
import CottonData
import CottonViewModels

/// Dynamic content view (could be a webview, a top sites list or something else)
struct BrowserContentView<W: WebViewModel>: View {
    /// Plugins builder needed by web view model
    /// but the reference needs to be holded/created by another vm on upper level
    private let jsPluginsBuilder: any JSPluginsSource
    /// The main state of the browser content view
    private let contentType: CoreBrowser.Tab.ContentType
    /// Determines if the state is still loading to not show wrong content type (like default one).
    /// Depends on main view state, because this model's init is getting called unexpectedly.
    private let isLoading: Bool
    /// Tells if web view needs to be updated to avoid unnecessary updates.
    @Binding private var webViewNeedsUpdate: Bool
    /// Selected swiftUI mode which is set at app start
    private let mode: SwiftUIMode
    /// Top sites view model, possibly somehow needs to be recreated JS setting changes
    @EnvironmentObject private var topSitesVM: TopSitesViewModel
    /// A delegate for the web view model
    private var siteNavigation: SiteExternalNavigationDelegate?
    /// Web view model
    @ObservedObject private var webVM: W

    init(_ jsPluginsBuilder: any JSPluginsSource,
         _ siteNavigation: SiteExternalNavigationDelegate?,
         _ isLoading: Bool,
         _ contentType: CoreBrowser.Tab.ContentType,
         _ webViewNeedsUpdate: Binding<Bool>,
         _ mode: SwiftUIMode,
         _ webVM: W) {
        self.isLoading = isLoading
        self.contentType = contentType
        _webViewNeedsUpdate = webViewNeedsUpdate
        self.jsPluginsBuilder = jsPluginsBuilder
        self.siteNavigation = siteNavigation
        self.mode = mode
        self.webVM = webVM
    }

    var body: some View {
        dynamicContentView
    }

    @ViewBuilder
    private var dynamicContentView: some View {
        if isLoading {
            Spacer()
        } else {
            switch contentType {
            case .blank:
                Spacer()
            case .topSites:
                TopSitesView(mode)
            case .site(let site):
                WebView(webVM, site, webViewNeedsUpdate, mode)
            default:
                Spacer()
            }
        }
    }
}
