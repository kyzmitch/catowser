//
//  SearchBarInViewMode.swift
//  catowser
//
//  Created by Andrey Ermoshin on 04.01.2025.
//  Copyright © 2025 Cotton (Catowser). All rights reserved.
//

/// View mode state
public final class SearchBarInViewMode: SearchBarState<SearchBarStateContextProxy>, @unchecked Sendable {
    @MainActor public override func transitionOn(
        _ action: Action,
        with context: Context?
    ) throws -> Self {
        let nextState: SearchBarState<SearchBarStateContextProxy>
        switch action {
        case .startSearch:
            nextState = SearchBarInSearchMode()
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
        return nextState as! Self
    }
    
    public override var showCancelButton: Bool {
        false
    }
}
