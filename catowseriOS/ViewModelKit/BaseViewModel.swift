//
//  BaseViewModel.swift
//  catowser
//
//  Created by Andrey Ermoshin on 17.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import Combine

/// Base view model type.
///
/// It implements default code for base inerface and allows to use the actual types
/// for the state, action & state context.
///
/// It can be used for SwiftUI because it confirms to `ObservableObject` as well.
/// But doesn't have published property for a state for now.
open class BaseViewModel<
    S: ViewModelState,
    A: ViewModelAction,
    C: StateContext
>: ViewModelInterface, ObservableObject where S.Action == A {
    public typealias Action = A
    public typealias State = S
    public typealias Context = C
    
    /// UI state
    public var state: State
    /// State context computed property, it is nil for the base view model
    /// because the actual context type is not determined yet.
    open var context: Context? {
        nil
    }
    
    /// Creates a base view model with initial UI state
    public init() {
        self.state = .createInitial()
    }
    
    open func sendAction(
        _ action: Action
    ) throws {
        // Can't provide default implementation
        // because state context type is not determined yet
    }
}
