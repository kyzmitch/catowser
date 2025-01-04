//
//  SearchBarStateContext.swift
//  catowser
//
//  Created by Andrey Ermoshin on 30.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import ViewModelKit

/// Search bar state context interface
public protocol SearchBarStateContext: StateContext, SearchSuggestionsListDelegate { }

/// Search bar state context proxy
//// to hide search bar view model implementation.
public final class SearchBarStateContextProxy: SearchBarStateContext {
    private let subject: any SearchBarStateContext
    
    init(subject: any SearchBarStateContext) {
        self.subject = subject
    }
    
    public func searchSuggestionDidSelect(_ content: SuggestionType) async throws {
        try await subject.searchSuggestionDidSelect(content)
    }
}
