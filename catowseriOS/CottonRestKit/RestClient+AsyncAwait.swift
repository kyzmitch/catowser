//
//  RestClient+AsyncAwait.swift
//  HttpKit
//
//  Created by Andrei Ermoshin on 6/10/21.
//  Copyright © 2021 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

#if swift(>=5.5)

import Foundation
import CottonBase

extension RestClient {
    /// Makes a REST request in Concurrency Task form with specific response type, with optional authentication
    ///
    /// - Parameter endpoint: An endpoint model describing the request information for specific server
    /// - Parameter accessToken: An optional access token string needed for authorization if needed
    /// - Parameter adapter: An HTTP adapter which is needed to genearalize the async API used to receive the response.
    /// - Returns a specific decodable response type
    @available(swift 5.5)
    @available(macOS 12, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    private func makeRequest<T, B: HTTPAdapter>(
        for endpoint: Endpoint<Server>,
        withAccessToken accessToken: String?,
        transport adapter: B
    ) async throws -> T where B.Response == T, B.Server == Server {
        let requestInfo = endpoint.request(
            server: server,
            requestTimeout: Int64(httpTimeout),
            accessToken: accessToken
        )
        guard let httpRequest = requestInfo.urlRequest else {
            throw HttpError.failedKotlinRequestConstruct
        }
        guard reachabilityStatus.isReachable else {
            throw HttpError.noInternetConnectionWithHost
        }
        let codes = T.successCodes
        return try await adapter.performAsyncRequest(httpRequest, sucessCodes: codes)
    }

    /// Makes a REST request in Concurrency Task form  with specific response type
    ///
    /// - Parameter endpoint: An endpoint model describing the request information for specific server
    /// - Parameter accessToken: An optional access token string needed for authorization if needed
    /// - Parameter adapter: An HTTP adapter which is needed to genearalize the async API used to receive the response.
    /// - Returns a specific decodable response type
    @available(swift 5.5)
    @available(macOS 12, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    public func makePublicRequest<T, B: HTTPAdapter>(
        for endpoint: Endpoint<Server>,
        transport adapter: B
    ) async throws -> T where B.Response == T, B.Server == Server {
        return try await makeRequest(
            for: endpoint,
            withAccessToken: nil,
            transport: adapter
        )
    }

    /// Makes an authenticated REST request in Concurrency Task form  with specific response type
    ///
    /// - Parameter endpoint: An endpoint model describing the request information for specific server
    /// - Parameter accessToken: An optional access token string needed for authorization if needed
    /// - Parameter adapter: An HTTP adapter which is needed to genearalize the async API used to receive the response.
    /// - Returns a specific decodable response type
    @available(swift 5.5)
    @available(macOS 12, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    func makeAuthorizedRequest<T, B: HTTPAdapter>(
        for endpoint: Endpoint<Server>,
        withAccessToken accessToken: String,
        transport adapter: B
    ) async throws -> T where B.Response == T, B.Server == Server {
        return try await makeRequest(
            for: endpoint,
            withAccessToken: accessToken,
            transport: adapter
        )
    }
    
    /// Makes a REST request in Concurrency Task form without any response, with optional authentication
    ///
    /// - Parameter endpoint: An endpoint model describing the request information for specific server
    /// - Parameter accessToken: An optional access token string needed for authorization if needed
    /// - Parameter adapter: An HTTP adapter which is needed to genearalize the async API used to receive the response.
    /// - Returns Nothing
    @available(swift 5.5)
    @available(macOS 12, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    private func makeVoidRequest<T, B: HTTPAdapter>(
        for endpoint: Endpoint<Server>,
        withAccessToken accessToken: String?,
        transport adapter: B
    ) async throws where B.Response == T, B.Server == Server {
        let requestInfo = endpoint.request(
            server: server,
            requestTimeout: Int64(httpTimeout),
            accessToken: accessToken
        )
        guard let httpRequest = requestInfo.urlRequest else {
            throw HttpError.failedKotlinRequestConstruct
        }
        guard reachabilityStatus.isReachable else {
            throw HttpError.noInternetConnectionWithHost
        }
        let codes = T.successCodes
        try await adapter.performAsyncVoidRequest(httpRequest, sucessCodes: codes)
    }
}

#endif
