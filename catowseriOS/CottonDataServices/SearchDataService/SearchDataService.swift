//
//  SearchDataService.swift
//  CottonDataServices
//
//  Created by Andrey Ermoshin on 26.11.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import Combine
import CoreBrowser
import CottonData
import DataServiceKit

/// An interface for a factory to be able to mock it for the unit tests
public protocol SearchStrategiesFactoryProtocol: AnyObject {
    func googleDnsResolvingStrategy() -> any DNSResolvingStrategy
    func duckDuckGoSearchStrategy() -> any SearchAutocompleteStrategy
    func googleSearchStrategy() -> any SearchAutocompleteStrategy
}

/// A data service needed to find/search any data needed for the app.
/// Currently it searches for the search suggestions to support auto-completion
/// and also can resolve domain names in the URLs to have ip addresses instead.
///
/// Can be unchecked sendable, because thread-safety is accomplished using recursive mutex.
final class SearchDataService: GenericConcurrentDataService<SearchServiceCommand, SearchServiceData, SearchServiceError>, SearchDataServiceProtocol, @unchecked Sendable {

    private var autocompleteHandler: AnyCancellable?
    private var domainNameResolveHandler: AnyCancellable?
    private let stratsFactory: SearchStrategiesFactoryProtocol
    
    /// Initializer
    init(
        executionQueue: any DispatchQueueInterface,
        responseQueue: any DispatchQueueInterface,
        stratsFactory: SearchStrategiesFactoryProtocol
    ) {
        self.stratsFactory = stratsFactory
        super.init(
            executionQueue: executionQueue,
            responseQueue: responseQueue
        )
    }

    public override func handleCommand(
        _ command: Command,
        _ input: ServiceData?
    ) {
        switch command {
        case let .fetchAutocompleteSuggestions(_, searchEngine, query):
            handleSuggestionsFetch(
                command: command,
                searchAutocompleteSource: searchEngine,
                query: query
            )
        case let .resolveDomainNameInURL(_, urlWithDomainName):
            handleDomainNameResolve(
                command,
                urlWithDomainName
            )
        case let .fetchSearchURL(_, suggestion, source):
            handleConstructSearchEngineURL(
                command,
                source,
                suggestion
            )
        }
    }
}

// MARK: - private functions

private extension SearchDataService {
    
    // MARK: - Command handlers

    func handleSuggestionsFetch(
        command: Command,
        searchAutocompleteSource: WebAutoCompletionSource,
        query: String
    ) {
        if case .started(input: let existingRequest) = serviceData.fetchingSearchSuggestions,
           existingRequest?.query == query {
            // already doing exact same request,
            // can finish it later and return without an error
            return
        }
        if let autocompleteHandler {
            autocompleteHandler.cancel()
        }
        let autocompleteStrategy: any SearchAutocompleteStrategy
        // Could be improved if more search engines need to be added by using subclasses instead of an enum
        switch searchAutocompleteSource {
        case .google:
            autocompleteStrategy = stratsFactory.googleSearchStrategy()
        case .duckduckgo:
            autocompleteStrategy = stratsFactory.duckDuckGoSearchStrategy()
        @unknown default:
            fatalError("New search engine must be handled")
        }
        let inputRequest = SuggestionsRequest(searchAutocompleteSource, query)
        serviceData.fetchingSearchSuggestions = .started(input: inputRequest)
        autocompleteHandler = autocompleteStrategy.suggestionsPublisher(for: query)
            .map { $0.textResults }
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    break
                case .failure(let failure):
                    self?.finishSimilarCommands(command, .failure(.strategyError(failure as NSError)))
                }
            }, receiveValue: { [weak self] suggestions in
                guard let self else {
                    return
                }
                serviceData.fetchingSearchSuggestions = .finished(output: .success(suggestions))
                finishSimilarCommands(command, .success(serviceData))
            })
    }
    
    func handleDomainNameResolve(
        _ command: Command,
        _ urlWithDomainName: URL
    ) {
        if let domainNameResolveHandler {
            domainNameResolveHandler.cancel()
        }
        let dnsResolveStrategy = stratsFactory.googleDnsResolvingStrategy()
        domainNameResolveHandler = dnsResolveStrategy.domainNameResolvingPublisher(urlWithDomainName)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    break
                case .failure(let failure):
                    guard let self else {
                        return
                    }
                    serviceData.resolvingDomainName = .finished(output: .failure(SearchServiceError.strategyError(failure as NSError)))
                    finishCommand(command, .failure(.strategyError(failure as NSError)))
                }
            }, receiveValue: { [weak self] resolvedURL in
                guard let self else {
                    return
                }
                serviceData.resolvingDomainName = .finished(output: .success(resolvedURL))
                finishCommand(command, .success(serviceData))
            })
    }

    func handleConstructSearchEngineURL(
        _ command: Command,
        _ selectedPluginName: WebAutoCompletionSource,
        _ suggestion: String
    ) {
        let client = parseSearchEngine(selectedPluginName)
        guard let url = client.searchURLForQuery(suggestion) else {
            finishCommand(command, .failure(.failedToCreateSearchEngine))
            return
        }
        serviceData.constructingSearchURL = .finished(output: .success(url))
        finishCommand(command, .success(serviceData))
    }
    
    // MARK: - private functions
    
    func parseSearchEngine(
        _ selectedPluginName: WebAutoCompletionSource
    ) -> SearchEngine {
        let optionalXmlData = XmlSearchPluginResource.read(
            with: selectedPluginName,
            on: .main
        )
        guard let xmlData = optionalXmlData else {
            return .googleSearchEngine()
        }

        let osDescription: OpenSearch.Description
        do {
            osDescription = try OpenSearch.Description(data: xmlData)
        } catch {
            print("Open search xml parser error: \(error.localizedDescription)")
            return .googleSearchEngine()
        }

        return osDescription.html
    }
    
    func finishSimilarCommands(
        _ command: Command,
        _ output: Result<ServiceData, ServiceError>
    ) {
        // could be improved later by searching for all similar
        // commands and finishing them with the same output
        finishCommand(command, output)
    }
}
