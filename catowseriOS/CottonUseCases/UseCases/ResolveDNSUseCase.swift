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

public typealias DNSResolvingProducer = SignalProducer<URL, AppError>
public typealias DNSResolvingPublisher = AnyPublisher<URL, AppError>

/// Resolve domain name use case.
/// 
/// Use cases do not hold any mutable state, so that, any of them can be sendable.
public protocol ResolveDNSUseCase: BaseUseCase, AutoMockable, Sendable {
    func resolveDomainNameProducer(_ url: URL) -> DNSResolvingProducer
    func resolveDomainNamePublisher(_ url: URL) -> DNSResolvingPublisher
    func resolveDomainName(_ url: URL) async throws -> URL
}
