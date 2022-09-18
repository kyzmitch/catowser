//
//  SearchSuggestionsViewModel.swift
//  catowser
//
//  Created by Andrei Ermoshin on 6/21/22.
//  Copyright © 2022 andreiermoshin. All rights reserved.
//

import Foundation
import ReactiveSwift
import Combine

typealias KnownDomains = [String]
typealias QuerySuggestions = [String]

/// View state, without error, because we want to show at least known domains even if there was a network failure
/// Need to return to `waitingForQuery` state after view changes the text
enum SearchSuggestionsViewState: Equatable {
    case waitingForQuery
    case knownDomainsLoaded(KnownDomains)
    case everythingLoaded(KnownDomains, QuerySuggestions)
    
    func rowsCount(_ section: Int) -> Int {
        switch self {
        case .waitingForQuery:
            return 0
        case .knownDomainsLoaded(let knownDomains):
            return knownDomains.count
        case .everythingLoaded(let knownDomains, let querySuggestions):
            if section == 0 {
                return querySuggestions.count
            } else if section == 1 {
                return knownDomains.count
            } else {
                // impossible case
                assertionFailure("Not expected section number for suggestions state")
                return 0
            }
        }
    }
    
    var sectionsNumber: Int {
        switch self {
        case .waitingForQuery:
            return 0
        case .knownDomainsLoaded:
            return 1
        case .everythingLoaded:
            return 2
        }
    }
    
    func value(from indexPath: IndexPath) -> String? {
        switch self {
        case .knownDomainsLoaded(let knownDomains):
            return knownDomains[indexPath.row]
        case .everythingLoaded(let knownDomains, let querySuggestions):
            if indexPath.section == 0 {
                return querySuggestions[indexPath.row]
            } else if indexPath.section == 1 {
                return knownDomains[indexPath.row]
            } else {
                assertionFailure("Not expected section number for suggestions state")
                return nil
            }
        default:
            return nil
        }
    }
}

protocol SearchSuggestionsViewModel: AnyObject {
    /// Initiate fetching only after subscribing to the async interfaces below
    func fetchSuggestions(_ query: String)
    
    var rxState: MutableProperty<SearchSuggestionsViewState> { get }
    var combineState: CurrentValueSubject<SearchSuggestionsViewState, Never> { get }
    /// wrapped value for Published
    var state: SearchSuggestionsViewState { get }
    var statePublisher: Published<SearchSuggestionsViewState>.Publisher { get }
}
