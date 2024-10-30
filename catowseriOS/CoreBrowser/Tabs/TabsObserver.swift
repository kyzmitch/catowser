//
//  TabsObserver.swift
//  CoreBrowser
//
//  Created by Andrei Ermoshin on 5/28/20.
//  Copyright © 2020 Cotton (former Catowser). All rights reserved.
//

import Foundation

/// Tabs observer interface.
/// No need to add delegate methods for tab close case, because anyway view must be removed right away.
/// Future directions:
/// https://github.com/apple/swift-evolution/blob/main/proposals/0395-observability.md
///
/// CoreBrowser.Tab did remove function is not needed, because we want to remove it from UI right away
///
/// This can be sendable, because all actor types are, and this one is Main actor
@MainActor
public protocol TabsObserver: AnyObject, Sendable {
    /// Prodive necessary data to render UI on tablets
    ///
    /// - Parameter tabs: Tabs from cache at application start.
    func initializeObserver(with tabs: [CoreBrowser.Tab]) async
    /// To be able to search specific observer.
    var tabsObserverName: String { get async }
    /// Updates observer with tabs count.
    ///
    /// - Parameter tabsCount: New number of tabs.
    func updateTabsCount(with tabsCount: Int) async
    /// Tells other observers about new tab.
    /// We can pause drawing new tab on view layer
    /// to be able firstly determine type of initial tab state.
    ///
    /// - parameters:
    ///     - tab: new tab
    ///     - index: where to add new object
    func tabDidAdd(_ tab: CoreBrowser.Tab, at index: Int) async
    /// Tells observer that index has changed.
    ///
    /// - parameters:
    ///     - index: new selected index.
    ///     - content: CoreBrowser.Tab content, e.g. can be site. Need to pass it to allow browser to change content in web view.
    ///     - identifier: needed to quickly determine visual state (selected view or not)
    func tabDidSelect(
        _ index: Int,
        _ content: CoreBrowser.Tab.ContentType,
        _ identifier: UUID
    ) async
    /// Notifies about tab content type changes or `site` changes
    ///
    /// - parameters:
    ///     - tab: new tab for replacement
    ///     - index: original tab's index whichneeds to be replaced
    func tabDidReplace(_ tab: CoreBrowser.Tab, at index: Int) async
}

/// Marks optional functions for protocol
/// because `optional` keyword can be only used for objc types
public extension TabsObserver {
    var tabsObserverName: String {
        get async {
            String(describing: self)
        }
    }

    func tabDidSelect(_ index: Int, _ content: CoreBrowser.Tab.ContentType, _ identifier: UUID) async {
        // Only landscape/regular tabs list view use that
    }

    func tabDidAdd(_ tab: CoreBrowser.Tab, at index: Int) async {
        // e.g. Counter view doesn't need to handle that
        // as it uses another delegate method with `tabsCount`
    }

    /* optional */ func tabDidReplace(_ tab: CoreBrowser.Tab, at index: Int) async {}

    /* optional */ func updateTabsCount(with tabsCount: Int) async {}

    /* optional */ func initializeObserver(with tabs: [CoreBrowser.Tab]) async {}
}

/// An actual type instead of a protocol to be able to use it in NSHashTable
open class BaseTabsObserver: TabsObserver { }
