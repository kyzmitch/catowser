//
//  TabsStoragable.swift
//  CottonDataServices
//
//  Created by Andrei Ermoshin on 5/28/20.
//  Copyright © 2020 Cotton (former Catowser). All rights reserved.
//

import CoreBrowser
import Foundation
import AutoMockable

/// Tabs repository factory
public final class TabsRepositoryFactory {
    /// Hide implementation and create repository instance
    public static func create(
        dbResource: TabsResource
    ) -> TabsRepository {
        TabsRepositoryImpl(dbResource)
    }
}

/// Tabs repository protocol can be sendable, because implementation
/// doesn't hold any state, only interface to the DB for now
/// so that, no need any synhronization.
public protocol TabsRepository: AutoMockable, Sendable {
    /// Defines human redable name for Int if it is describes index.
    /// e.g. implementation could use Index type instead.
    typealias TabIndex = Int

    /// The identifier of selected tab.
    func fetchSelectedTabId() async throws -> CoreBrowser.Tab.ID
    /// Changes selected tab only if it is presented in storage.
    ///
    /// - Parameter tab: The tab object to be selected.
    ///
    /// - Returns: An identifier of the selected tab.
    func select(tab: CoreBrowser.Tab) async throws -> CoreBrowser.Tab.ID

    /// Loads tabs data from storage.
    ///
    /// - Returns: A producer with tabs array or error.
    func fetchAllTabs() async throws -> [CoreBrowser.Tab]

    /// Adds a tab to storage
    ///
    /// - Parameter tab: The tab object to be added.
    func add(_ tab: CoreBrowser.Tab, select: Bool) async throws -> CoreBrowser.Tab

    /// Updates tab content
    ///
    /// - Parameter tab: The tab object to be updated. Usually only tab content needs to be updated.
    func update(tab: CoreBrowser.Tab) throws -> CoreBrowser.Tab

    /// Removes some tabs for current session
    func remove(tabs: [CoreBrowser.Tab]) async throws -> [CoreBrowser.Tab]
}
