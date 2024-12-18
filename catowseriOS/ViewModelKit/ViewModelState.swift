//
//  ViewModelState.swift
//  catowser
//
//  Created by Andrey Ermoshin on 17.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

/// View model action marker interface
public protocol ViewModelAction: CaseIterable, Sendable { }

/// View model state marker interface
public protocol ViewModelState: Sendable {
    /// Action type
    associatedtype Action: ViewModelAction
    /// Context
    associatedtype Context: StateContext

    /// Create an initial state which is needed for View Model init
    static func createInitial() -> Self
    /// Converts current state to another valid state based on input action
    @MainActor func handleAction(
        _ action: Action,
        context: Context
    ) throws -> Self
}
