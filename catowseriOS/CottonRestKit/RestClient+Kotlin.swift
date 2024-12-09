//
//  RestClient+Kotlin.swift
//  HttpKit
//
//  Created by Andrei Ermoshin on 4/16/22.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import CottonBase

extension RestClient {
    /// Makes a REST request with specific type of response
    ///
    /// - Parameter endpoint: An endpoint model describing the request information for specific server
    /// - Parameter accessToken: An optional access token string needed for authorization if needed
    /// - Parameter adapter: An HTTP adapter which is needed to genearalize the async API used to receive the response.
    public func makeRequest<T, B: HTTPAdapter>(
        for endpoint: Endpoint<Server>,
        withAccessToken accessToken: String?,
        transport adapter: B
    ) where B.Response == T, B.Server == Server {
        let requestInfo = endpoint.request(
            server: server,
            requestTimeout: Int64(httpTimeout),
            accessToken: accessToken
        )
        guard let httpRequest = requestInfo.urlRequest else {
            let result: HttpTypedResult<T> = .failure(.failedKotlinRequestConstruct)
            adapter.wrapperHandler()(result)
            return
        }
        let codes = T.successCodes
        adapter.performRequest(httpRequest, sucessCodes: codes)
    }

    // MARK: - Clear RX capable functions without dependencies

    /// Makes a Reactive request with specific type of response
    ///
    /// - Parameter endpoint: An endpoint model describing the request information for specific server
    /// - Parameter accessToken: An optional access token string needed for authorization if needed
    /// - Parameter adapter: An HTTP adapter which is needed to genearalize the async API used to receive the response.
    public func makeRxRequest<T, B: HTTPRxAdapter>(
        for endpoint: Endpoint<Server>,
        withAccessToken accessToken: String?,
        transport adapter: B
    ) where B.Response == T, B.Server == Server {
        let requestInfo = endpoint.request(
            server: server,
            requestTimeout: Int64(httpTimeout),
            accessToken: accessToken
        )
        guard let httpRequest = requestInfo.urlRequest else {
            let result: HttpTypedResult<T> = .failure(.failedKotlinRequestConstruct)
            adapter.wrapperHandler()(result)
            return
        }
        let codes = T.successCodes
        adapter.performRequest(httpRequest, sucessCodes: codes)
    }

    /// Makes a Reactive request, but without any response type
    ///
    /// - Parameter endpoint: An endpoint model describing the request information for specific server
    /// - Parameter accessToken: An optional access token string needed for authorization if needed
    /// - Parameter adapter: An HTTP adapter which is needed to genearalize the async API used to receive the response.
    public func makeRxVoidRequest<B: HTTPRxVoidAdapter>(
        for endpoint: Endpoint<Server>,
        withAccessToken accessToken: String?,
        transport adapter: B
    ) where B.Server == Server {
        let requestInfo = endpoint.request(
            server: server,
            requestTimeout: Int64(httpTimeout),
            accessToken: accessToken
        )
        guard let httpRequest = requestInfo.urlRequest else {
            let result: Result<Void, HttpError> = .failure(.failedKotlinRequestConstruct)
            adapter.wrapperHandler()(result)
            return
        }
        let codes = VoidResponse.successCodes
        adapter.performVoidRequest(httpRequest, sucessCodes: codes)
    }
}
