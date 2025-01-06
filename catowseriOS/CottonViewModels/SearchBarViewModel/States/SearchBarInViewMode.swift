//
//  SearchBarInViewMode.swift
//  catowser
//
//  Created by Andrey Ermoshin on 04.01.2025.
//  Copyright © 2025 Cotton (Catowser). All rights reserved.
//

/// View mode state
public final class SearchBarInViewMode<C: SearchBarStateContext>: SearchBarState<C>, @unchecked Sendable {
    /// Initializer
    init(
        titleString: String? = nil,
        searchBarContent: String? = nil
    ) {
        super.init()
        self.titleString = titleString
        self.searchBarContent = searchBarContent
    }
    
    @MainActor public override func transitionOn(
        _ action: Action,
        with context: Context?
    ) throws -> BaseState {
        let nextState: SearchBarState<C>
        switch action {
        case .startSearch(let query):
            let searchState = SearchBarInSearchMode<C>(
                query: query,
                titleString: titleString,
                searchBarContent: searchBarContent
            )
            nextState = searchState
        case .cancelSearch:
            throw SearchBarError.cannotCancelSearchWhenInViewMode
        case let .updateView(title, searchBarContent):
            self.titleString = title
            self.searchBarContent = searchBarContent
            nextState = self
        case .clearView:
            self.titleString = nil
            self.searchBarContent = nil
            nextState = self
        case .selectSuggestion:
            throw SearchBarError.cannotSeeSuggestionsInViewMode
        }
        return nextState
    }
    
    public override var showCancelButton: Bool {
        false
    }
}
