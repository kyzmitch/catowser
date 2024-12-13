//
//  HTTPVoidAdapter.swift
//  HttpKit
//
//  Created by Andrei Ermoshin on 2/10/22.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

#if canImport(Combine)
import Combine
#endif
import CottonBase

/// HTTP reactive adapter which returns nothing (Void)
public protocol HTTPRxVoidAdapter: AnyObject {
    associatedtype Server
    associatedtype Observer: RxVoidInterface where Observer.Server == Server

    var handlerType: ResponseVoidHandlingApi<Server, Observer> { get set }

    init(_ handlerType: ResponseVoidHandlingApi<Server, Observer>)
    func performVoidRequest(
        _ request: URLRequest,
        sucessCodes: [Int]
    )

    /// This is not defined in ResponseHandlingApi because it is a value type and this function should capture self
    /// So, better to store it here in reference type
    func wrapperHandler() -> (Result<Void, HttpError>) -> Void

    /* mutating */ func transferToCombineState(
        _ promise: @escaping Future<Void, HttpError>.Promise,
        _ endpoint: Endpoint<Server>
    )
}
