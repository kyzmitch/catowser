//
//  SearchSuggestionsVMConcurrencyTests.swift
//  CoreCatowserTests
//
//  Created by Andrei Ermoshin on 1/8/23.
//  Copyright © 2023 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import XCTest
@testable import CottonData
import CottonBase
import CottonRestKit
import CottonReactiveRestKit
@preconcurrency import ReactiveSwift
import CottonNetworking
import Combine
import SwiftyMocky

@MainActor
final class SearchSuggestionsVMConcurrencyTests: SearchSuggestionsVMFixture {
    private var cancellables: Set<AnyCancellable>!

    override func setUpWithError() throws {
        try super.setUpWithError()
        cancellables = []
    }

    func testVMInitAndSuggestionsFetch() async throws {
        let vm: SearchSuggestionsViewModelImpl = .init(autocompleteUseCaseMock, searchViewContextMock)
        XCTAssertEqual(vm.state, .waitingForQuery)
        let input1 = "g"
        let input2 = "o"
        let expected1 = ["google", "gmail"]
        let known1 = ["google.com", "gmail.com"]
        let expected2 = ["opennet com", "overwatch"]
        let known2 = ["opennet.com", "blizzard.com"]
        let promiseValue1: SearchSuggestionsResponse = .init(input1, expected1)
        let promiseValue2: SearchSuggestionsResponse = .init(input2, expected2)

        Given(autocompleteUseCaseMock, .aaFetchSuggestions(.value(input1), willReturn: promiseValue1.textResults))
        Given(searchViewContextMock, .knownDomainsStorage(getter: knownDomainsStorageMock))
        Given(knownDomainsStorageMock, .domainNames(whereURLContains: .value(input1), willReturn: known1))
        await vm.fetchSuggestions(input1)
        XCTAssertEqual(vm.state, .everythingLoaded(known1, expected1))
        Given(autocompleteUseCaseMock, .aaFetchSuggestions(.value(input2), willReturn: promiseValue2.textResults))
        Given(searchViewContextMock, .knownDomainsStorage(getter: knownDomainsStorageMock))
        Given(knownDomainsStorageMock, .domainNames(whereURLContains: .value(input2), willReturn: known2))
        await vm.fetchSuggestions(input2)
        XCTAssertEqual(vm.state, .everythingLoaded(known2, expected2))
    }

    func testSuggestionsFetchFailure() async throws {
        let vm: SearchSuggestionsViewModelImpl = .init(autocompleteUseCaseMock, searchViewContextMock)
        XCTAssertEqual(vm.state, .waitingForQuery)
        let input1 = "g"
        let known1 = ["google.com", "gmail.com"]

        let error1 = HttpError.httpFailure(error: EndpointHttpError())
        Given(autocompleteUseCaseMock, .aaFetchSuggestions(.value(input1), willThrow: error1))
        Given(searchViewContextMock, .knownDomainsStorage(getter: knownDomainsStorageMock))
        Given(knownDomainsStorageMock, .domainNames(whereURLContains: .value(input1), willReturn: known1))
        await vm.fetchSuggestions(input1)
        XCTAssertEqual(vm.state, .everythingLoaded(known1, []))
    }
}
