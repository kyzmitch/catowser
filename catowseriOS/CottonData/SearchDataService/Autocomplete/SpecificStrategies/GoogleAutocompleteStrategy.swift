//
//  GoogleAutocompleteStrategy.swift
//  catowser
//
//  Created by Andrei Ermoshin on 6/21/22.
//  Copyright © 2022 Cotton (former Catowser). All rights reserved.
//

import Foundation
import BrowserNetworking
@preconcurrency import ReactiveSwift
import Combine
import CottonRestKit
import Alamofire

public final class GoogleContext: RestClientContext {
    public typealias Response = GSearchSuggestionsResponse
    public typealias Server = GoogleServer
    public typealias ReachabilityAdapter = AlamofireReachabilityAdaptee<Server>
    public typealias Encoder = JSONEncoding
    public typealias Client = RestClient<Server, ReachabilityAdapter, Encoder>

    public let client: Client
    public let rxSubscriber: HttpKitRxSubscriber
    public let subscriber: HttpKitSubscriber

    public init(_ client: Client,
                _ rxSubscriber: HttpKitRxSubscriber,
                _ subscriber: HttpKitSubscriber) {
        self.client = client
        self.rxSubscriber = rxSubscriber
        self.subscriber = subscriber
    }
}

public final class GoogleAutocompleteStrategy: SearchAutocompleteStrategy {
    public typealias Context = GoogleContext

    private let context: Context

    public init(_ context: Context) {
        self.context = context
    }

    public func suggestionsProducer(for text: String) -> SignalProducer<SearchSuggestionsResponse, HttpError> {
        context.client.googleSearchSuggestions(for: text, context.rxSubscriber)
            .map { SearchSuggestionsResponse($0) }
    }

    public func suggestionsPublisher(for text: String) -> AnyPublisher<SearchSuggestionsResponse, HttpError> {
        context.client.cGoogleSearchSuggestions(for: text, context.subscriber)
            .map { SearchSuggestionsResponse($0) }
            .eraseToAnyPublisher()
    }

    @available(swift 5.5)
    @available(macOS 12, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    public func suggestionsTask(for text: String) async throws -> SearchSuggestionsResponse {
        let response = try await context.client.aaGoogleSearchSuggestions(for: text)
        return SearchSuggestionsResponse(response)
    }
}
