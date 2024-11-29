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
    @available(swift 5.5)
    @available(macOS 12, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    private func aaMakeRequest<T, B: HTTPAdapter>(
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

    @available(swift 5.5)
    @available(macOS 12, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    public func aaMakePublicRequest<T, B: HTTPAdapter>(
        for endpoint: Endpoint<Server>,
        transport adapter: B
    ) async throws -> T where B.Response == T, B.Server == Server {
        return try await aaMakeRequest(
            for: endpoint,
            withAccessToken: nil,
            transport: adapter
        )
    }

    @available(swift 5.5)
    @available(macOS 12, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    func aaMakeAuthorizedRequest<T, B: HTTPAdapter>(
        for endpoint: Endpoint<Server>,
        withAccessToken accessToken: String,
        transport adapter: B
    ) async throws -> T where B.Response == T, B.Server == Server {
        return try await aaMakeRequest(
            for: endpoint,
            withAccessToken: accessToken,
            transport: adapter
        )
    }
}

#endif
