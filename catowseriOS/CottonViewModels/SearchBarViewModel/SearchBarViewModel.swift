//
//  SearchBarViewModel.swift
//  CottonViewModels
//
//  Created by Andrey Ermoshin on 16.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import Combine
import UIKit

/// Search suggestions delegate interface
@MainActor public protocol SearchSuggestionsListDelegate: AnyObject {
    /// Some search suggestion was selected
    func searchSuggestionDidSelect(_ content: SuggestionType) async
}

/// Search bar view model interface
@MainActor public protocol SearchBarViewModel: ObservableObject, UISearchBarDelegate, SearchSuggestionsListDelegate, Sendable {
    /// publisher about visibility of search suggestions
    var showSearchSuggestions: Published<Bool>.Publisher { get }
    /// publisher about incoming search query
    var searchQuery: Published<String>.Publisher { get }
    /// publisher about incoming action
    var action: Published<SearchBarAction>.Publisher { get }
}
