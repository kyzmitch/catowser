//
//  TabsPreviewsAction.swift
//  catowser
//
//  Created by Andrei Ermoshin on 1/10/25.
//  Copyright © 2025 Cotton (Catowser). All rights reserved.
//

import CoreBrowser
import ViewModelKit

/// Tab previews view model action
public enum TabsPreviewsAction: ViewModelAction {
    case load
    case closeTab(index: Int)
    case select(CoreBrowser.Tab)
    case addTab
    
    public static let allCases: [TabsPreviewsAction] = [
        .load,
        .closeTab(index: -1),
        .select(.blank)
    ]
}
