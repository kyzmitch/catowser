//
//  TabsResource.swift
//  catowser
//
//  Created by Andrey Ermoshin on 14.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import CoreBrowser

/// Tabs interface for a database storage
public protocol TabsResource: AnyObject, Sendable {
    /// Updates tab content if tab with same identifier was found in DB or creates completely new tab
    func update(tab: CoreBrowser.Tab) throws -> CoreBrowser.Tab
    /// Remove all the tabs
    func forget(tabs: [CoreBrowser.Tab]) async throws -> [CoreBrowser.Tab]
    /// Remembers tab identifier as selected one
    func selectTab(_ tab: CoreBrowser.Tab) async throws
    /// Gets all tabs recorded in DB. Currently there is only one session, but later
    /// it should be possible to store and read tabs from different sessions like
    /// private browser session tabs & usual tabs.
    func tabsFromLastSession() async throws -> [CoreBrowser.Tab]
    /// Add a tab
    func remember(
        tab: CoreBrowser.Tab,
        andSelect select: Bool
    ) async throws -> CoreBrowser.Tab
    /// Gets an identifier of a selected tab or an error if no tab is present which isn't possible
    /// at least blank tab should be present.
    func selectedTabId() async throws -> CoreBrowser.Tab.ID
}
