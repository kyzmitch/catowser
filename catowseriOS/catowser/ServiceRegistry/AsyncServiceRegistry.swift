//
//  AsyncServiceRegistry.swift
//  catowser
//
//  Created by Andrei Ermoshin on 5/28/20.
//  Copyright © 2020 Cotton (former Catowser). All rights reserved.
//

import CoreBrowser
import CoreData
import FeaturesFlagsKit

/// Service registry for the data services with async constructors
private final class AsyncServiceRegistry {
    static func shared() async -> ManagerHolder {
        if let holder = internalInstance {
            return holder
        }

        let created: ManagerHolder
        if #available(iOS 17.0, *) {
            created = await ManagerHolder(UIServiceRegistry.shared().tabsSubject)
        } else {
            created = await ManagerHolder(nil)
        }
        internalInstance = created
        return created
    }

    /// Nonisolsated unsafe because it is private field and actual `shared()` is async and that is why it is ok
    static nonisolated(unsafe) private var internalInstance: ManagerHolder?

    fileprivate actor ManagerHolder {
        let tabsDataService: any TabsDataServiceProtocol
        private let database: Database

        init(_ tabsSubject: TabsDataSubjectProtocol?) async {
            guard let database = Database(name: "CottonDbModel") else {
                fatalError("Failed to initialize CoreData database")
            }
            do {
                try await database.loadStore()
            } catch {
                fatalError("Failed to initialize Database \(error.localizedDescription)")
            }
            self.database = database
            let contextClosure = { @Sendable [weak database] () -> NSManagedObjectContext? in
                guard let dbInterface = database else {
                    fatalError("Cotton db reference is nil")
                }
                return dbInterface.newPrivateContext()
            }
            let cacheProvider = TabsRepositoryImpl(database.viewContext, contextClosure)
            let strategy = NearbySelectionStrategy()
            tabsDataService = await TabsDataServiceFactory.create(
                cacheProvider,
                DefaultTabProvider.shared,
                strategy,
                tabsSubject,
                FeatureManager.shared.observingApiTypeValue()
            )
        }
    }
}

extension TabsDataServiceFactory {
    static var shared: any TabsDataServiceProtocol {
        get async {
            await AsyncServiceRegistry.shared().tabsDataService
        }
    }
}
