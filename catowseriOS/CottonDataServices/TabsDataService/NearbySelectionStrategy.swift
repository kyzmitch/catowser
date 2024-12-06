//
//  NearbySelectionStrategy.swift
//  CoreBrowser
//
//  Created by Andrei Ermoshin on 5/30/22.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import Foundation

/**
 Implements the algorithms for the nearby use case
 when the next closest tab needs to be selected.
 */
public struct NearbySelectionStrategy {
    public let makeTabActiveAfterAdding: Bool
    public init() {
        makeTabActiveAfterAdding = true
    }
}

extension NearbySelectionStrategy: TabSelectionStrategy {
    public func autoSelectedIndexAfterTabRemove(_ context: IndexSelectionContext, removedIndex: Int) async -> Int {
        let value: Int

        let currentIx = await context.currentlySelectedIndex
        if currentIx == removedIndex {
            // find if we're closing selected tab
            // select next - same behaviour is in Firefox for ios
            if await removedIndex == context.collectionLastIndex {
                value = removedIndex - 1
            } else {
                // if it is not last index, then it is automatically will become next index as planned
                // index is the same, but tab content will be different, so, need to notify observers
                // re-settings same value will trigger observers notification
                value = currentIx
            }
        } else {
            if removedIndex < currentIx {
                value = currentIx - 1
            } else {
                // for opposite case it will stay the same
                value = currentIx
            }
        }

        return value
    }
}
