//
//  AlamofireHTTPRxVoidAdaptee.swift
//  BrowserNetworking
//
//  Created by Andrei Ermoshin on 2/10/22.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import CottonRestKit
import Alamofire
@preconcurrency import ReactiveSwift
#if canImport(Combine)
import Combine
#endif
import CottonBase

final class AlamofireHTTPRxVoidAdaptee<
    S,
    RX: RxVoidInterface
>: HTTPRxVoidAdapter where RX.Server == S {
    typealias Server = S
    typealias ObserverWrapper = RX

    var handlerType: ResponseVoidHandlingApi<Server, ObserverWrapper>

    init(_ handlerType: ResponseVoidHandlingApi<Server, ObserverWrapper>) {
        self.handlerType = handlerType
    }

    func wrapperHandler() -> (Result<Void, HttpError>) -> Void {
        let closure = { [weak self] (result: Result<Void, HttpError>) in
            guard let self = self else {
                return
            }
            switch self.handlerType {
            case .closure(let originalClosure):
                originalClosure.closure(result)
            case .rxObserver(let observerWrapper):
                switch result {
                case .success:
                    let value: Void = ()
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

    func performVoidRequest(
        _ request: URLRequest,
        sucessCodes: [Int]
    ) {
        let dataRequest: DataRequest = AF.request(request)
        dataRequest
            .validate(statusCode: sucessCodes)
            .response { [weak self] (defaultResponse) in
                let result: Result<Void, HttpError>
                if let error = defaultResponse.error {
                    let localError = HttpError.httpFailure(error: error)
                    result = .failure(localError)
                } else {
                    let value: Void = ()
                    result = .success(value)
                }
                self?.wrapperHandler()(result)
            }
        if case let .rxObserver(observerWrapper) = handlerType {
            observerWrapper.lifetime.newObserveEnded({
                dataRequest.cancel()
            })
        } else if case let .combine(publisherWrapper) = handlerType {
            // publisherWrapper.
            #warning("Cancel request https://github.com/kyzmitch/Cotton/issues/14")
        }
    }

    func transferToCombineState(
        _ promise: @escaping Future<Void, HttpError>.Promise,
        _ endpoint: Endpoint<Server>
    ) {
        if case .waitsForCombinePromise = handlerType {
            let promiseWrapper: CombinePromiseVoidWrapper<Server> = .init(promise, endpoint)
            handlerType = .combine(promiseWrapper)
        }
    }
}
