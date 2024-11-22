//
//  GenericDataServiceProtocol.swift
//  catowser
//
//  Created by Andrey Ermoshin on 24.09.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

/// An interface to implement Command design pattern for a data service
/// this type should allow to provide a common interface for any data service
/// by using a single function in the data service API which has a command
/// as an input parameter
public protocol GenericDataServiceCommand: CaseIterable { }

/// An interface or a marker protocol for a data service state
public protocol GenericServiceData {
    /// Any data should have some initial state, so, must have an emty init at least
    init()
}

/// A base interface for a data service which can be specialized
/// for a specific business logic domain (tabs, search auto-completion, DNS over HTTPS, etc.)
/// This one is modeled around an Actor type and thread safety is accomplished using Actor.
public protocol GenericDataServiceActorProtocol: Actor {
    /// Type of command for a specific domain
    associatedtype Command: GenericDataServiceCommand
    /// Type of a state for a specific domain
    associatedtype ServiceData: GenericServiceData

    /// A single entry point in data service API for read/write functionality
    /// related to specific domain of business logic.
    func sendCommand(
        _ command: Command,
        _ input: ServiceData?
    ) async -> ServiceData
}
