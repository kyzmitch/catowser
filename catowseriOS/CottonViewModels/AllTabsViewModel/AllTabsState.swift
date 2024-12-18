//
//  AllTabsState.swift
//  catowser
//
//  Created by Andrey Ermoshin on 18.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import CoreBrowser
import ViewModelKit

public protocol AllTabsStateContext: StateContext {
    @MainActor func handleTabAdd(_ tab: CoreBrowser.Tab)
}

public struct AllTabsState<C: AllTabsStateContext>: ViewModelState {
    public typealias Context = C
    public typealias Action = AllTabsAction
    
    public static func createInitial() -> AllTabsState {
        .init()
    }
    
    @MainActor public func handleAction(
        _ action: Action,
        context: Context
    ) throws -> Self {
        switch action {
        case .addTab(let tab):
            context.handleTabAdd(tab)
        }
        return self
    }
}
