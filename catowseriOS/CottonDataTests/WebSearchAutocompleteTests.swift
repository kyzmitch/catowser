//
//  AutocompleteWebSearchUseCaseImpl.swift
//  CoreCatowserTests
//
//  Created by Andrei Ermoshin on 10/18/22.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import XCTest
@testable import CottonData
import CottonBase
import CottonRestKit
import CottonReactiveRestKit
@preconcurrency import ReactiveSwift
import Combine
import CottonNetworking
import SwiftyMocky

final class WebSearchAutocompleteTests: XCTestCase {
    private var goodServerMock: MockedGoodDnsServer!
    private var goodJsonEncodingMock: MockedGoodJSONEncoding!
    private var reachabilityMock: NetworkReachabilityAdapterMock<MockedGoodDnsServer>!
    typealias Observer = Signal<MockedDNSResponse, HttpError>.Observer
    typealias ObserverWrapper = RxObserverWrapper<MockedDNSResponse, MockedGoodDnsServer, Observer>
    private var subscriber: Sub<MockedDNSResponse, MockedGoodDnsServer>!
    private var rxSubscriber: RxSubscriber<MockedDNSResponse, MockedGoodDnsServer, ObserverWrapper>!
    private var goodRestClient: RestInterfaceMock<MockedGoodDnsServer,
                                                  NetworkReachabilityAdapterMock<MockedGoodDnsServer>,
                                                  MockedGoodJSONEncoding>!
    private lazy var goodContextMock: MockedDNSContext = .init(goodRestClient, rxSubscriber, subscriber)
    private lazy var strategyMock: SearchAutocompleteStrategyMock = .init(goodContextMock)
    private var cancellables: Set<AnyCancellable>!

    private let input = "g"
    private let results = ["google", "gmail"]

    override func setUpWithError() throws {
        try super.setUpWithError()
        cancellables = []
        goodServerMock = .init()
        goodJsonEncodingMock = .init()
        // swiftlint:disable:next force_unwrapping
        reachabilityMock = NetworkReachabilityAdapterMock(server: goodServerMock)!
        subscriber = .init()
        rxSubscriber = .init()
        goodRestClient = .init(server: goodServerMock,
                               jsonEncoder: goodJsonEncodingMock,
                               reachability: reachabilityMock,
                               httpTimeout: 10)
        goodContextMock = .init(goodRestClient, rxSubscriber, subscriber)
        strategyMock = .init(goodContextMock)
    }

    func testRxWebSearchAutocomplete() throws {
        let searchSuggestionsResponse: SearchSuggestionsResponse = .init(input, results)
        typealias SuggestionProducer = SignalProducer<SearchSuggestionsResponse, HttpError>
        let responseProducer: SuggestionProducer = .init(value: searchSuggestionsResponse)
        Given(strategyMock, .suggestionsProducer(for: .value(input), willReturn: responseProducer))
        let autoCompleteFacade: AutocompleteSearchUseCaseImpl = .init(strategyMock)
        let producer = autoCompleteFacade.rxFetchSuggestions(input)
        let expectationRxSuggestionFail = XCTestExpectation(description: "Suggestions were not received")
        producer.startWithResult { result in
            expectationRxSuggestionFail.fulfill()
            // swiftlint:disable:next force_try
            let received = try! result.get()
            XCTAssertEqual(received, self.results)
        }
        wait(for: [expectationRxSuggestionFail], timeout: 1)
    }

    func testCombineWebSearchAutocomplete() throws {
        let promiseValue: SearchSuggestionsResponse = .init(input, results)
        let responsePublisher: AnyPublisher<SearchSuggestionsResponse, HttpError> = Future
            .success(promiseValue)
            .eraseToAnyPublisher()
        Given(strategyMock, .suggestionsPublisher(for: .value(input), willReturn: responsePublisher))
        let autoCompleteFacade: AutocompleteSearchUseCaseImpl = .init(strategyMock)
        let publisher = autoCompleteFacade.combineFetchSuggestions(input)
        let expectationRxSuggestionFail = XCTestExpectation(description: "Suggestions were not received")
        let cancellable = publisher.sink { completion in
            XCTAssertEqual(completion, .finished)
        } receiveValue: { received in
            expectationRxSuggestionFail.fulfill()
            XCTAssertEqual(received, self.results)
        }
        cancellables.insert(cancellable)
        wait(for: [expectationRxSuggestionFail], timeout: 1)
    }

    func testConcurrencyWebSearchAutocomplete() async throws {
        let value: SearchSuggestionsResponse = .init(input, results)
        Given(strategyMock, .suggestionsTask(for: .value(input), willReturn: value))
        let autoCompleteFacade: AutocompleteSearchUseCaseImpl = .init(strategyMock)
        let received = try await autoCompleteFacade.aaFetchSuggestions(input)
        XCTAssertEqual(received, results)
    }
}
