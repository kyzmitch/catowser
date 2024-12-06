//
//  SiteSettings+Extensions.swift
//  catowser
//
//  Created by Andrei Ermoshin on 6/2/20.
//  Copyright © 2020 Cotton (former Catowser). All rights reserved.
//

import WebKit
import CottonBase

extension Site.Settings {
    /// This will be ignored for old WebViews because it can't be changed for existing WebView without recration.
    /// It has to be main actor because `WKWebViewConfiguration` uses it.
    @MainActor public var webViewConfig: WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        if #available(iOS 14, *) {
            let preferences = WKWebpagePreferences()
            preferences.allowsContentJavaScript = isJSEnabled
            configuration.defaultWebpagePreferences = preferences
        } else {
            configuration.preferences.javaScriptEnabled = isJSEnabled
        }
        configuration.processPool = WKProcessPool()
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = !blockPopups
        #if os(iOS)
        // We do this to go against the configuration of the <meta name="viewport">
        // tag to behave the same way as Safari :-(
        configuration.ignoresViewportScaleLimits = true
        #endif
        if isPrivate {
            configuration.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        }

        return configuration
    }
}
