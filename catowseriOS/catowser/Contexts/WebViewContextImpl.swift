//
//  WebViewContextImpl.swift
//  catowser
//
//  Created by Andrei Ermoshin on 10/3/22.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import Foundation
import CottonBase
import CoreBrowser
import CottonPlugins
import FeatureFlagsKit
import CottonViewModels

final class WebViewContextImpl: WebViewContext {
    public let pluginsSource: any JSPluginsSource

    init(_ pluginsSource: any JSPluginsSource) {
        self.pluginsSource = pluginsSource
    }

    func nativeApp(for host: Host) -> String? {
        guard let checker = try? DomainNativeAppChecker(host: host) else {
            return nil
        }
        return checker.correspondingDomain
    }

    func isJavaScriptEnabled() async -> Bool {
        await FeatureManager.shared.boolValue(of: .javaScriptEnabled)
    }

    var isDohEnabled: Bool {
        get async {
            await FeatureManager.shared.boolValue(of: .dnsOverHTTPSAvailable)
        }
    }

    func allowNativeAppRedirects() async -> Bool {
        await FeatureManager.shared.boolValue(of: .nativeAppRedirect)
    }

    func appAsyncApiTypeValue() async -> AsyncApiType {
        await FeatureManager.shared.appAsyncApiTypeValue()
    }
}
