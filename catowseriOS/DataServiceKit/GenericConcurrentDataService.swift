//
//  GenericConcurrentDataService.swift
//  catowser
//
//  Created by Andrei Ermoshin on 11/22/24.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

/// Base generic data service which will use dispatch queue as a synhronization instead of a modern actor
public class GenericConcurrentDataService<
    C: GenericDataServiceCommand,
    S: GenericServiceData
>: GenericDataServiceProtocol {
    
    public typealias Command = C
    public typealias ServiceData = S
    
    public var serviceData: ServiceData
    private let dispatchQueue: DispatchQueue
    
    public init(
        dispatchQueue: DispatchQueue = .global()
    ) {
        serviceData = ServiceData()
        self.dispatchQueue = dispatchQueue
    }
    
    public func sendCommand(
        _ command: Command,
        _ input: ServiceData?
    ) -> ServiceData {
        
        return serviceData
    }
}
