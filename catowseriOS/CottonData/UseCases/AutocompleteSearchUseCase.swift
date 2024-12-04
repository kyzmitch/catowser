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

public typealias WebSearchSuggestionsProducer = SignalProducer<[String], AppError>
public typealias WebSearchSuggestionsPublisher = AnyPublisher<[String], AppError>

/// Search auto-complete use case.
///
/// Use cases do not hold any mutable state, so that, any of them can be (should be) sendable.
public protocol AutocompleteSearchUseCase: BaseUseCase, AutoMockable, Sendable {
    func suggestionsProducer(_ query: String) -> WebSearchSuggestionsProducer
    func suggestionsPublisher(
        _ source: WebAutoCompletionSource,
        _ query: String
    ) -> WebSearchSuggestionsPublisher
    func fetchSuggestions(
        _ source: WebAutoCompletionSource,
        _ query: String
    ) async throws -> [String]
}
