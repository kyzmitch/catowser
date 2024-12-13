//
//  GenericServiceData.swift
//  catowser
//
//  Created by Andrey Ermoshin on 25.11.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

/// An interface or a marker protocol for a data service state.
/// Should contain only fields of type `CommandExecutionData`
public protocol GenericServiceData: Sendable {
    /// Any data should have some initial state, so, must have an emty init at least
    init()
}
