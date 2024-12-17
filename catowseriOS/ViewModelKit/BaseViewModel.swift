//
//  BaseViewModel.swift
//  catowser
//
//  Created by Andrey Ermoshin on 17.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

/// Base view model class for inheritance
open class BaseViewModel<
    S: ViewModelState,
    A: ViewModelAction
>: ViewModelInterface, StateContext where S.Action == A {
    public typealias Action = A
    public typealias State = S
    
    public var state: State
    
    public init(state: State) {
        self.state = state
    }
}
