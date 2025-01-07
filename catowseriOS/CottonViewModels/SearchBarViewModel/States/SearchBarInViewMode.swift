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
    /// - Parameter overlayContent: text for overlay label from previous state
    /// - Parameter searchBarContent: text for search bar from previous state
    init(
        _ overlayContent: String? = nil,
        _ searchBarContent: String? = nil
    ) {
        super.init()
        self.overlayContent = overlayContent
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
                query,
                overlayContent,
                searchBarContent
            )
            nextState = searchState
        case .cancelSearch:
            throw SearchBarError.cannotCancelSearchWhenInViewMode
        case let .updateView(overlayLabel, searchBarContent):
            self.overlayContent = overlayLabel
            self.searchBarContent = searchBarContent
            nextState = self
        case .clearView:
            nextState = SearchBarInViewMode<C>()
        case .selectSuggestion:
            throw SearchBarError.cannotSeeSuggestionsInViewMode
        }
        return nextState
    }
    
    public override var showCancelButton: Bool {
        false
    }
}
