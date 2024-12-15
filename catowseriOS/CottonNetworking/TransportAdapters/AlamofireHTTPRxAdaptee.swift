//
//  AlamofireHTTPRxAdaptee.swift
//  BrowserNetworking
//
//  Created by Andrei Ermoshin on 11/29/21.
//  Copyright © 2021 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import AutoMockable
import CottonRestKit
import CottonReactiveRestKit
import Alamofire
@preconcurrency import ReactiveSwift
#if canImport(Combine)
import Combine
#endif
import CottonBase

final class AlamofireHTTPRxAdaptee<
    R,
    S,
    RX: RxInterface
>: HTTPRxAdapter where
    RX.Observer.Response == R, RX.Server == S {
    typealias Response = R
    typealias Server = S
    typealias ObserverWrapper = RX

    var handlerType: ResponseHandlingApi<Response, Server, ObserverWrapper>

    init(_ handlerType: ResponseHandlingApi<Response, Server, ObserverWrapper>) {
        self.handlerType = handlerType
    }

    func wrapperHandler() -> (Result<Response, HttpError>) -> Void {
        let closure = { [weak self] (result: Result<Response, HttpError>) in
            guard let self = self else {
                return
            }
            switch self.handlerType {
            case .closure(let originalClosure):
                originalClosure.closure(result)
            case .rxObserver(let observerWrapper):
                switch result {
                case .success(let value):
                    observerWrapper.observer.newSend(value: value)
                    observerWrapper.observer.newComplete()
                case .failure(let error):
                    observerWrapper.observer.newSend(error: error)
                }
            case .waitsForRxObserver, .waitsForCombinePromise:
                break
            case .combine(let promiseWrapper):
                promiseWrapper.promise(result)
            case .asyncAwaitConcurrency:
                break
            @unknown default:
                break
            }
        }
        return closure
    }

    func performRequest(
        _ request: URLRequest,
        sucessCodes: [Int]
    ) {
        let dataRequest: DataRequest = AF.request(request)
        dataRequest
            .validate(statusCode: sucessCodes)
            .responseDecodable(of: Response.self,
                               queue: .main,
                               decoder: JSONDecoder(),
                               completionHandler: { [weak self] (response) in
                                let result: Result<Response, HttpError>
                                switch response.result {
                                case .success(let value):
                                    result = .success(value)
                                case .failure(let error):
                                    result = .failure(.httpFailure(error: error))
                                }
                                guard let self = self else {
                                    print("Networking backend was deallocated")
                                    return
                                }
                                self.wrapperHandler()(result)
                               })
        if case let .rxObserver(observerWrapper) = handlerType {
            observerWrapper.lifetime.newObserveEnded({
                dataRequest.cancel()
            })
        } else if case let .combine(publisherWrapper) = handlerType {
            // publisherWrapper.
        }
    }

    func transferToCombineState(
        _ promise: @escaping Future<Response, HttpError>.Promise,
        _ endpoint: Endpoint<Server>
    ) {
        if case .waitsForCombinePromise = handlerType {
            let promiseWrapper: CombinePromiseWrapper<Response, Server> = .init(promise, endpoint)
            handlerType = .combine(promiseWrapper)
        }
    }
}

/// Wrapper around Alamofire method.
/// URLRequest is already implements same protocol in `CottonRestKit`
/// and here it needs to overwrite that confirmance.
extension URLRequest /* : URLRequestCreatable */ {
    public func convertToURLRequest() throws -> URLRequest {
        return try asURLRequest()
    }
}

/// Wrapper around Alamofire method.
/// Can't be retroactive because it is from 3rd party Alamofire lib.
extension JSONEncoding: @unchecked Sendable {}
/// Can be retroactivly Auto mockable because it is our own protocol which can't be known by Alamofire devs.
extension JSONEncoding: @retroactive AutoMockable {}
/// Can be retroactivly conforming to JSONRequestEncodable because Alamofire devs won't know that protocol for sure.
extension JSONEncoding: @retroactive JSONRequestEncodable {
    public func encodeRequest(
        _ urlRequest: URLRequestCreatable,
        with parameters: [String: Any]?
    ) throws -> URLRequest {
        return try encode(urlRequest.convertToURLRequest(), with: parameters)
    }
}
