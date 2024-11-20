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
    
    /// A single entry point in data service API for read/write functionality
    /// related to specific domain of business logic.
    func sendCommand(
        _ command: Command,
        _ input: ServiceData?
    ) -> ServiceData
}
