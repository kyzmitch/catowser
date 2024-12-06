//
//  DNSResolvingStrategy.swift
//  catowser
//
//  Created by Andrei Ermoshin on 7/29/22.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import Foundation
import CottonRestKit
@preconcurrency import ReactiveSwift
import Combine
import AutoMockable

/// DNS resolving strategy interface should be sendable, because it is used by the use cases,
/// and any use case has to be sendable because a use case shouldn't have any state.
// swiftlint:disable comment_spacing
//sourcery: associatedtype = "Context: RestClientContext"
public protocol DNSResolvingStrategy: AnyObject, AutoMockable, Sendable {
    // swiftlint:enable comment_spacing

    associatedtype Context: RestClientContext
    init(_ context: Context)
    func domainNameResolvingProducer(_ originalURL: URL) -> SignalProducer<URL, DnsError>
    func domainNameResolvingPublisher(_ originalURL: URL) -> AnyPublisher<URL, DnsError>
    @available(swift 5.5)
    @available(macOS 12, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    func domainNameResolvingTask(_ originalURL: URL) async throws -> URL
}
