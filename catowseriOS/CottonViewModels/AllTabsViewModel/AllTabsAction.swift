//
//  AllTabsAction.swift
//  catowser
//
//  Created by Andrey Ermoshin on 18.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import CoreBrowser
import ViewModelKit

/// All tabs view model actions
public enum AllTabsAction: ViewModelAction {
    /// Add a tab action
    case addTab(CoreBrowser.Tab)
    
    /// All possible actions
    public static var allCases: [AllTabsAction] {
        [.addTab(.blank)]
    }
}
