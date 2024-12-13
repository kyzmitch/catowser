//
//  RestClient.swift
//  HttpKit
//
//  Created by Andrei Ermoshin on 10/11/19.
//  Copyright © 2019 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import Foundation
#if canImport(Combine)
import Combine
#endif
import CottonBase

fileprivate extension String {
    static let threadName = "Client"
}

public typealias HttpTypedResult<T> = Result<T, HttpError>
public typealias TypedResponseClosure<T> = (HttpTypedResult<T>) -> Void

/// An interface of a server description can be sendable because it is a model.
/// Can mark it as retroactive because it is from my CottonBase library.
extension CottonBase.ServerDescription: @unchecked @retroactive Sendable {}

/// Rest client.
///
/// It should be sendable because is used in the context for the strategy
/// and strategy is used by the use cases which can't store any mutable state.
public final class RestClient<
    S: ServerDescription,
    R: NetworkReachabilityAdapter,
    E: JSONRequestEncodable
>: @unchecked Sendable, RestInterface where R.Server == S {
    public typealias Server = S
    public typealias Reachability = R
    public typealias Encoder = E

    public let server: Server
    public let jsonEncoder: Encoder
    private let connectivityManager: R
    let httpTimeout: TimeInterval
    var reachabilityStatus: NetworkReachabilityStatus = .unknown

    private lazy var hostListener: NetworkReachabilityAdapter.Listener = { [weak self] status in
        self?.reachabilityStatus = status
    }

    public required init(
        server: S,
        jsonEncoder: E,
        reachability: R,
        httpTimeout: TimeInterval = 60
    ) {
        self.server = server
        self.httpTimeout = httpTimeout
        self.jsonEncoder = jsonEncoder
        connectivityManager = reachability
        guard connectivityManager.startListening(onQueue: .main, onUpdatePerforming: hostListener) else {
            print("Connectivity listening failed to start")
            return
        }
    }

    deinit {
        connectivityManager.stopListening()
    }
}
