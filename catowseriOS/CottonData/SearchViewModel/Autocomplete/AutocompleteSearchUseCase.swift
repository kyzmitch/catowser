//
//  AutocompleteSearchUseCase.swift
//  CottonData
//
//  Created by Andrey Ermoshin on 27.01.2024.
//  Copyright © 2024 Cotton (former Catowser). All rights reserved.
//

import DataServiceKit
import Foundation
import CoreBrowser
@preconcurrency import ReactiveSwift
import Combine
import CottonRestKit
import AutoMockable

public typealias WebSearchSuggestionsProducer = SignalProducer<[String], HttpError>
public typealias WebSearchSuggestionsPublisher = AnyPublisher<[String], HttpError>

/// Autocomplete search use case.
/// Use cases do not hold any mutable state, so that, any of them can be sendable.
// swiftlint:disable comment_spacing
//sourcery: associatedtype = "Strategy: SearchAutocompleteStrategy"
public protocol AutocompleteSearchUseCase: BaseUseCase, AutoMockable, Sendable {
    // swiftlint:enable comment_spacing

    associatedtype Strategy: SearchAutocompleteStrategy
    var strategy: Strategy { get }
    func rxFetchSuggestions(_ query: String) -> WebSearchSuggestionsProducer
    func combineFetchSuggestions(_ query: String) -> WebSearchSuggestionsPublisher
    func aaFetchSuggestions(_ query: String) async throws -> [String]
}
