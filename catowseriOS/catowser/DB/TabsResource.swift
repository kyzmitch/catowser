//
//  TabsResource.swift
//  catowser
//
//  Created by Andrei Ermoshin on 9/28/20.
//  Copyright © 2020 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import Foundation
import CoreBrowser
import CoreData
import CottonDataServices

fileprivate extension String {
    static let threadName = "tabsStore"
}

/// Класс обертка над клиентом базы данных, имеет синхронизацию через DispatchQueue
final class TabsResource: @unchecked Sendable {
    private var dbClient: TabsDBClient

    /// Needs to be checked on every access to `dbClient` to not use wrong context
    /// functions can return empty data if it's not initialized state
    private var isStoreInitialized = false

    private let queue: DispatchQueue = .init(label: .queueNameWith(suffix: .threadName))

    /// Creates an instance of TabsResource which is a wrapper around CoreData Store class
    ///
    /// - Parameters:
    ///   - temporaryContext: Temporary core data context to be able to compile init.
    ///   For valid instance we must create Core Data context on
    ///   specific thread to keep using it only with this thread.
    ///   - privateContextCreator: We have to call this closure on specific thread and
    ///    use same thread for any other usages of this context.
    init(temporaryContext: NSManagedObjectContext,
         privateContextCreator: @escaping @Sendable () -> NSManagedObjectContext?) {
        // Creating temporary instance to be able to use background thread
        // to properly create private CoreData context
        let dummyStore: TabsDBClient = .init(temporaryContext)
        dbClient = dummyStore
        queue.async { [weak self] in
            guard let self = self else {
                fatalError("Tabs Resource is nil in init")
            }
            guard let correctContext = privateContextCreator() else {
                fatalError("Tabs Resource closure returns no private CoreData context")
            }
            self.dbClient = .init(correctContext)
            self.isStoreInitialized = true
        }
    }

    /// Updates tab content if tab with same identifier was found in DB or creates completely new tab
    func update(tab: CoreBrowser.Tab) throws -> CoreBrowser.Tab {
        guard isStoreInitialized else {
            throw TabResourceError.storeNotInitializedYet
        }

        do {
            try self.dbClient.update(tab: tab)
            return tab
        } catch {
            throw TabResourceError.insertError(error)
        }
    }

    /// Remove all the tabs
    func forget(tabs: [CoreBrowser.Tab]) async throws -> [CoreBrowser.Tab] {
        guard isStoreInitialized else {
            throw TabResourceError.storeNotInitializedYet
        }

        do {
            if tabs.count == 1 {
                try dbClient.remove(tab: tabs[0])
            } else {
                try dbClient.removeAll(tabs: tabs)
            }
            return tabs
        } catch {
            throw TabResourceError.deleteError(error)
        }
    }

    /// Remembers tab identifier as selected one
    func selectTab(_ tab: CoreBrowser.Tab) async throws {
        guard isStoreInitialized else {
            throw TabResourceError.storeNotInitializedYet
        }

        do {
            try await self.dbClient.select(tab: tab)
        } catch {
            throw TabResourceError.selectedTabId(error)
        }
    }

    /// Gets all tabs recorded in DB. Currently there is only one session, but later
    /// it should be possible to store and read tabs from different sessions like
    /// private browser session tabs & usual tabs.
    func tabsFromLastSession() async throws -> [CoreBrowser.Tab] {
        guard isStoreInitialized else {
            throw TabResourceError.storeNotInitializedYet
        }
        return try await dbClient.fetchAllTabs()
    }

    func remember(tab: CoreBrowser.Tab, andSelect select: Bool) async throws -> CoreBrowser.Tab {
        guard isStoreInitialized else {
            throw TabResourceError.storeNotInitializedYet
        }
        try await dbClient.insert(tab: tab)
        if select {
            try await dbClient.select(tab: tab)
        }
        return tab
    }

    /// Gets an identifier of a selected tab or an error if no tab is present which isn't possible
    /// at least blank tab should be present.
    func selectedTabId() async throws -> UUID {
        guard isStoreInitialized else {
            throw TabResourceError.storeNotInitializedYet
        }
        return try await dbClient.selectedTabId()
    }
}
