//
//  WebViewControllerProxy.swift
//  catowser
//
//  Created by Andrei Ermoshin on 1/14/23.
//  Copyright © 2023 Cotton (former Catowser). All rights reserved.
//

import Foundation
import CottonBase
import CottonViewModels

/// A proxy type around WebViewController for SwiftUI mode only when
/// web view can only be re-used and same web view controller
/// will be used which for some reason doesn't trigger SwiftUI's onReceive.
/// Hoping that this proxy will solve this issue.
final class WebViewControllerProxy: WebViewNavigatable {
    /// Has to be a weak reference, because this Proxy will be stored in the argument (web view controller)
    private weak var vc: (any WebViewNavigatable)?

    init(_ vc: any WebViewNavigatable) {
        self.vc = vc
    }
    var canGoBack: Bool {
        vc?.canGoBack ?? false
    }

    var canGoForward: Bool {
        vc?.canGoForward ?? false
    }

    func goForward() {
        vc?.goForward()
    }

    func goBack() {
        vc?.goBack()
    }

    func reload() {
        vc?.reload()
    }

    func enableJavaScript(_ enabled: Bool, for host: Host) {
        vc?.enableJavaScript(enabled, for: host)
    }

    var host: Host {
        let badResponse = try? Host(input: "")
        // swiftlint:disable:next force_unwrapping
        return vc?.host ?? badResponse!
    }

    var siteSettings: Site.Settings {
        vc?.siteSettings ?? Site.Settings(isPrivate: false,
                                          blockPopups: false,
                                          isJSEnabled: false,
                                          canLoadPlugins: false)
    }

    var url: URL? {
        vc?.url
    }
}
