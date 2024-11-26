//
//  GenericConcurrentDataService.swift
//  catowser
//
//  Created by Andrei Ermoshin on 11/22/24.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

/// Base generic data service which will use dispatch queue as a synhronization.
/// There is another approach in this framework using an actor base protocol.
open class GenericConcurrentDataService<
    C: GenericDataServiceCommand,
    S: GenericServiceData
>: GenericDataServiceProtocol {
    
    public typealias Command = C
    public typealias ServiceData = S
    
    public let executionQueue: DispatchQueueInterface
    public let responseQueue: DispatchQueueInterface
    public var serviceData: ServiceData
    public let lock: NSRecursiveLock
    private var commandToPromise: [Command: (Result<ServiceData, Error>) -> Void]
    
    public init(
        executionQueue: DispatchQueueInterface = DispatchQueue.global(),
        responseQueue: DispatchQueueInterface = DispatchQueue.main
    ) {
        serviceData = ServiceData()
        lock = NSRecursiveLock()
        self.executionQueue = executionQueue
        self.responseQueue = responseQueue
        commandToPromise = [:]
    }
    
    public func sendCommand(
        _ command: Command,
        _ input: ServiceData?,
        _ onComplete: @escaping (Result<ServiceData, Error>) -> Void
    ) {
        executionQueue.performAsync { [weak self] in
            guard let self else {
                onComplete(.failure(DataServiceKitError.zombyInstance))
                return
            }
            lock.lock()
            if commandToPromise[command] != nil {
                print("There was existing not finished command")
            }
            commandToPromise[command] = onComplete
            lock.unlock()
            handleCommand(command, input, onComplete)
        }
    }
    
    /// Handle specific command, should be implemented by every specific data service
    ///
    /// - Parameter command: a command to handle by the data service
    /// - Parameter input: an input for a command if it wasn't passed in the same parameter as command
    /// - Parameter onComplete: a closure which will be called after handling the command with some output or an error
    open func handleCommand(
        _ command: Command,
        _ input: ServiceData?,
        _ onComplete: @escaping (Result<ServiceData, Error>) -> Void
    ) { }
    
    /// Finilizes handling of a command by calling completion closure with the result.
    ///
    /// - Parameter command: a command to handle by the data service
    /// - Parameter output: a result with service data or an error
    func finishCommand(
        _ command: Command,
        _ output: Result<ServiceData, Error>
    ) {
        lock.lock()
        guard let onComplete = commandToPromise.removeValue(forKey: command) else {
            lock.unlock()
            return
        }
        lock.unlock()
        responseQueue.performAsync {
            onComplete(output)
        }
    }
}
