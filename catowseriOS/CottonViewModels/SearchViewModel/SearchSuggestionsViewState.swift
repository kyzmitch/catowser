//
//  SearchSuggestionsViewState.swift
//  catowser
//
//  Created by Andrey Ermoshin on 15.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//


public typealias KnownDomains = [String]
public typealias QuerySuggestions = [String]

/// View state, without error, because we want to show at least known domains even if there was a network failure
/// Need to return to `waitingForQuery` state after view changes the text
public enum SearchSuggestionsViewState: Equatable {
    case waitingForQuery
    case knownDomainsLoaded(KnownDomains)
    case everythingLoaded(KnownDomains, QuerySuggestions)

    public func rowsCount(_ section: Int) -> Int {
        switch self {
        case .waitingForQuery:
            return 0
        case .knownDomainsLoaded(let knownDomains):
            return knownDomains.count
        case .everythingLoaded(let knownDomains, let querySuggestions):
            if section == 0 {
                return knownDomains.count
            } else if section == 1 {
                return querySuggestions.count
            } else {
                let errMsg = "Not expected section number for suggestions state"
                #if TESTING
                #else
                // can't assert here because of unit tests
                print(errMsg)
                #endif
                return -1
            }
        }
    }

    public var sectionsNumber: Int {
        switch self {
        case .waitingForQuery:
            return 0
        case .knownDomainsLoaded:
            return 1
        case .everythingLoaded:
            return 2
        }
    }

    public func value(from row: Int, section: Int) -> String? {
        switch self {
        case .knownDomainsLoaded(let knownDomains):
            return knownDomains[safe: row]
        case .everythingLoaded(let knownDomains, let querySuggestions):
            if section == 0 {
                return knownDomains[row]
            } else if section == 1 {
                return querySuggestions[row]
            } else {
                assertionFailure("Not expected section number for suggestions state")
                return nil
            }
        default:
            return nil
        }
    }

    public func sectionTitle(section: Int) -> String? {
        switch section {
        case 0:
            return NSLocalizedString(
                "ttl_search_history_domains",
                comment: "Known domains"
            )
        case 1:
            return NSLocalizedString(
                "ttl_search_suggestions",
                comment: "Suggestions from search engine"
            )
        default:
            return nil
        }
    }
}
