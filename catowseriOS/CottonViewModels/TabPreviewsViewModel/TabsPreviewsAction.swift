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
    /// Load all the tabs
    case load
    /// Close specific tab at index
    case closeTab(index: Int)
    /// Select different tab
    case select(CoreBrowser.Tab)
    /// Select tab by id and only change the state, saving was done already
    case selectTabIdWithoutSaving(CoreBrowser.Tab.ID)
    /// Handle user tap on + tab button
    case addDefaultTab
    
    public static let allCases: [TabsPreviewsAction] = [
        .load,
        .closeTab(index: -1),
        .select(.blank),
        .selectTabIdWithoutSaving(UUID()),
        .addDefaultTab
    ]
}
