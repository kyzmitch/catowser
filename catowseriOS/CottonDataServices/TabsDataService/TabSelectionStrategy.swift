//
//  TabSelectionStrategy.swift
//  CoreBrowser
//
//  Created by Andrei Ermoshin on 05/03/2019.
//  Copyright © 2019 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import Foundation
import AutoMockable

public protocol IndexSelectionContext: AutoMockable {
    var collectionLastIndex: Int { get async }
    var currentlySelectedIndex: Int { get async }
}

/// CoreBrowser.Tab selection protocol can be sendable, because implementation
/// only hold a constant which can't be mutated, so that, no any mutable state for now.
public protocol TabSelectionStrategy: AutoMockable, Sendable {
    /**
     A CoreBrowser.Tab selection strategy (Compositor) defines the algorithms of tab selection in specific cases
     - when tab was removed and need to select another
     */
    func autoSelectedIndexAfterTabRemove(_ context: IndexSelectionContext, removedIndex: Int) async -> Int
    var makeTabActiveAfterAdding: Bool { get }
}
