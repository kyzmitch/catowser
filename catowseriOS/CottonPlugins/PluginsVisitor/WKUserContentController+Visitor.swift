//
//  WKUserContentController+Visitor.swift
//  JSPlugins
//
//  Created by Andrei Ermoshin on 6/4/22.
//  Copyright © 2022 Cotton (former Catowser). All rights reserved.
//

import WebKit
import CottonBase

/// A Concrete Visitor which is in this case only one possible type from iOS SDK WebKit
extension WKUserContentController: JavaScriptPluginVisitor {
    public func canVisit(
        _ plugin: any JavaScriptPlugin,
        _ host: CottonBase.Host,
        _ canInject: Bool,
        _ handler: WKScriptMessageHandler
    ) -> Bool {
        guard canInject else {
            return false
        }
        guard let pluginHostName = plugin.hostKeyword else {
            // should be a base plugin which doesn't need to be enabled (ON by default)
            return true
        }
        guard host.isSimilar(name: pluginHostName) else {
            return false
        }
        return true
    }

    public func visit(
        _ plugin: any JavaScriptPlugin,
        _ handler: WKScriptMessageHandler
    ) throws {
        if let base = plugin as? BasePlugin {
            try visit(basePlugin: base, handler: handler)
        } else if let instagram = plugin as? InstagramContentPlugin {
            try visit(instagramPlugin: instagram, handler: handler)
        }
    }

    private func visit(
        basePlugin: BasePlugin,
        handler: WKScriptMessageHandler
    ) throws {
        let wkScript = try JSPluginFactory.shared.script(
            for: basePlugin,
            with: .atDocumentEnd,
            isMainFrameOnly: true
        )
        addHandler(wkScript, basePlugin.messageHandlerName, handler)
    }

    private func visit(
        instagramPlugin: InstagramContentPlugin,
        handler: WKScriptMessageHandler
    ) throws {
        let wkScript = try JSPluginFactory.shared.script(
            for: instagramPlugin,
            with: .atDocumentStart,
            isMainFrameOnly: instagramPlugin.isMainFrameOnly
        )
        addHandler(wkScript, instagramPlugin.messageHandlerName, handler)
    }

    private func addHandler(_ script: WKUserScript, _ handlerName: String, _ handler: WKScriptMessageHandler) {
        addUserScript(script)
        removeScriptMessageHandler(forName: handlerName)
        add(handler, name: handlerName)
    }
}
