//
//  DuckDuckGoSearchEndpoint.swift
//  BrowserNetworking
//
//  Created by Andrey Ermoshin on 19.02.2022.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import CottonRestKit
import Combine
@preconcurrency import ReactiveSwift
import CottonBase
import CottonReactiveRestKit
import Alamofire

public typealias DDGoSuggestionsClient = RestClient<DuckDuckGoServer,
                                                    AlamofireReachabilityAdaptee<DuckDuckGoServer>,
                                                    JSONEncoding>
typealias DDGoSuggestionsEndpoint = Endpoint<DuckDuckGoServer>

extension Endpoint where S == DuckDuckGoServer {
    static func duckduckgoSuggestions(query: String) throws -> DDGoSuggestionsEndpoint {
        guard !query.isEmpty else {
            throw HttpError.emptyQueryParam
        }

        let withoutSpaces = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !withoutSpaces.isEmpty else {
            throw HttpError.spacesInQueryParam
        }

        let items: [URLQueryItem] = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "type", value: "list")
        ]
        let headers: [CottonBase.HTTPHeader] = [.ContentType(type: .jsonsuggestions), .Accept(type: .jsonsuggestions)]

        /**
         https://youtrack.jetbrains.com/issue/KT-44108

         .freeze() doesn't affect Swift or Objective-C objects, they are just opaque for freezing,
         and anything these objects refer doesn't get frozen as well.
         */
        let frozenEndpoint = DDGoSuggestionsEndpoint(
            httpMethod: .get,
            path: "ac",
            headers: Set(headers),
            encodingMethod: .QueryString(items: items.kotlinArray))
        return frozenEndpoint
    }
}

public struct DDGoSuggestionsResponse: ResponseType {
    public static var successCodes: [Int] {
        [200]
    }

    public let queryText: String
    public let textResults: [String]

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        queryText = try container.decode(String.self)
        textResults = try container.decode([String].self)
    }
}

public typealias DDGoRxSignal = Signal<DDGoSuggestionsResponse, HttpError>.Observer
public typealias DDGoRxInterface = RxObserverWrapper<DDGoSuggestionsResponse,
                                                     DuckDuckGoServer,
                                                     DDGoRxSignal>
public typealias DDGoSuggestionsClientRxSubscriber = RxSubscriber<DDGoSuggestionsResponse,
                                                                  DuckDuckGoServer,
                                                                  DDGoRxInterface>
public typealias DDGoSuggestionsProducer = SignalProducer<DDGoSuggestionsResponse, HttpError>
public typealias DDGoSuggestionsClientSubscriber = Sub<DDGoSuggestionsResponse,
                                                       DuckDuckGoServer>
public typealias DDGoSuggestionsPublisher = AnyPublisher<DDGoSuggestionsResponse, HttpError>

extension RestClient where Server == DuckDuckGoServer {
    public func duckDuckGoSuggestions(
        for text: String,
        subscriber: DDGoSuggestionsClientRxSubscriber
    ) -> DDGoSuggestionsProducer {
        let endpoint: DDGoSuggestionsEndpoint
        do {
            endpoint = try .duckduckgoSuggestions(query: text)
        } catch let error as HttpError {
            return DDGoSuggestionsProducer.init(error: error)
        } catch {
            return DDGoSuggestionsProducer.init(error: .failedConstructRequestParameters)
        }

        let adapter: AlamofireHTTPRxAdaptee<DDGoSuggestionsResponse,
                                            DuckDuckGoServer,
                                            DDGoRxInterface> = .init(.waitsForRxObserver)
        let producer = self.rxMakePublicRequest(for: endpoint, transport: adapter, subscriber: subscriber)
        return producer
    }

    public func cDuckDuckgoSuggestions(
        for text: String,
        subscriber: DDGoSuggestionsClientSubscriber
    ) -> DDGoSuggestionsPublisher {
        let endpoint: DDGoSuggestionsEndpoint
        do {
            endpoint = try .duckduckgoSuggestions(query: text)
        } catch let error as HttpError {
            return DDGoSuggestionsPublisher(Future.failure(error))
        } catch {
            return DDGoSuggestionsPublisher(Future.failure(.failedConstructRequestParameters))
        }

        let adapter: AlamofireHTTPAdaptee<DDGoSuggestionsResponse, DuckDuckGoServer> = .init(.waitsForCombinePromise)
        let future = self.cMakePublicRequest(for: endpoint, transport: adapter, subscriber: subscriber)
        return future.eraseToAnyPublisher()
    }
}
