//
//  SearchSuggestionsViewModelImpl.swift
//  catowser
//
//  Created by Andrei Ermoshin on 6/22/22.
//  Copyright © 2022 Cotton (former Catowser). All rights reserved.
//

import Foundation
import Combine
import FeaturesFlagsKit
import CoreBrowser
import AutoMockable

/// This is only needed now to not have a direct dependency on FutureManager
public protocol SearchViewContext: AutoMockable {
    var appAsyncApiTypeValue: AsyncApiType { get async }
    var knownDomainsStorage: KnownDomainsSource { get }
}

public final class SearchSuggestionsViewModelImpl: SearchSuggestionsViewModel {
    /// Autocomplete client, probably need to depend on all possible use case (google, duckduckgo, etc.)
    private let autocompleteUseCase: any AutocompleteSearchUseCase
    /// search view context
    private let searchContext: SearchViewContext

    // MARK: - state observers

    @Published public var state: SearchSuggestionsViewState
    /// State publisher
    public var statePublisher: Published<SearchSuggestionsViewState>.Publisher { $state }

    // MARK: - cancelation handlers

    #if swift(>=5.5)
    @available(swift 5.5)
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    lazy var searchSuggestionsTaskHandler: Task<[String], Error>? = nil
    #endif

    public init(_ autocompleteUseCase: any AutocompleteSearchUseCase, _ context: SearchViewContext) {
        state = .waitingForQuery
        self.autocompleteUseCase = autocompleteUseCase
        searchContext = context
    }

    deinit {
        /// Can't cancel `searchSuggestionsTaskHandler?.cancel()` because it is async
    }

    public func fetchSuggestions(_ query: String) async {
        let domainNames = await searchContext.knownDomainsStorage.domainNames(whereURLContains: query)
        state = .knownDomainsLoaded(domainNames)
        searchSuggestionsTaskHandler?.cancel()
        do {
            let suggestions = try await autocompleteUseCase.fetchSuggestions(query)
            state = .everythingLoaded(domainNames, suggestions)
        } catch {
            state = .everythingLoaded(domainNames, [])
        }
    }
}
