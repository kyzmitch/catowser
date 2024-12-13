//
//  BasePlugin.swift
//  JSPlugins
//
//  Created by Andrei Ermoshin on 5/30/22.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import Foundation
import WebKit

/// Base plugin interface, needs to be sendable to be able to pass it to async func
@MainActor public protocol BasePluginContentDelegate: AnyObject, Sendable {
    func didReceiveVideoTags(_ tags: [HTMLVideoTag])
}

public struct BasePlugin: JavaScriptPlugin {
    public let jsFileName: String = "__cotton__"

    public let messageHandlerName: String = .basePluginHName

    /// Should be present on any web site no matter which host is it
    public let hostKeyword: String? = nil

    public func scriptString(_ enable: Bool) -> String? {
        // always should work, no need to enable it
        return nil
    }

    public let isMainFrameOnly: Bool = true
}

extension String {
    /// Always should be enabled
    static let basePluginHName = "cottonHandler"
}

extension BasePlugin: Equatable {
    public static func == (lhs: BasePlugin, rhs: BasePlugin) -> Bool {
        return lhs.jsFileName == rhs.jsFileName
            && lhs.messageHandlerName == rhs.messageHandlerName
            && lhs.hostKeyword == rhs.hostKeyword
            && lhs.isMainFrameOnly == rhs.isMainFrameOnly
    }
}
