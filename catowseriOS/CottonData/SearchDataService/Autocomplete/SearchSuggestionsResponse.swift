//
//  SearchSuggestionsResponse.swift
//  catowser
//
//  Created by Andrei Ermoshin on 6/21/22.
//  Copyright © 2022 Cotton (former Catowser). All rights reserved.
//

import Foundation
import BrowserNetworking

/// Need to have one common response type, because there are more than one provider (Google, DDGo, etc.)
public struct SearchSuggestionsResponse {
    let queryText: String
    let textResults: [String]

    init(_ googleResponse: GSearchSuggestionsResponse) {
        queryText = googleResponse.queryText
        textResults = googleResponse.textResults
    }

    init(_ ddgoResponse: DDGoSuggestionsResponse) {
        queryText = ddgoResponse.queryText
        textResults = ddgoResponse.textResults
    }

    init(_ query: String, _ results: [String]) {
        queryText = query
        textResults = results
    }
}
