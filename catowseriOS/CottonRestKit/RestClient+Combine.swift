//
//  RestClient+Combine.swift
//  HttpKit
//
//  Created by Andrei Ermoshin on 4/28/20.
//  Copyright © 2020 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import Foundation
#if canImport(Combine)
import Combine
#endif
import CottonBase

extension RestClient {
    /// Apple's Combine Future publisher with generic parameter and Http type of error
    public typealias ResponseFuture<T> = Deferred<Publishers.HandleEvents<Future<T, HttpError>>>

    /// Makes a REST request with optional authentication and with Combine Future publisher
    ///
    /// - Parameter endpoint: An endpoint model describing the request information for specific server
    /// - Parameter accessToken: An optional access token string needed for authorization
    /// - Parameter adapter: An HTTP adapter which is needed to genearalize the async API used to receive the response.
    /// - Parameter subscriber: An object from the subscribers storage needed to return the response to the request initiator.
    /// - Returns an Apple.Combine publisher for Future object.
    public func makeRequestFuture<T, B: HTTPAdapter>(
        for endpoint: Endpoint<Server>,
        withAccessToken accessToken: String?,
        transport adapter: B,
        subscriber: Subscriber<T, Server>
    ) -> ResponseFuture<T> where B.Response == T, B.Server == Server {
        // Can't use Future without Deferred because
        // a Future will begin executing immediately when you create it.
        return Combine.Deferred {
            let subject: Future<T, HttpError> = .init { [weak self] (promise) in
                guard let self = self else {
                    promise(.failure(.zombieSelf))
                    return
                }

                adapter.transferToCombineState(promise, endpoint)
                subscriber.insert(adapter.handlerType)
                self.makeRequest(for: endpoint, withAccessToken: accessToken, transport: adapter)
            }
            return subject.handleEvents(
                receiveCompletion: { [weak subscriber] _ in
                    /**
                     Must capture `adapter` by strong reference comparing to
                     similar implementation for Rx, because the `adapter` is getting deallocated
                     for Combine implementation for some still unknown reason.
                     Actually we only store handlerType reference types in the ClientSubscriber sets
                     so, actually the first question is why Rx implementation was working
                     because I would expect that adapter is nil and you can't transfer execution back
                     to the handler
                     */
                    subscriber?.remove(adapter.handlerType)
                },
                receiveCancel: {
                    print("Implement Combine.Deferred cancel")
                }
            )
        }
    }
}
