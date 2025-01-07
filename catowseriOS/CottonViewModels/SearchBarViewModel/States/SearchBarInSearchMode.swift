//
//  SearchBarInSearchMode.swift
//  catowser
//
//  Created by Andrey Ermoshin on 04.01.2025.
//  Copyright © 2025 Cotton (Catowser). All rights reserved.
//

/// Search mode state (or search suggestions mode)
public final class SearchBarInSearchMode<C: SearchBarStateContext>: SearchBarState<C>, @unchecked Sendable {
    /// Init
    /// - Parameter query: optional search request text
    /// - Parameter overlayContent: text for overlay label
    /// - Parameter searchBarContent: text for search bar
    public init(
        _ query: String?,
        _ overlayContent: String?,
        _ searchBarContent: String?
    ) {
        super.init()
        self.query = query
        self.overlayContent = overlayContent
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
                overlayContent,
                searchBarContent
            )
        case let .updateView(overlayLabel, searchBarContent):
            self.overlayContent = overlayLabel
            self.searchBarContent = searchBarContent
            nextState = self
        case .clearView:
            nextState = SearchBarInViewMode<C>()
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
