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
    ///
    /// It is without any type constraints for now
    /// so that, potentially can be for a different state type.
    associatedtype Context: StateContext

    /// Create an initial state which is needed for View Model init
    static func createInitial() -> Self
    /// Converts current state to another valid state based on input action
    /// - Parameter action: An action which tells how to convert the state or ignore that action if it doesn't apply
    /// - Parameter context: An optional state context if it is needed for state conversion
    /// - Returns same type or modified/same state if action was valid for current state
    @MainActor func handleAction(
        _ action: Action,
        with context: Context?
    ) throws -> Self
}
