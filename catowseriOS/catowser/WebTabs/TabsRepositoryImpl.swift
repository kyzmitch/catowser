//
//  TabsCache.swift
//  catowser
//
//  Created by Andrei Ermoshin on 28/01/2019.
//  Copyright © 2019 Cotton (former Catowser). All rights reserved.
//

import Foundation
import CoreBrowser
import CoreData
import CottonDataServices

/**
 Declaring CoreBrowser.Tab storage type in host app instead of `CoreBrowser` framework,
 to allow use app settings like default tab content which only can be stored in host app.
 
 Later need to add tabs rest/firebase client dependency to use it as a 2nd (remote) data source.
 */
final class TabsRepositoryImpl {
    private let tabsDbResource: TabsResource

    init(_ temporaryContext: NSManagedObjectContext,
         _ privateContextCreator: @escaping @Sendable () -> NSManagedObjectContext?) {
        tabsDbResource = .init(temporaryContext: temporaryContext,
                               privateContextCreator: privateContextCreator)
    }
}

extension TabsRepositoryImpl: TabsRepository {
    func select(tab: CoreBrowser.Tab) async throws -> UUID {
        do {
            try await tabsDbResource.selectTab(tab)
            return tab.id
        } catch {
            throw TabStorageError.dbResourceError(error)
        }
    }

    func update(tab: CoreBrowser.Tab) throws -> CoreBrowser.Tab {
        do {
            return try tabsDbResource.update(tab: tab)
        } catch {
            throw TabStorageError.dbResourceError(error)
        }
    }

    func remove(tabs: [CoreBrowser.Tab]) async throws -> [CoreBrowser.Tab] {
        do {
            return try await tabsDbResource.forget(tabs: tabs)
        } catch {
            throw TabStorageError.dbResourceError(error)
        }
    }

    func fetchAllTabs() async throws -> [CoreBrowser.Tab] {
        try await tabsDbResource.tabsFromLastSession()
    }

    func add(_ tab: CoreBrowser.Tab, select: Bool) async throws -> CoreBrowser.Tab {
        try await tabsDbResource.remember(tab: tab, andSelect: select)
    }

    func fetchSelectedTabId() async throws -> UUID {
        try await tabsDbResource.selectedTabId()
    }
}
