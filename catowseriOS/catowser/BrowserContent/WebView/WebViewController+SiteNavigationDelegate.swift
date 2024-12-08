//
//  WebViewController+WebViewNavigatable.swift
//  catowser
//
//  Created by Andrei Ermoshin on 6/1/20.
//  Copyright © 2020 Cotton (former Catowser). All rights reserved.
//

import WebKit
import CottonBase
import CottonData
import CottonViewModels

// MARK: - Allow users of this delegate to control webview navigation

extension WebViewController: WebViewNavigatable {
    var canGoBack: Bool {
        guard let nonNilValue = webView else {
            return false
        }
        return isViewLoaded ? nonNilValue.canGoBack : false
    }

    var canGoForward: Bool {
        guard let nonNilValue = webView else {
            return false
        }
        return isViewLoaded ? nonNilValue.canGoForward : false
    }

    func goForward() {
        guard isViewLoaded else { return }
        viewModel.siteNavigation?.provisionalNavigationDidStart()
        Task {
            await viewModel.goForward()
        }
        _ = webView?.goForward()
    }

    func goBack() {
        guard isViewLoaded else { return }
        viewModel.siteNavigation?.provisionalNavigationDidStart()
        Task {
            await viewModel.goBack()
        }
        _ = webView?.goBack()
    }

    func reload() {
        guard isViewLoaded else { return }
        viewModel.siteNavigation?.provisionalNavigationDidStart()
        Task {
            await viewModel.reload()
        }
        _ = webView?.reload()
    }

    func enableJavaScript(_ enabled: Bool, for host: Host) {
        guard viewModel.host == host, let jsSubject = webView else {
            return
        }
        Task {
            await viewModel.setJavaScript(jsSubject, enabled)
        }
    }

    var host: Host {
        viewModel.host
    }

    var siteSettings: Site.Settings {
        viewModel.settings
    }

    var url: URL? {
        viewModel.currentURL
    }
}
