//
//  ViewModelState.swift
//  catowser
//
//  Created by Andrey Ermoshin on 17.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

/// View model action marker interface
public protocol ViewModelAction: CaseIterable { }

/// View model state marker interface
public protocol ViewModelState {
    associatedtype Action: ViewModelAction
    
    /// Converts current state to another valid state based on input action
    func handleAction(_ action: Action) -> Self
    /// Create an initial state which is needed for View Model init
    static func createInitial() -> Self
}
