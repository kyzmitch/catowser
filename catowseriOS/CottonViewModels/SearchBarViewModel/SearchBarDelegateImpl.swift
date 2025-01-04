//
//  SearchBarDelegateImpl.swift
//  catowser
//
//  Created by Andrey Ermoshin on 04.01.2025.
//  Copyright © 2025 Cotton (Catowser). All rights reserved.
//

import UIKit
import CoreBrowser

/// Internal delegate implementation
/// which uses view model as a subject for this proxy.
final class SearchBarDelegateImpl: NSObject {
    /// Temporary property which automatically removes leading spaces.
    /// Can't declare it private due to compiler error.
    @LeadingTrimmed private var tempSearchText: String
    /// View model
    private let viewModel: SearchBarViewModel
    
    init(
        viewModel: SearchBarViewModel
    ) {
        self.viewModel = viewModel
        tempSearchText = ""
    }
}

// MARK: - UISearchBarDelegate

extension SearchBarDelegateImpl: UISearchBarDelegate {
    public func searchBar(
        _ searchBar: UISearchBar,
        textDidChange searchQuery: String
    ) {
        do {
            if searchQuery.isEmpty || searchQuery.looksLikeAURL() {
                try viewModel.sendAction(.cancelSearch)
            } else {
                try viewModel.sendAction(.startSearch(searchQuery))
            }
        } catch {
            print("textDidChange fail: \(error)")
        }
    }

    public func searchBar(
        _ searchBar: UISearchBar,
        shouldChangeTextIn range: NSRange,
        replacementText text: String
    ) -> Bool {
        guard let value = searchBar.text else {
            return text != " "
        }
        // UIKit's searchbar delegate uses modern String type
        // but at the same time legacy NSRange type
        // which can't be used in String API,
        // since it requires modern Range<String.Index>
        // https://exceptionshub.com/nsrange-to-rangestring-index.html
        let future = (value as NSString).replacingCharacters(in: range, with: text)
        // Only need to check that no leading spaces
        // trailing space is allowed to be able to construct
        // query requests with more than one word.
        tempSearchText = future
        // 400 IQ approach
        return tempSearchText == future
    }

    public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        do {
            try viewModel.sendAction(.startSearch(nil))
        } catch {
            print("TextDidBeginEditing error: \(error)")
        }
    }

    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        do {
            try viewModel.sendAction(.cancelSearch)
        } catch {
            print("CancelButtonClicked error: \(error)")
        }
        
    }

    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text else {
            return
        }
        let content: SuggestionType
        if text.looksLikeAURL() {
            content = .looksLikeURL(text)
        } else {
            // need to open web view with url of search engine and specific search queue
            content = .suggestion(text)
        }
        do {
            try viewModel.sendAction(.selectSuggestion(content))
        } catch {
            print("SearchButtonClicked error: \(error)")
        }
    }

    public func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        // called when `Cancel` pressed or search bar no more a first responder
    }
}
