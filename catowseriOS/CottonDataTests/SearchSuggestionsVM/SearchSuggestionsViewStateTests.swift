//
//  SearchSuggestionsViewStateTests.swift
//  CoreCatowserTests
//
//  Created by Andrei Ermoshin on 1/8/23.
//  Copyright © 2023 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import XCTest

final class SearchSuggestionsViewStateTests: XCTestCase {
    let known1 = ["google.com", "gmail.com"]
    let expected1 = ["google", "gmail"]

    func testWaitingForQuery() throws {
        let state: SearchSuggestionsViewState = .waitingForQuery
        XCTAssertEqual(state, .waitingForQuery)
        XCTAssertEqual(state.rowsCount(Int.random(in: -1000...1000)), 0)
        XCTAssertEqual(state.sectionsNumber, 0)
        let row = Int.random(in: -1000...1000)
        let section =  Int.random(in: -1000...1000)
        XCTAssertNil(state.value(from: row, section: section))
    }

    func testKnownDomainsLoaded() throws {
        let state: SearchSuggestionsViewState = .knownDomainsLoaded(known1)
        XCTAssertEqual(state, .knownDomainsLoaded(known1))
        XCTAssertEqual(state.rowsCount(Int.random(in: -1000...1000)), known1.count)
        XCTAssertEqual(state.sectionsNumber, 1)
        let section =  Int.random(in: -1000...1000)
        XCTAssertNil(state.value(from: 3, section: section))
        XCTAssertEqual(state.value(from: 0, section: section), known1[0])
        XCTAssertEqual(state.value(from: 1, section: section), known1[1])
    }

    func testEverythingLoaded() throws {
        let state: SearchSuggestionsViewState = .everythingLoaded(known1, expected1)
        XCTAssertEqual(state, .everythingLoaded(known1, expected1))
        XCTAssertEqual(state.rowsCount(0), known1.count)
        XCTAssertEqual(state.rowsCount(1), expected1.count)
        XCTAssertEqual(state.rowsCount(-1), -1)
    }
}
