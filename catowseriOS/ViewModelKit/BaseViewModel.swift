//
//  BaseViewModel.swift
//  catowser
//
//  Created by Andrey Ermoshin on 17.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import Combine

/// Base view model class for inheritance
open class BaseViewModel<
    S: ViewModelState,
    A: ViewModelAction
>: ViewModelInterface, ObservableObject where S.Action == A {
    public typealias Action = A
    public typealias State = S
    
    public var state: State
    
    public init() {
        self.state = .createInitial()
    }
    
    open func sendAction(
        _ action: Action
    ) throws { }
}
