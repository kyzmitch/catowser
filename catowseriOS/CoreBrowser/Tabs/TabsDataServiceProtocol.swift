//
//  TabsDataServiceProtocol.swift
//  catowser
//
//  Created by Andrei Ermoshin on 11/21/24.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import DataServiceKit

/// Tabs data service interface
public protocol TabsDataServiceProtocol: GenericDataServiceActorProtocol, TabsSubject where
Command == TabsServiceCommand,
ServiceData == TabsServiceData { }

/// Tabs data service factory to create it
public class TabsDataServiceFactory {
    private init() {}
    /// Factory method to hide actual implementation and only disclose the interface
    /// the only disadvantage is that you can't call static methods on a protocol instance
    /// and have to create some temporary type to call static func
    public static func create(
        _ tabsRepository: TabsRepository,
        _ positioning: TabsStatesInterface,
        _ selectionStrategy: TabSelectionStrategy,
        _ tabsSubject: TabsDataSubjectProtocol?,
        _ observingType: ObservingApiType
    ) async -> any TabsDataServiceProtocol {
        await TabsDataService(
            tabsRepository,
            positioning,
            selectionStrategy,
            tabsSubject,
            observingType
        )
    }
}
