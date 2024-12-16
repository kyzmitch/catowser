//
//  SearchBarViewModel.swift
//  CottonViewModels
//
//  Created by Andrey Ermoshin on 16.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import Combine
import UIKit

@MainActor public protocol SearchSuggestionsListDelegate: AnyObject {
    func searchSuggestionDidSelect(_ content: SuggestionType) async
}

@MainActor public protocol SearchBarViewModel: ObservableObject, UISearchBarDelegate, SearchSuggestionsListDelegate, Sendable {
    var showSearchSuggestions: Published<Bool>.Publisher { get }
    var searchQuery: Published<String>.Publisher { get }
    var action: Published<SearchBarAction>.Publisher { get }
}
