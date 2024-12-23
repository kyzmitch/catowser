//
//  BrowserToolbarAction.swift
//  catowser
//
//  Created by Andrey Ermoshin on 23.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import ViewModelKit

/// All tabs view model actions
public enum BrowserToolbarAction: ViewModelAction {
    case goForward
    case goBack
    case reload
    case updateBackNavigation(canGoBack: Bool)
    
    public static var allCases: [BrowserToolbarAction] {
        [
            .goForward,
            .goBack,
            .reload,
            .updateBackNavigation(canGoBack: true)
        ]
    }
}
