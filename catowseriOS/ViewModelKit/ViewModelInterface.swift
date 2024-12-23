//
//  ViewModelInterface.swift
//  catowser
//
//  Created by Andrey Ermoshin on 17.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import Combine

/// Base view model interface.
///
/// Always has to be a reference type (AnyObject)
@MainActor public protocol ViewModelInterface: AnyObject, Sendable {
    /// Type of the associated state
    associatedtype State: ViewModelState
    /// Type of an action
    associatedtype Action: ViewModelAction where Action == State.Action
    /// State context to not expose the view model type.
    /// It is temporarily without any type constraints, so, can potentially be for any state
    associatedtype Context: StateContext

    /// UI state of view model
    var state: State { get set }
    /// Combine publisher for the UI state
    var statePublisher: Published<State>.Publisher { get }
    /// State context which could help to convert the state on incoming action.
    /// Usually it should be a wrapper around view model implementation.
    var context: Context? { get }
    /// Apply an action to a view model state to get a new valid state
    /// - Parameter action: an action to apply to the state
    /// - Throws an error if incoming action is not valid for a current state or due to other errors
    func sendAction(
        _ action: Action
    ) throws
}
