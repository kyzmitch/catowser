//
//  SearchBarError.swift
//  catowser
//
//  Created by Andrey Ermoshin on 30.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

/// Search bar view model errors
public enum SearchBarError: LocalizedError {
    case invalidDummyState
    case cannotCancelSearchWhenInViewMode
    case alreadyInSearchMode
    case failToInitNewSiteValue
    case cannotSeeSuggestionsInViewMode
    case looksLikeUrlButNotExactly(String)
    case failToCreatUrlFromDomain
    
    public var errorDescription: String? {
        switch self {
        case .invalidDummyState:
            return "Invalid dummy state"
        case .cannotCancelSearchWhenInViewMode:
            return "Cannot cancel search when in view mode"
        case .alreadyInSearchMode:
            return "Already in search mode"
        case .failToInitNewSiteValue:
            return "Fail to init new site value"
        case .cannotSeeSuggestionsInViewMode:
            return "Cannot see suggestions in view mode"
        case .looksLikeUrlButNotExactly(let url):
            return "Looks like URL but not exactly \(url)"
        case .failToCreatUrlFromDomain:
            return "Fail to creat URL from domain"
        }
    }
}
