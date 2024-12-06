//
//  SearchSuggestionsViewModelImpl.swift
//  CottonViewModels
//
//  Created by Andrei Ermoshin on 6/22/22.
//  Copyright © 2022 Cotton (former Catowser). All rights reserved.
//

import Foundation
import Combine
import FeatureFlagsKit
import CoreBrowser
import CottonUseCases
import AutoMockable

/// This is only needed now to not have a direct dependency on FutureManager
public protocol SearchViewContext: AutoMockable, Sendable {
    var appAsyncApiTypeValue: FeatureFlagsKit.AsyncApiType { get async }
    var webAutocompletionSourceValue: CoreBrowser.WebAutoCompletionSource { get async }
    var knownDomainsStorage: CoreBrowser.KnownDomainsSource { get }
}

public final class SearchSuggestionsViewModelImpl: SearchSuggestionsViewModel {
    /// Autocomplete client, probably need to depend on all possible use case (google, duckduckgo, etc.)
    private let autocompleteUseCase: AutocompleteSearchUseCase
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

    public init(
        _ autocompleteUseCase: AutocompleteSearchUseCase,
        _ context: SearchViewContext
    ) {
        state = .waitingForQuery
        self.autocompleteUseCase = autocompleteUseCase
        searchContext = context
    }

    deinit {
        /// Can't cancel `searchSuggestionsTaskHandler?.cancel()` because it is async
    }

    public func fetchSuggestions(_ query: String) async {
        async let autocompletionSource = searchContext.webAutocompletionSourceValue
        async let domainNames = searchContext.knownDomainsStorage.domainNames(whereURLContains: query)
        let fetchData = await (
            autocompletionSource: autocompletionSource,
            domainNames: domainNames
        )
        state = .knownDomainsLoaded(fetchData.domainNames)
        searchSuggestionsTaskHandler?.cancel()
        do {
            let suggestions = try await autocompleteUseCase.fetchSuggestions(fetchData.autocompletionSource, query)
            state = .everythingLoaded(fetchData.domainNames, suggestions)
        } catch {
            state = .everythingLoaded(fetchData.domainNames, [])
        }
    }
}
