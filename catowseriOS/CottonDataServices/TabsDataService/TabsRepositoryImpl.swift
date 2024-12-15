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

/// Tabs repository implementation
final class TabsRepositoryImpl {
    private let tabsDbResource: TabsResource

    init(_ tabsDbResource: TabsResource) {
        self.tabsDbResource = tabsDbResource
    }
}

extension TabsRepositoryImpl: TabsRepository {
    func select(tab: CoreBrowser.Tab) async throws -> CoreBrowser.Tab.ID {
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

    func fetchSelectedTabId() async throws -> CoreBrowser.Tab.ID {
        try await tabsDbResource.selectedTabId()
    }
}
