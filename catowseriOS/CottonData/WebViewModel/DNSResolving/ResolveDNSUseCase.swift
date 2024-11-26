//
//  ResolveDNSUseCase.swift
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

public typealias DNSResolvingProducer = SignalProducer<URL, DnsError>
public typealias DNSResolvingPublisher = AnyPublisher<URL, DnsError>

/// Resolve Domain name use case.
/// Use cases do not hold any mutable state, so that, any of them can be sendable.
// swiftlint:disable comment_spacing
//sourcery: associatedtype = "Strategy: DNSResolvingStrategy"
public protocol ResolveDNSUseCase: BaseUseCase, AutoMockable, Sendable {
    // swiftlint:enable comment_spacing

    associatedtype Strategy: DNSResolvingStrategy
    var strategy: Strategy { get }
    func rxResolveDomainName(_ url: URL) -> DNSResolvingProducer
    func cResolveDomainName(_ url: URL) -> DNSResolvingPublisher
    func aaResolveDomainName(_ url: URL) async throws -> URL
}
