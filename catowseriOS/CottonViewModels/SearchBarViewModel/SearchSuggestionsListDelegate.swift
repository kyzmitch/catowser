//
//  SearchSuggestionsListDelegate.swift
//  catowser
//
//  Created by Andrey Ermoshin on 30.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

/// Search suggestions delegate interface
@MainActor public protocol SearchSuggestionsListDelegate: AnyObject {
    /// Some search suggestion was selected
    func searchSuggestionDidSelect(_ content: SuggestionType) async throws
}
