//
//  WebViewContextImpl.swift
//  catowser
//
//  Created by Andrei Ermoshin on 10/3/22.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import Foundation
import CottonBase
import CottonData
import CoreBrowser
import CottonPlugins
import FeatureFlagsKit

public final class WebViewContextImpl: WebViewContext {
    public let pluginsSource: any JSPluginsSource

    init(_ pluginsSource: any JSPluginsSource) {
        self.pluginsSource = pluginsSource
    }

    public func nativeApp(for host: Host) -> String? {
        guard let checker = try? DomainNativeAppChecker(host: host) else {
            return nil
        }
        return checker.correspondingDomain
    }

    public func isJavaScriptEnabled() async -> Bool {
        await FeatureManager.shared.boolValue(of: .javaScriptEnabled)
    }

    public func isDohEnabled() async -> Bool {
        await FeatureManager.shared.boolValue(of: .dnsOverHTTPSAvailable)
    }

    public func allowNativeAppRedirects() async -> Bool {
        await FeatureManager.shared.boolValue(of: .nativeAppRedirect)
    }

    public func appAsyncApiTypeValue() async -> AsyncApiType {
        await FeatureManager.shared.appAsyncApiTypeValue()
    }
}
