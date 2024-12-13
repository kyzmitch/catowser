//
//  HTTPRxAdapter.swift
//  CottonRestKit
//
//  Created by Andrei Ermoshin on 2/8/22.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

#if canImport(Combine)
import Combine
#endif
import CottonBase

/// An interface for some HTTP networking library (e.g. Alamofire or URLSession) to hide it and
/// not use it directly and be able to mock it for unit testing.
///
/// Also, it allows to use completely different callback APIs (closure, Reactive observers, Combine promises, etc.
///
/// It seems it should be only implemented by classes (see AnyObject requirement),
/// because network library API probably uses closures and should be able to access `self`
/// and should  avoid copying closures, original closure should be used.
///
/// This is an adapter pattern for the high level HTTP requests transport.
/// This one is Reactive dependend interface.
public protocol HTTPRxAdapter: AnyObject {
    associatedtype Response
    associatedtype Server
    associatedtype ObserverWrapper: RxInterface where ObserverWrapper.Observer.Response == Response,
                                                      ObserverWrapper.Server == Server
    init(_ handlerType: ResponseHandlingApi<Response, Server, ObserverWrapper>)

    /// Starts the request, the async method is determined later internally in the implementation
    func performRequest(
        _ request: URLRequest,
        sucessCodes: [Int]
    )
    /// Should be the main closure which should call basic closure and Rx stuff (observer, lifetime) and Async stuff
    /// This is not defined in ResponseHandlingApi because it is a value type and this function should capture self
    /// So, better to store it here in reference type
    func wrapperHandler() -> (Result<Response, HttpError>) -> Void
    /// Should refer to simple closure api
    var handlerType: ResponseHandlingApi<Response, Server, ObserverWrapper> { get set }

    /// Transfer the request to be Apple.Combine compatible when this information became clear
    /* mutating */ func transferToCombineState(
        _ promise: @escaping Future<Response, HttpError>.Promise,
        _ endpoint: Endpoint<Server>
    )
}

/// HTTP adapter for the async APIs without Reactive lib dependency.
public protocol HTTPAdapter: AnyObject {
    associatedtype Response: ResponseType
    associatedtype Server: ServerDescription

    typealias RxFreeDummy<R: ResponseType, S: ServerDescription> = RxFreeInterface<R, S>

    init(_ handlerType: ResponseHandlingApi<Response, Server, RxFreeDummy<Response, Server>>)

    /// Starts the request,  the async method is determined later internally in the implementation
    func performRequest(
        _ request: URLRequest,
        sucessCodes: [Int]
    )
    /// Starts the request and creates Concurrency task
    func performAsyncRequest(
        _ request: URLRequest,
        sucessCodes: [Int]
    ) async throws -> Response
    /// Starts the request which should return nothing
    func performAsyncVoidRequest(
        _ request: URLRequest,
        sucessCodes: [Int]
    ) async throws
    /// Should be the main closure which should call basic closure and Rx stuff (observer, lifetime) and Async stuff
    /// This is not defined in ResponseHandlingApi because it is a value type and this function should capture self
    /// So, better to store it here in reference type
    func wrapperHandler() -> (Result<Response, HttpError>) -> Void
    /// Should refer to simple closure api
    var handlerType: ResponseHandlingApi<Response, Server, RxFreeDummy<Response, Server>> { get set }

    /// Transfer the request to be Apple.Combine compatible when this information became clear
    /* mutating */ func transferToCombineState(
        _ promise: @escaping Future<Response, HttpError>.Promise,
        _ endpoint: Endpoint<Server>
    )
}
