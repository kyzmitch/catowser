//
//  SearchBarInSearchMode.swift
//  catowser
//
//  Created by Andrey Ermoshin on 04.01.2025.
//  Copyright © 2025 Cotton (Catowser). All rights reserved.
//

/// Search mode state (or search suggestions mode)
public final class SearchBarInSearchMode: SearchBarState<SearchBarStateContextProxy>, @unchecked Sendable {
    @MainActor public override func transitionOn(
        _ action: Action,
        with context: Context?
    ) throws -> Self {
        let nextState: SearchBarState<SearchBarStateContextProxy>
        switch action {
        case .startSearch:
            throw SearchBarError.alreadyInSearchMode
        case .cancelSearch:
            nextState = SearchBarInViewMode()
        case let .updateView(title, searchBarContent):
            self.titleString = title
            self.searchBarContent = searchBarContent
            nextState = self
        case .clearView:
            self.titleString = nil
            self.searchBarContent = nil
            nextState = self
        case .selectSuggestion(let suggestion):
            nextState = SearchBarInViewMode()
            Task {
                try await context?.searchSuggestionDidSelect(suggestion)
            }
        }
        return nextState as! Self
    }
    
    public override var showCancelButton: Bool {
        true
    }
}
