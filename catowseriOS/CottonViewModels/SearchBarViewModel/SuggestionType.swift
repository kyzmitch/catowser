//
//  SuggestionType.swift
//  CottonViewModels
//
//  Created by Andrey Ermoshin on 16.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

/// Search suggestion type in the list of combined suggestions
public enum SuggestionType: Equatable {
    /// Suggestion from the remote provider like any search engine like Google, etc.
    case suggestion(String)
    /// Suggestion is a known domain name
    case knownDomain(String)
    /// Suggestion looks like an URL (starts with https scheme)
    case looksLikeURL(String)
}
