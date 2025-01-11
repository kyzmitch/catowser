//
//  AllTabsState.swift
//  catowser
//
//  Created by Andrey Ermoshin on 18.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import CoreBrowser
import ViewModelKit

/// All tabs view model state
public struct AllTabsState<C: AllTabsStateContext>: ViewModelState {
    public typealias Context = C
    public typealias Action = AllTabsAction
    public typealias BaseState = AllTabsState
    
    public static func createInitial() -> BaseState {
        .init()
    }
    
    @MainActor public func transitionOn(
        _ action: Action,
        with context: Context?
    ) async throws -> BaseState {
        switch action {
        case .addTab(let tab):
            context?.handleTabAdd(tab)
        }
        return self
    }
}
