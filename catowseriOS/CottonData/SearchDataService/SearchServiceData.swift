//
//  SearchServiceData.swift
//  catowser
//
//  Created by Andrey Ermoshin on 26.11.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import DataServiceKit

public struct SuggestionsRequest: Sendable {
    let searchEngine: WebAutoCompletionSource
    let query: String
}

typealias DomainResolvingData = CommandExecutionData<URL, URL>
typealias SearchSuggestionsData = CommandExecutionData<SuggestionsRequest, [String]>

public struct SearchServiceData: GenericServiceData {
    var domainResolving: DomainResolvingData = .notStarted
    var searchSuggestions: SearchSuggestionsData = .notStarted
    
    public init() { }
    
    public var suggestions: [String] {
        get throws(SearchServiceError) {
            guard case .finished(let result) = searchSuggestions else {
                throw .requestedDataWhenNotCorrecrtState
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
            guard case .finished(let result) = domainResolving else {
                throw .requestedDataWhenNotCorrecrtState
            }
            switch result {
            case .success(let value):
                return value
            case .failure(let failure):
                throw .strategyError(failure)
            }
        }
    }
}
