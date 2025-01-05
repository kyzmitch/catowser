//
//  SearchBarAction.swift
//  catowser
//
//  Created by Andrey Ermoshin on 16.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import CoreBrowser
import ViewModelKit

/// Search bar action to change the state
public enum SearchBarAction: Equatable, ViewModelAction {
    /// When search bar is in view mode - this is a request to move it to edit state.
    /// If search query string is not empty it also allows to set the title
    case startSearch(_ searchQuery: String?)
    /// When search bar is in edit mode - this is a request to move it back to view mode
    case cancelSearch
    /// Update on new tab site content
    case updateView(
        _ title: String,
        _ searchBarContent: String
    )
    /// Update to clear state
    case clearView
    /// Select some search suggestion
    case selectSuggestion(SuggestionType)

    /// Create enum case based on parameter of content type of a tab
    public static func create(
        _ value: CoreBrowser.Tab.ContentType
    ) -> SearchBarAction {
        switch value {
        case .blank, .favorites, .topSites, .homepage:
            return .clearView
        case .site(let site):
            return .updateView(site.title, site.searchBarContent)
        @unknown default:
            fatalError("Not handled tab state")
        }
    }
    
    /// All actions
    public static let allCases: [SearchBarAction] = [
        .startSearch(nil),
        .cancelSearch,
        .updateView("", ""),
        .clearView,
        .selectSuggestion(.suggestion(""))
    ]
    
}
