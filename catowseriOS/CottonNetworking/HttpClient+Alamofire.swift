//
//  HttpClient+Alamofire.swift
//  BrowserNetworking
//
//  Created by Andrei Ermoshin on 1/25/22.
//  Copyright © 2022 Cotton (former Catowser). All rights reserved.
//

import CottonRestKit
@preconcurrency import ReactiveSwift
import CottonBase
import Combine

/// This typealias could be an issue, because the same defined in ReactiveSwift HttpClient+RxSwift.swift
public typealias RxProducer<R: ResponseType> = SignalProducer<R, HttpError>
/// Shorter name
public typealias RxSub<R, S, O: RxInterface> = RxSubscriber<R, S, O> where O.Observer.Response == R, O.Server == S
/// Shorter name for the subscriber type without dependencies
public typealias Sub<R: ResponseType, S: ServerDescription> = CottonRestKit.Subscriber<R, S>

extension RestClient {
    /// Makes a public not authenticated REST request with Reactive adapter
    ///
    /// - Parameter endpoint: An endpoint model describing the request information for specific server
    /// - Parameter adapter: A reactive HTTP adapter which is needed to genearalize the async API used to receive the response.
    public func makePublicRequest<T, B: HTTPRxAdapter>(
        for endpoint: Endpoint<Server>,
        transport adapter: B
    ) where B.Response == T, B.Server == Server {
        makeRxRequest(for: endpoint, withAccessToken: nil, transport: adapter)
    }

    /// Makes an authenticated REST request with Reactive adapter
    ///
    /// - Parameter endpoint: An endpoint model describing the request information for specific server
    /// - Parameter accessToken: An access token string needed for authorization
    /// - Parameter adapter: A reactive HTTP adapter which is needed to genearalize the async API used to receive the response.
    public func makeAuthorizedRequest<T, B: HTTPRxAdapter>(
        for endpoint: Endpoint<Server>,
        withAccessToken accessToken: String,
        transport adapter: B
    ) where B.Response == T, B.Server == Server {
        makeRxRequest(for: endpoint, withAccessToken: accessToken, transport: adapter)
    }

    /// Makes a public not authenticated REST request with Reactive adapter
    ///
    /// - Parameter endpoint: An endpoint model describing the request information for specific server
    /// - Parameter adapter: A reactive HTTP adapter which is needed to genearalize the async API used to receive the response.
    /// - Parameter subscriber: An object from the subscribers storage needed to return the response to the request initiator.
    /// - Returns a reactive producer object.
    public func makePublicRequestProducer<T, B: HTTPRxAdapter, RX>(
        for endpoint: Endpoint<Server>,
        transport adapter: B,
        subscriber: RxSubscriber<T, Server, RX>
    ) -> RxProducer<T> where B.Response == T, B.Server == Server, B.ObserverWrapper == RX {
        let producer = makeRequestProducer(
            for: endpoint,
            withAccessToken: nil,
            transport: adapter,
            subscriber: subscriber
        )
        return producer
    }

    /// Makes an authenticated REST request with Reactive adapter
    ///
    /// - Parameter endpoint: An endpoint model describing the request information for specific server
    /// - Parameter accessToken: An access token string needed for authorization
    /// - Parameter adapter: A reactive HTTP adapter which is needed to genearalize the async API used to receive the response.
    /// - Parameter subscriber: An object from the subscribers storage needed to return the response to the request initiator.
    /// - Returns a reactive producer object.
    public func makeAuthorizedRequestProducer<T, B: HTTPRxAdapter, RX>(
        for endpoint: Endpoint<Server>,
        withAccessToken accessToken: String,
        transport adapter: B,
        subscriber: RxSub<T, Server, RX>
    ) -> RxProducer<T> where B.Response == T, B.Server == Server, B.ObserverWrapper == RX {
        let producer = makeRequestProducer(
            for: endpoint,
            withAccessToken: accessToken,
            transport: adapter,
            subscriber: subscriber
        )
        return producer
    }

    /// Makes a public not authenticated REST request with a general response adapter
    ///
    /// - Parameter endpoint: An endpoint model describing the request information for specific server
    /// - Parameter adapter: An HTTP adapter which is needed to genearalize the async API used to receive the response.
    /// - Parameter subscriber: An object from the subscribers storage needed to return the response to the request initiator.
    /// - Returns an Apple.Combine publisher for Future object.
    public func makePublicRequestFuture<T, B: HTTPAdapter>(
        for endpoint: Endpoint<Server>,
        transport adapter: B,
        subscriber: Sub<T, Server>
    ) -> ResponseFuture<T> where B.Response == T, B.Server == Server {
        let future = makeRequestFuture(
            for: endpoint,
            withAccessToken: nil,
            transport: adapter,
            subscriber: subscriber
        )
        return future
    }

    /// Makes an authenticated REST request with a general response adapter
    ///
    /// - Parameter endpoint: An endpoint model describing the request information for specific server
    /// - Parameter accessToken: An access token string needed for authorization
    /// - Parameter adapter: An HTTP adapter which is needed to genearalize the async API used to receive the response.
    /// - Parameter subscriber: An object from the subscribers storage needed to return the response to the request initiator.
    /// - Returns an Apple.Combine publisher for Future object.
    public func makeAuthorizedRequestFuture<T, B: HTTPAdapter>(
        for endpoint: Endpoint<Server>,
        withAccessToken accessToken: String,
        transport adapter: B,
        subscriber: Sub<T, Server>
    ) -> ResponseFuture<T> where B.Response == T, B.Server == Server {
        let future = makeRequestFuture(
            for: endpoint,
            withAccessToken: accessToken,
            transport: adapter,
            subscriber: subscriber
        )
        return future
    }
}
