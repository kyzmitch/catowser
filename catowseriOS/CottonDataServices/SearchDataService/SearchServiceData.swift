//
//  SearchServiceData.swift
//  CottonDataServices
//
//  Created by Andrey Ermoshin on 26.11.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import CoreBrowser
import DataServiceKit

/// Input data for a search suggestions command
public struct SuggestionsRequest: Sendable {
    let searchAutocompletionSource: WebAutoCompletionSource
    let query: String
    /// Initializer
    public init(
        _ searchAutocompletionSource: WebAutoCompletionSource,
        _ query: String
    ) {
        self.searchAutocompletionSource = searchAutocompletionSource
        self.query = query
    }
}

typealias DomainResolvingData = CommandExecutionData<URL, URL>
typealias SearchSuggestionsData = CommandExecutionData<SuggestionsRequest, [String]>
typealias SearchURLData = CommandExecutionData<Void, URL>

/// Search service data state
public struct SearchServiceData: GenericServiceData {
    /// state of domain name resolving command data
    var resolvingDomainName: DomainResolvingData = .notStarted
    /// state of search suggestions for auto-completion command data
    var fetchingSearchSuggestions: SearchSuggestionsData = .notStarted
    /// state of constructing search URL using search engine
    var constructingSearchURL: SearchURLData = .notStarted
    
    public init() { }
    
    public var suggestions: [String] {
        get throws(SearchServiceError) {
            guard case .finished(let result) = fetchingSearchSuggestions else {
                throw .requestDataWhenNotCorrectState
            }
            switch result {
            case .success(let value):
                return value
            case .failure(let failure):
                throw .strategyError(failure)
            }
        }
    }
    
    public var resolvedURL: URL {
        get throws(SearchServiceError) {
            guard case .finished(let result) = resolvingDomainName else {
                throw .requestDataWhenNotCorrectState
            }
            switch result {
            case .success(let value):
                return value
            case .failure(let failure):
                throw .strategyError(failure)
            }
        }
    }
    
    public var searchURL: URL {
        get throws(SearchServiceError) {
            guard case .finished(let result) = constructingSearchURL else {
                throw .requestDataWhenNotCorrectState
            }
            switch result {
            case .success(let value):
                return value
            case .failure(let failure):
                throw .xmlParsingError(failure)
            }
        }
    }
}
