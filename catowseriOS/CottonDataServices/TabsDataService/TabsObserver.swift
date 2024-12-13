//
//  TabsObserver.swift
//  CottonDataServices
//
//  Created by Andrei Ermoshin on 5/28/20.
//  Copyright © 2020 Cotton (former Catowser). All rights reserved.
//

import CoreBrowser

/// Tabs observer interface.
/// No need to add delegate methods for tab close case, because anyway view must be removed right away.
/// Future directions:
/// https://github.com/apple/swift-evolution/blob/main/proposals/0395-observability.md
///
/// CoreBrowser.Tab did remove function is not needed, because we want to remove it from UI right away
///
/// This can be sendable, because all actor types are, and this one is Main actor
@MainActor public protocol TabsObserver: AnyObject, Sendable {
    /// Provide necessary data to render UI on the tablets
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

    func tabDidSelect(
        _ index: Int,
        _ content: CoreBrowser.Tab.ContentType,
        _ identifier: UUID
    ) async {
        // Only landscape/regular tabs list view use that
    }

    func tabDidAdd(
        _ tab: CoreBrowser.Tab,
        at index: Int
    ) async {
        // e.g. Counter view doesn't need to handle that
        // as it uses another delegate method with `tabsCount`
    }

    /* optional */ func tabDidReplace(
        _ tab: CoreBrowser.Tab,
        at index: Int
    ) async {}

    /* optional */ func updateTabsCount(with tabsCount: Int) async {}

    /* optional */ func initializeObserver(with tabs: [CoreBrowser.Tab]) async {}
}

/// A wrapper for TabsObserver to be able to store them by weak reference and be able to use Swift array
/// instead of NSPointerArray weakObjectsPointerArray which is still requires an actual type
/// instead of a protocol TabsObserver which can't be used in a collection data structure.
public final class TabsObserverProxy: @unchecked Sendable {
    weak var realSubject: TabsObserver?
    
    init(_ realSubject: TabsObserver) {
        self.realSubject = realSubject
    }
}

extension TabsObserverProxy: TabsObserver {
    public var tabsObserverName: String {
        get async {
            await realSubject?.tabsObserverName ?? String(describing: self)
        }
    }

    public func initializeObserver(with tabs: [CoreBrowser.Tab]) async {
        await realSubject?.initializeObserver(with: tabs)
    }
    
    public func updateTabsCount(with tabsCount: Int) async {
        await realSubject?.updateTabsCount(with: tabsCount)
    }
    
    public func tabDidAdd(_ tab: Tab, at index: Int) async {
        await realSubject?.tabDidAdd(tab, at: index)
    }
    
    public func tabDidSelect(
        _ index: Int,
        _ content: Tab.ContentType,
        _ identifier: UUID
    ) async {
        await realSubject?.tabDidSelect(index, content, identifier)
    }
    
    public func tabDidReplace(
        _ tab: Tab,
        at index: Int
    ) async {
        await realSubject?.tabDidReplace(tab, at: index)
    }
}
