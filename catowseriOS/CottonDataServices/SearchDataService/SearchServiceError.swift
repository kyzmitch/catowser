//
//  SearchServiceError.swift
//  CottonDataServices
//
//  Created by Andrey Ermoshin on 03.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import DataServiceKit

/// Search data service errors
public enum SearchServiceError: DataServiceKitError {
    case zombyInstance
    case strategyError(NSError)
    case requestDataWhenNotCorrectState
    case xmlParsingError(NSError)
    case failedToCreateSearchEngine

    public init(zombyInstance: Bool) {
        self = .zombyInstance
    }
    
    public var errorDescription: String? {
        switch self {
        case .zombyInstance:
            "Search data service is nil"
        case .strategyError(let nsError):
            "Search strategy failure (\(nsError.localizedDescription))"
        case .requestDataWhenNotCorrectState:
            "Requested data when incorrect state"
        case .xmlParsingError(let nsError):
            "XML parsing error (\(nsError.localizedDescription))"
        case .failedToCreateSearchEngine:
            "Failed to create search engine model"
        }
    }
}
