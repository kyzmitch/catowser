//
//  DataServiceFactory.swift
//  catowser
//
//  Created by Andrey Ermoshin on 17.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import DataServiceKit

/// Data service factory to create the data services
public class DataServiceFactory {
    private init() {}
    /// Factory method to create tabs data service and hide an actual implementation
    public static func createTabsService(
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
    
    /// factory method to create search data service and hide an actual implementation
    public static func createSearchService(
        executionQueue: any DispatchQueueInterface,
        responseQueue: any DispatchQueueInterface,
        stratsFactory: SearchStrategiesFactoryProtocol
    ) -> any SearchDataServiceProtocol {
        SearchDataService(
            executionQueue: executionQueue,
            responseQueue: responseQueue,
            stratsFactory: stratsFactory
        )
    }
}
