//
//  PluginsProxy.swift
//  catowser
//
//  Created by Andrey Ermoshin on 27.11.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import CottonPlugins

protocol PluginsProxyDelegate: AnyObject, InstagramContentDelegate, BasePluginContentDelegate { }

/// Need to have it for AppCoordinator because its init is getting called after AppAssembler,
/// and something is needed as a delegate as a replacement
final class PluginsProxy: @unchecked Sendable {
    /// Points to AppCoordinator
    weak var delegate: PluginsProxyDelegate?
}

// MARK: - InstagramContentDelegate

extension PluginsProxy: InstagramContentDelegate {
    func didReceiveVideoNodes(_ nodes: [InstagramVideoNode]) {
        delegate?.didReceiveVideoNodes(nodes)
    }
}

// MARK: - BasePluginContentDelegate

extension PluginsProxy: BasePluginContentDelegate {
    func didReceiveVideoTags(_ tags: [HTMLVideoTag]) {
        delegate?.didReceiveVideoTags(tags)
    }
}
