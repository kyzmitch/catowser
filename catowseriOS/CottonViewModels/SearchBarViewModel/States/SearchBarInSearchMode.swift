//
//  SearchBarInSearchMode.swift
//  catowser
//
//  Created by Andrey Ermoshin on 04.01.2025.
//  Copyright © 2025 Cotton (Catowser). All rights reserved.
//

/// Search mode state (or search suggestions mode)
public final class SearchBarInSearchMode<C: SearchBarStateContext>: SearchBarState<C>, @unchecked Sendable {
    public init(
        query: String?,
        titleString: String?,
        searchBarContent: String?
    ) {
        super.init()
        self.query = query
        self.titleString = titleString
        self.searchBarContent = searchBarContent
    }
    
    @MainActor public override func transitionOn(
        _ action: Action,
        with context: Context?
    ) throws -> BaseState {
        let nextState: SearchBarState<C>
        switch action {
        case .startSearch:
            throw SearchBarError.alreadyInSearchMode
        case .cancelSearch:
            nextState = SearchBarInViewMode<C>(
                titleString: titleString,
                searchBarContent: searchBarContent
            )
        case let .updateView(title, searchBarContent):
            self.titleString = title
            self.searchBarContent = searchBarContent
            nextState = self
        case .clearView:
            self.titleString = nil
            self.searchBarContent = nil
            nextState = self
        case .selectSuggestion(let suggestion):
            nextState = SearchBarInViewMode<C>()
            Task {
                try await context?.searchSuggestionDidSelect(suggestion)
            }
        }
        return nextState
    }
    
    public override var showCancelButton: Bool {
        true
    }
}
