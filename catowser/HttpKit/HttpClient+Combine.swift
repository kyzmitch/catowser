//
//  HttpClient+Combine.swift
//  HttpKit
//
//  Created by Andrei Ermoshin on 4/28/20.
//  Copyright © 2020 andreiermoshin. All rights reserved.
//

import Foundation
import Alamofire
#if canImport(Combine)
import Combine
#endif

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Combine.Future {
    public static func failure(_ error: Failure) -> Future<Output, Failure> {
        let future: Future<Output, Failure> = .init { (promise) in
            promise(.failure(error))
        }
        return future
    }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Combine.Deferred {
    public init(_ instantePublisher: DeferredPublisher) {
        self.init { () -> DeferredPublisher in
            return instantePublisher
        }
    }
}

extension HttpKit.Client {
    @available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    typealias ResponseFuture<T> = Deferred<Future<T, HttpKit.HttpError>>
    
    @available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    private func cMakeRequest<T: ResponseType>(for endpoint: HttpKit.Endpoint<T, Server>,
                                               withAccessToken accessToken: String?,
                                               responseType: T.Type) -> ResponseFuture<T> {
        let subject: Future<T, HttpKit.HttpError> = .init { (promise) in
            guard let url = endpoint.url(relatedTo: self.server) else {
                promise(.failure(.failedConstructUrl))
                return
            }
            var httpRequest = URLRequest(url: url,
                                         cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                                         timeoutInterval: self.httpTimeout)
            httpRequest.httpMethod = endpoint.method.rawValue
            httpRequest.allHTTPHeaderFields = endpoint.headers?.dictionary
            if let token = accessToken {
                let auth: HttpKit.HttpHeader = .authorization(token: token)
                httpRequest.setValue(auth.value, forHTTPHeaderField: auth.key)
            }
            
            do {
                try httpRequest.addParameters(from: endpoint)
            } catch let error as HttpKit.HttpError {
                promise(.failure(error))
                return
            } catch {
                promise(.failure(.httpFailure(error: error, request: httpRequest)))
                return
            }
            
            let codes = T.successCodes
            
            let _: DataRequest = Alamofire.request(httpRequest)
                .validate(statusCode: codes)
                .responseDecodableObject(queue: nil, completionHandler: { (response: DataResponse<T>) in
                    switch response.result {
                    case .success(let value):
                        promise(.success(value))
                    case .failure(let error) where error is HttpKit.HttpError:
                        // swiftlint:disable:next force_cast
                        let kitError = error as! HttpKit.HttpError
                        promise(.failure(kitError))
                    case .failure(let error):
                        promise(.failure(.httpFailure(error: error, request: httpRequest)))
                    }
                })
            
            // TODO: find a way to react on subscribtion cancallation to cancel http request
        }
        
        return Combine.Deferred {
            // maybe need to move creation of subject inside
            return subject
        }
    }
    
    @available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func cMakePublicRequest<T: ResponseType>(for endpoint: HttpKit.Endpoint<T, Server>,
                                             responseType: T.Type) -> ResponseFuture<T> {
        let future = cMakeRequest(for: endpoint,
                                  withAccessToken: nil,
                                  responseType: responseType)
        return future
    }
    
    @available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func cMakeAuthorizedRequest<T: ResponseType>(for endpoint: HttpKit.Endpoint<T, Server>,
                                                 withAccessToken accessToken: String,
                                                 responseType: T.Type) -> ResponseFuture<T> {
        let future = cMakeRequest(for: endpoint,
                                    withAccessToken: accessToken,
                                    responseType: responseType)
        return future
    }
}
