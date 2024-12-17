//
//  TabsPreviewState.swift
//  catowser
//
//  Created by Andrey Ermoshin on 17.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import CoreBrowser

/// A typealias for a Box with the tabs
public typealias TabsBox = Box<[CoreBrowser.Tab]>

/// Tab previews state
public enum TabsPreviewState {
    /// Maybe it is not needed state, but it is required for scalability when some user will have 100 tabs
    case loading
    /// Actual collection for tabs, at least one tab always will be in it
    case tabs(dataSource: TabsBox, selectedId: UUID?)

    /// Number of items for each state
    public var itemsNumber: Int {
        switch self {
        case .loading:
            return 0
        case .tabs(let box, _):
            return box.value.count
        }
    }
}
