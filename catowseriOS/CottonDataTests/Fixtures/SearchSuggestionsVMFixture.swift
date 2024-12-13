//
//  SearchSuggestionsVMFixture.swift
//  CoreCatowserTests
//
//  Created by Andrei Ermoshin on 1/8/23.
//  Copyright © 2023 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import XCTest
import CottonBase
import CottonRestKit
import CottonReactiveRestKit
@preconcurrency import ReactiveSwift
import Combine
import CottonNetworking
import SwiftyMocky

/// A known state against which a test is running for search suggestions vm
@MainActor
class SearchSuggestionsVMFixture: XCTestCase {
    var goodServerMock: MockedGoodSearchServer!
    var goodJsonEncodingMock: MockedGoodJSONEncoding!
    var reachabilityMock: NetworkReachabilityAdapterMock<MockedGoodSearchServer>!
    typealias Observer = Signal<MockedSearchResponse, HttpError>.Observer
    typealias ObserverWrapper = RxObserverWrapper<MockedSearchResponse, MockedGoodSearchServer, Observer>
    var subscriber: Sub<MockedSearchResponse, MockedGoodSearchServer>!
    var rxSubscriber: RxSubscriber<MockedSearchResponse, MockedGoodSearchServer, ObserverWrapper>!
    var goodRestClient: RestInterfaceMock<MockedGoodSearchServer,
                                          NetworkReachabilityAdapterMock<MockedGoodSearchServer>,
                                          MockedGoodJSONEncoding>!
    lazy var goodContextMock: MockedSearchContext = .init(goodRestClient, rxSubscriber, subscriber)
    lazy var strategyMock: SearchAutocompleteStrategyMock = .init(goodContextMock)
    lazy var autocompleteUseCaseMock = AutocompleteSearchUseCaseMock<SearchAutocompleteStrategyMock<MockedSearchContext>>()
    var searchViewContextMock: SearchViewContextMock!
    var knownDomainsStorageMock: KnownDomainsSourceMock!
    var fetchSuggestionsCounter = 0

    override func setUpWithError() throws {
        try super.setUpWithError()
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
        searchViewContextMock = .init()
        knownDomainsStorageMock = .init()
        strategyMock = .init(goodContextMock)
        fetchSuggestionsCounter = 0
    }
}
