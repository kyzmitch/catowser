//
//  SearchDataServiceProtocol.swift
//  CottonDataServices
//
//  Created by Andrey Ermoshin on 05.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import DataServiceKit

/// Search data service interface
public protocol SearchDataServiceProtocol: GenericDataServiceProtocol, Sendable where
Command == SearchServiceCommand,
ServiceData == SearchServiceData,
ServiceError == SearchServiceError { }


/// Search data service factory to create it
public class SearchDataServiceFactory {
    private init() {}
    /// Factory method to hide actual implementation and only disclose the interface
    /// the only disadvantage is that you can't call static methods on a protocol instance
    /// and have to create some temporary type to call static func
    public static func create(
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
