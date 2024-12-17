//
//  SearchSuggestionsViewModel.swift
//  CottonViewModels
//
//  Created by Andrei Ermoshin on 6/21/22.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import Combine

/// Search suggestions view model, provides auto-completion results
@MainActor public protocol SearchSuggestionsViewModel: ObservableObject, Sendable {
    /// Initiate fetching only after subscribing to the async interfaces below
    func fetchSuggestions(_ query: String) async
    /// Concurrency state, also can be used as a synchronous state. A wrapped value for Published
    var state: SearchSuggestionsViewState { get }
    /// This is a replacement for Concurrency's `Task.Handler`, property wrapper can't be defined in protocol
    var statePublisher: Published<SearchSuggestionsViewState>.Publisher { get }
}
