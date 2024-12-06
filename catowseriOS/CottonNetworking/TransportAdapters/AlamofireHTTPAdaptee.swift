//
//  AlamofireHTTPAdaptee.swift
//  BrowserNetworking
//
//  Created by Andrey Ermoshin on 18.02.2022.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import CottonRestKit
import CottonReactiveRestKit
import Alamofire
@preconcurrency import ReactiveSwift
#if canImport(Combine)
import Combine
#endif
import CottonBase

final class AlamofireHTTPAdaptee<R: ResponseType, S: ServerDescription>: HTTPAdapter {
    typealias Response = R
    typealias Server = S

    var handlerType: ResponseHandlingApi<Response, Server, RxFreeDummy<Response, Server>>

    init(_ handlerType: ResponseHandlingApi<Response, Server, RxFreeDummy<Response, Server>>) {
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
            case .rxObserver, .waitsForRxObserver:
                assertionFailure("Calling RX interface in RX free wrapper")
            case .waitsForCombinePromise:
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

    func performRequest(_ request: URLRequest, sucessCodes: [Int]) {
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
                                    print("Http request failed: \(error.localizedDescription)")
                                    result = .failure(.httpFailure(error: error))
                                }
                                guard let self = self else {
                                    print("Networking backend was deallocated")
                                    return
                                }
                                self.wrapperHandler()(result)
                               })
        if case .combine = handlerType {
            // https://github.com/kyzmitch/Cotton/issues/14
        }
    }

    func transferToCombineState(_ promise: @escaping Future<Response, HttpError>.Promise,
                                _ endpoint: Endpoint<Server>) {
        if case .waitsForCombinePromise = handlerType {
            let promiseWrapper: CombinePromiseWrapper<Response, Server> = .init(promise, endpoint)
            handlerType = .combine(promiseWrapper)
        }
    }

    func performAsyncRequest(_ request: URLRequest,
                             sucessCodes: [Int]) async throws -> Response {
        do {
            let value = try await AF.request(request)
                .validate(statusCode: sucessCodes)
                .serializingDecodable(Response.self)
                .value
            return value
        } catch {
            throw HttpError.httpFailure(error: error)
        }

    }
}
