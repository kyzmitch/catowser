//
//  GenericDataServiceProtocol.swift
//  catowser
//
//  Created by Andrey Ermoshin on 24.09.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

public protocol GenericDataServiceCommand: CaseIterable { }

public protocol GenericServiceData { }

public protocol GenericDataServiceProtocol: Actor {
    associatedtype Command: GenericDataServiceCommand
    associatedtype ServiceData: GenericServiceData

    func sendCommand(
        _ command: Command,
        _ input: ServiceData?
    ) async -> ServiceData
}
