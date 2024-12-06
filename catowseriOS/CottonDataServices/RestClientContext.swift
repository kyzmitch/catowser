//
//  RestClientContext.swift
//  catowser
//
//  Created by Andrei Ermoshin on 6/21/22.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import Foundation
import CottonRestKit
@preconcurrency import ReactiveSwift
import Combine
import CottonBase
import CottonReactiveRestKit
import CottonNetworking
import AutoMockable

extension CottonBase.ServerDescription: @unchecked Sendable {}

/// Rest client context should be sendable, because it is used by the strategies
/// and a strategy is used by the use cases which shouldn't store any state (state-less).
/// It means that a use case must be sendable which requires the context to be sendable as well.
// swiftlint:disable comment_spacing
//sourcery: associatedtype = "R: ResponseType"
//sourcery: associatedtype = "S: ServerDescription"
//sourcery: associatedtype = "RA: NetworkReachabilityAdapter where RA.Server == S"
//sourcery: associatedtype = "E: JSONRequestEncodable"
//sourcery: associatedtype = "C: RestInterface where C.Reachability == RA, C.Encoder == E"
//sourcery: typealias = "Response = R"
//sourcery: typealias = "Server = S"
//sourcery: typealias = "ReachabilityAdapter = RA"
//sourcery: typealias = "Encoder = E"
//sourcery: typealias = "Client = C"
public protocol RestClientContext: AnyObject, AutoMockable, Sendable {
    // swiftlint:enable comment_spacing
    associatedtype Response: ResponseType
    associatedtype Server: ServerDescription
    associatedtype ReachabilityAdapter: NetworkReachabilityAdapter where ReachabilityAdapter.Server == Server
    associatedtype Encoder: JSONRequestEncodable
    associatedtype Client: RestInterface where Client.Reachability == ReachabilityAdapter, Client.Encoder == Encoder

    /// Alias for a ReactiveSwift type with specific types in place of generics
    typealias Observer = Signal<Response, HttpError>.Observer
    /// Alias for a real type, no need to hide it under protocol
    typealias ObserverWrapper = RxObserverWrapper<Response, Server, Observer>
    /// Alias for a real type, no need to hide it under protocol
    typealias HttpKitRxSubscriber = RxSubscriber<Response, Server, ObserverWrapper>
    /// Alias for a real type, no need to hide it under protocol
    typealias HttpKitSubscriber = Sub<Response, Server>

    var client: Client { get }
    var rxSubscriber: HttpKitRxSubscriber { get }
    var subscriber: HttpKitSubscriber { get }

    init(_ client: Client,
         _ rxSubscriber: HttpKitRxSubscriber,
         _ subscriber: HttpKitSubscriber)
}
