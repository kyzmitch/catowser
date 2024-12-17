//
//  ViewModelInterface.swift
//  catowser
//
//  Created by Andrey Ermoshin on 17.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

/// A context marker protocol for a state which receives an action to be able
/// to get an additional information for state conversion.
///
/// Usually context is a view model itself.
public protocol StateContext: AnyObject { }

/// Base view model interface always has to be a reference type (AnyObject)
@MainActor public protocol ViewModelInterface: AnyObject {
    /// Type of a state
    associatedtype State: ViewModelState where State.Action == Action
    /// Type of an action
    associatedtype Action: ViewModelAction
    
    /// UI state of view model
    var state: State { get set }
    /// Apply an action to view model state to get a new valid state
    func sendAction(
        _ action: Action,
        with context: StateContext
    ) throws
}

extension ViewModelInterface {
    public func sendAction(
        _ action: Action,
        with context: StateContext
    ) throws {
        state = state.handleAction(action)
    }
}
