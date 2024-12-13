//
//  InstagramContentPlugin.swift
//  JSPlugins
//
//  Created by Andrei Ermoshin on 5/30/22.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import Foundation
import WebKit

/// Instagram plugin interface, needs to be sendable to be able to pass it to async func
@MainActor public protocol InstagramContentDelegate: AnyObject, Sendable {
    func didReceiveVideoNodes(_ nodes: [InstagramVideoNode])
}

public struct InstagramContentPlugin: JavaScriptPlugin {
    public let jsFileName: String = "ig"

    public let messageHandlerName: String = "igHandler"

    public let hostKeyword: String? = "instagram"

    public func scriptString(_ enable: Bool) -> String? {
        return "__cotton__.ig.setEnabled(\(enable ? "true" : "false"));"
    }

    public let isMainFrameOnly: Bool = true
}

extension InstagramContentPlugin: Equatable {
    public static func == (lhs: InstagramContentPlugin, rhs: InstagramContentPlugin) -> Bool {
        return lhs.jsFileName == rhs.jsFileName
            && lhs.messageHandlerName == rhs.messageHandlerName
            && lhs.hostKeyword == rhs.hostKeyword
            && lhs.isMainFrameOnly == rhs.isMainFrameOnly
    }
}
