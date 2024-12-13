//
//  GenericSerialDataService.swift
//  catowser
//
//  Created by Andrey Ermoshin on 20.11.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

/// Base interface for a generic data service using class with custom sinhronization
/// (serial or concurrent depending on implementation)
public protocol GenericDataServiceProtocol: AnyObject {
    /// Type of command for a specific domain of business logic
    associatedtype Command: GenericDataServiceCommand
    /// Type of a state for a specific domain of business logic
    associatedtype ServiceData: GenericServiceData
    /// Data service error type
    associatedtype ServiceError: DataServiceKitError
    /// Type of closure for response on a command
    typealias Promise = @Sendable (Result<ServiceData, ServiceError>) -> Void

    /// mutable service data (state)
    var serviceData: ServiceData { get set }
    /// Dispatch queue for a business logic
    var executionQueue: DispatchQueueInterface { get }
    /// Dispatch queue to execute a completion closure
    var responseQueue: DispatchQueueInterface { get }
    
    /// A single entry point in data service API for read/write functionality
    /// related to specific domain of business logic.
    ///
    /// - Parameter command: a command to handle by the data service
    /// - Parameter input: an input for a command if it wasn't passed in the same parameter as command
    /// - Parameter onComplete: a closure which will be called after handling the command with some output or an error
    func sendCommand(
        _ command: Command,
        _ input: ServiceData?,
        _ onComplete: @escaping @Sendable Promise
    )
}
