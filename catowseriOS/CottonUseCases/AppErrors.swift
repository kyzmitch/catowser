//
//  AppErrors.swift
//  catowser
//
//  Created by Andrei Ermoshin on 7/26/21.
//  Copyright © 2021 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import CottonDataServices

/// Errors used on use case level
public enum AppError: LocalizedError {
    case zombieSelf
    case searchDataServiceError(SearchServiceError)
    case erasedSearchDataServiceError(Error)
    case commandNotFinishedYet
    case tabsServiceError(TabsListError)
    
    public var errorDescription: String? {
        switch self {
        case .zombieSelf:
            "Use case reference is nil"
        case .searchDataServiceError(let searchServiceError):
            "Search data service failure (\(searchServiceError.errorDescription ?? "none"))"
        case .erasedSearchDataServiceError(let error):
            "Erased search data service failure (\(error.localizedDescription)"
        case .commandNotFinishedYet:
            "Same command not finished yet"
        case .tabsServiceError(let tabsListError):
            "Tabs data service failure (\(tabsListError.errorDescription ?? "none"))"
        }
    }
}
