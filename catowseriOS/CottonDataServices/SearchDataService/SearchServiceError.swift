//
//  SearchServiceError.swift
//  CottonDataServices
//
//  Created by Andrey Ermoshin on 03.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import DataServiceKit

/// Search data service error
public enum SearchServiceError: DataServiceKitError {
    case zombyInstance
    case strategyError(NSError)
    case requestDataWhenNotCorrectState
    case xmlParsingError(NSError)
    case failedToCreateSearchEngine

    public init(zombyInstance: Bool) {
        self = .zombyInstance
    }
}
