//
//  SearchBarError.swift
//  catowser
//
//  Created by Andrey Ermoshin on 30.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

/// Search bar view model errors
public enum SearchBarError: Error {
    case invalidDummyState
    case cannotCancelSearchWhenInViewMode
    case alreadyInSearchMode
    case failToInitNewSiteValue
    case cannotSeeSuggestionsInViewMode
}
