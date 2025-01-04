//
//  ViewModelState.swift
//  catowser
//
//  Created by Andrey Ermoshin on 17.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

/// View model state marker interface
///
/// Can be value type (struct or enum) to be thread-safe out of the box.
/// But it is not required, you can use classes and inheritance to
/// implement canonical state design pattern as well.
public protocol ViewModelState: Sendable {
    /// Action type
    associatedtype Action: ViewModelAction
    /// Context of the state to be able to get any additional data
    /// required for action handling or state conversion.
    associatedtype Context: StateContext

    /// Create an initial state which is needed for View Model init
    ///
    /// e.g. it could be loading state at the beginning
    static func createInitial() -> Self

    /// Converts current state to another valid state based on input action.
    ///
    /// - Parameter action: An action which tells how to convert the state
    /// - Parameter context: An optional state context if it is needed for state conversion/handling
    /// - Returns same or modified state value, depending if action was valid or not for the current state
    @MainActor func transitionOn(
        _ action: Action,
        with context: Context?
    ) throws -> Self
}
