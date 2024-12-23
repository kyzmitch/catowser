//
//  WebViewNavigatable.swift
//  catowser
//
//  Created by Andrei Ermoshin on 12/6/22.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import CottonBase

/// This protocol is used by SiteExternalNavigationDelegate which is required by
/// web view model which is in separate CottonViewModels module.
@MainActor public protocol WebViewNavigatable: AnyObject, Sendable {
    var canGoBack: Bool { get }
    var canGoForward: Bool { get }
    func goForward()
    func goBack()
    func reload()
    func enableJavaScript(_ enabled: Bool, for host: CottonBase.Host)

    var host: CottonBase.Host { get }
    var siteSettings: Site.Settings { get }
    var url: URL? { get }
}
