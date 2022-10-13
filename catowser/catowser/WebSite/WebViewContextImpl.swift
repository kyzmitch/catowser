//
//  WebViewContextImpl.swift
//  catowser
//
//  Created by Andrei Ermoshin on 10/3/22.
//  Copyright © 2022 andreiermoshin. All rights reserved.
//

import Foundation
import CoreHttpKit
import CoreCatowser
import CoreBrowser
import JSPlugins
import FeaturesFlagsKit

public final class WebViewContextImpl: WebViewContext {
    public let pluginsProgram: any JSPluginsProgram
    
    init(_ program: any JSPluginsProgram) {
        pluginsProgram = program
    }
    
    public func nativeApp(for host: Host) -> String? {
        guard let checker = try? DomainNativeAppChecker(host: host) else {
            return nil
        }
        return checker.correspondingDomain
    }
    
    public func isJavaScriptEnabled() -> Bool {
        return FeatureManager.boolValue(of: .javaScriptEnabled)
    }
    
    public func isDohEnabled() -> Bool {
        return FeatureManager.boolValue(of: .dnsOverHTTPSAvailable)
    }
    
    public func appAsyncApiTypeValue() -> AsyncApiType {
        return FeatureManager.appAsyncApiTypeValue()
    }
    
    public func updateTabContent(_ site: Site) throws {
        let content: Tab.ContentType = .site(site)
#if DEBUG
        print("Web VM tab update: \(content.debugDescription)")
#endif
        try TabsListManager.shared.replaceSelected(tabContent: content)
    }
}
