//
//  BrowserToolbarViewModel.swift
//  catowser
//
//  Created by Andrey Ermoshin on 03.01.2023.
//  Copyright © 2023 Cotton (former Catowser). All rights reserved.
//

import SwiftUI
import CoreBrowser
import CottonData

@MainActor
final class BrowserToolbarViewModel: ObservableObject {
    /// Notifies if current web view changes
    @Published var webViewInterface: WebViewNavigatable?
    /// Max value should be 1.0 because total is equals to that by default
    @Published var websiteLoadProgress: Double
    /// Tells if there is a web view content loading is in progress
    @Published var showProgress: Bool
    /// Tells that web view has handled re-use action and it is not needed anymore.
    /// Void type can be used, because only notification is needed.
    @Published var stopWebViewReuseAction: Void

    // MARK: - only for SwiftUI toolbar

    @Published var goBackDisabled: Bool
    @Published var goForwardDisabled: Bool
    @Published var reloadDisabled: Bool
    @Published var downloadsDisabled: Bool

    private var vcFactory: ViewControllerFactory {
        UIServiceRegistry.shared().vcFactory
    }

    private var siteNavigationDelegate: SiteNavigationChangable? {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return vcFactory.createdToolbaViewController as? SiteNavigationChangable
        } else {
            return vcFactory.createdDeviceSpecificSearchBarVC as? SiteNavigationChangable
        }
    }

    init() {
        webViewInterface = nil
        showProgress = false
        websiteLoadProgress = 0.0
        stopWebViewReuseAction = ()
        goBackDisabled = true
        goForwardDisabled = true
        reloadDisabled = true
        downloadsDisabled = true
    }

    func goForward() {
        webViewInterface?.goForward()
    }

    func goBack() {
        webViewInterface?.goBack()
    }

    func reload() {
        webViewInterface?.reload()
    }
}

extension BrowserToolbarViewModel: SiteExternalNavigationDelegate {
    func didBackNavigationUpdate(to canGoBack: Bool) {
        goBackDisabled = !canGoBack
        siteNavigationDelegate?.changeBackButton(to: canGoBack)
    }

    func didForwardNavigationUpdate(to canGoForward: Bool) {
        goForwardDisabled = !canGoForward
        siteNavigationDelegate?.changeForwardButton(to: canGoForward)
    }

    func provisionalNavigationDidStart() {}

    func didSiteOpen(appName: String) {}

    func loadingProgressdDidChange(_ progress: Float) {
        websiteLoadProgress = Double(progress)
    }

    func showLoadingProgress(_ show: Bool) {
        showProgress = show
    }

    func webViewDidHandleReuseAction() {
        // web view was re-created, so, all next SwiftUI view updates can be ignored
        stopWebViewReuseAction = ()
    }

    func webViewDidReplace(_ interface: WebViewNavigatable?) {
        // This will be called every time web view changes
        // in re-usable web view controller
        // so, it will be the same reference actually
        // that is why no need to check for dublication.
        webViewInterface = interface
        reloadDisabled = interface == nil
        goBackDisabled = !(interface?.canGoBack ?? false)
        goForwardDisabled = !(interface?.canGoForward ?? false)
    }
}
