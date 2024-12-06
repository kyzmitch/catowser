//
//  SpecificBasicFeatures.swift
//  catowser
//
//  Created by Andrei Ermoshin on 5/29/20.
//  Copyright © 2020 Cotton (former Catowser). All rights reserved.
//

import CoreBrowser
import FeatureFlagsKit

extension ApplicationFeature {
    static var dnsOverHTTPSAvailable: ApplicationFeature<DoHAvailable> {
        return ApplicationFeature<DoHAvailable>()
    }
    static var javaScriptEnabled: ApplicationFeature<JavaScriptEnabled> {
        return ApplicationFeature<JavaScriptEnabled>()
    }
    static var nativeAppRedirect: ApplicationFeature<NativeAppRedirect> {
        return ApplicationFeature<NativeAppRedirect>()
    }
}

/// DNS over HTTPS
enum DoHAvailable: BasicFeature {
    typealias Value = Bool
    static let key = "ios.doh"
    static let defaultValue = false
    static let source: FeatureSource.Type = LocalFeatureSource.self
}

/// State of JavaScript in webview.
enum JavaScriptEnabled: BasicFeature {
    typealias Value = Bool
    static let key: String = "ios.js.enabled"
    static let defaultValue: Bool = true
    static let source: FeatureSource.Type = LocalFeatureSource.self
}

/// Native app redirect
enum NativeAppRedirect: BasicFeature {
    typealias Value = Bool
    static let key = "ios.native-app-redirect"
    /// By default it is disabled, but default value for OS is enabled.
    /// This is because in Cotton app it is desired to keep user in the app
    /// even for native app links to allow use html content.
    /// But would be good to quickly revert this feature.
    static let defaultValue = false
    static let source: FeatureSource.Type = LocalFeatureSource.self
}
