//
//  GenericDataServiceProtocol.swift
//  catowser
//
//  Created by Andrey Ermoshin on 24.09.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

/// A base interface for a data service which can be specialized
/// for a specific business logic domain (tabs, search auto-completion, DNS over HTTPS, etc.)
/// This one is modeled around an Actor type and thread safety is accomplished using Actor.
public protocol GenericDataServiceActorProtocol: Actor {
    /// Type of command for a specific domain
    associatedtype Command: GenericDataServiceCommand
    /// Type of a state for a specific domain
    associatedtype ServiceData: GenericServiceData
    /// Service data
    var serviceData: ServiceData { get set }

    /// A single entry point in data service API for read/write functionality
    /// related to specific domain of business logic.
    func sendCommand(
        _ command: Command,
        _ input: ServiceData?
    ) async -> ServiceData
}
