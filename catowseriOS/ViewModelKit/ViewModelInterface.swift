//
//  ViewModelInterface.swift
//  catowser
//
//  Created by Andrey Ermoshin on 17.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

public protocol StateContext: AnyObject {
    associatedtype State: ViewModelState
}

/// Base view model interface always has to be a reference type (AnyObject)
@MainActor public protocol ViewModelInterface: AnyObject {
    /// Type of the associated state to have the context matched to the used state type
    associatedtype State: ViewModelState
    /// Type of an action
    associatedtype Action: ViewModelAction where Action == State.Action

    /// UI state of view model
    var state: State { get set }
    /// Apply an action to view model state to get a new valid state
    func sendAction(
        _ action: Action
    ) throws
}
