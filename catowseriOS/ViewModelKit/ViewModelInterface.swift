//
//  ViewModelInterface.swift
//  catowser
//
//  Created by Andrey Ermoshin on 17.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

/// View model state context type,
/// It is optional for the state, but could be usefull to
/// determine how to convert from one state value to another.
/// Usually state context is a view model itself, but
/// view model implementation is better to be hidden.
@MainActor public protocol StateContext: AnyObject, Sendable { }

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
    /// State context which is actually just this view model, but with a wrapper type
    var context: Context? { get }
    /// Apply an action to a view model state to get a new valid state
    /// - Parameter action: an action to apply to the state
    /// - Throws an error if incoming action is not valid for a current state or due to other errors
    func sendAction(
        _ action: Action
    ) throws
}
