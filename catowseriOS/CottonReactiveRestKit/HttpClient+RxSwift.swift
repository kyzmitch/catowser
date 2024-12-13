//
//  HttpClient+RxSwift.swift
//  ReactiveHttpKit
//
//  Created by Andrei Ermoshin on 11/29/21.
//  Copyright © 2021 Cotton (former Catowser). All rights reserved.
//

import CottonRestKit
@preconcurrency import ReactiveSwift
import CottonBase

/// This typealias could be an issue, because the same defined in BrowserNetworking HttpClient+Alamofire.swift
public typealias RxProducer<R: ResponseType> = SignalProducer<R, HttpError>
public typealias RxVoidProducer = SignalProducer<Void, HttpError>

extension RestClient {
    /// Makes a REST request reactive signal producer with a specific return JSON type
    ///
    /// - Parameter endpoint: An endpoint model describing the request information for specific server
    /// - Parameter accessToken: An optional access token string needed for authorization if needed
    /// - Parameter adapter: An HTTP adapter which is needed to genearalize the async API used to receive the response.
    /// - Parameter subscriber: An object from the subscribers storage needed to return the response to the request initiator.
    /// - Returns a reactive signal producer of specific type
    public func makeRequestProducer<T, B: HTTPRxAdapter, RX>(
        for endpoint: Endpoint<Server>,
        withAccessToken accessToken: String?,
        transport adapter: B,
        subscriber: RxSubscriber<T, Server, RX>) -> RxProducer<T>
    where B.Response == T, B.Server == Server, B.ObserverWrapper == RX {
        let producer: SignalProducer<T, HttpError> = .init { [weak self] (observer, lifetime) in
            guard let self = self else {
                observer.send(error: .zombieSelf)
                return
            }

            adapter.transferToRxState(observer, lifetime, endpoint)
            subscriber.insert(adapter.handlerType)
            self.makeRxRequest(for: endpoint, withAccessToken: accessToken, transport: adapter)
        }

        return producer.on(failed: { [weak subscriber] _ in
            subscriber?.remove(adapter.handlerType)
        }, completed: { [weak subscriber, weak adapter] in
            guard let adapter = adapter else {
                return
            }
            subscriber?.remove(adapter.handlerType)
        })
    }

    /// Makes a REST request reactive signal producer without return value
    ///
    /// - Parameter endpoint: An endpoint model describing the request information for specific server
    /// - Parameter accessToken: An optional access token string needed for authorization if needed
    /// - Parameter adapter: An HTTP adapter which is needed to genearalize the async API used to receive the response.
    /// - Parameter subscriber: An object from the subscribers storage needed to return the response to the request initiator.
    /// - Returns a reactive signal producer without any type (Void)
    public func makeVoidRequestProducer<B: HTTPRxVoidAdapter, RX>(
        for endpoint: Endpoint<Server>,
        withAccessToken accessToken: String?,
        transport adapter: B,
        subscriber: RxVoidSubscriber<Server, RX>
    ) -> RxVoidProducer where B.Server == Server, B.Observer == RX {
        let producer: SignalProducer<Void, HttpError> = .init { [weak self] (observer, lifetime) in
            guard let self = self else {
                observer.send(error: .zombieSelf)
                return
            }

            adapter.transferToRxState(observer, lifetime, endpoint)
            subscriber.insert(adapter.handlerType)
            self.makeRxVoidRequest(for: endpoint, withAccessToken: accessToken, transport: adapter)
        }
        return producer.on(failed: { [weak subscriber] _ in
            subscriber?.remove(adapter.handlerType)
        }, completed: { [weak subscriber, weak adapter] in
            guard let adapter = adapter else {
                return
            }
            subscriber?.remove(adapter.handlerType)
        })
    }
}
