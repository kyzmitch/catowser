//
//  RestClientError.swift
//  HttpKit
//
//  Created by Andrei Ermoshin on 10/12/19.
//  Copyright © 2019 Cotton (former Catowser). All rights reserved.
//

import Foundation
import CottonBase

extension DomainName.Error: @unchecked @retroactive Sendable {}

/// Cotton Rest Kit http errors
public enum HttpError: LocalizedError, Equatable {
    // MARK: - Comon errors related to http client

    /// Reference to self is deallocated
    case zombieSelf
    /// Swift version is too low for Concurrency code
    case swiftVersionIsTooLowForAsyncAwait
    /// Auth token seems required but missing
    case noAuthenticationToken
    /// Not enough request parameters
    case failedConstructRequestParameters
    /// Not correct domain name with Cotton Base error
    case invalidDomainName(error: DomainName.Error)
    /// Not enough kotlin side request params
    case failedKotlinRequestConstruct
    /// JSON format is not expected
    case failedEncodeEncodable
    /// Host is unreachable
    case noInternetConnectionWithHost
    /// Missing HTTP response
    case noHttpResponse
    /// Not a URL response
    case notHttpUrlResponse
    /// Not correct URL
    case invalidURL
    /// Has response but without good status code
    case notGoodStatusCode(Int)
    /// Missing host info in the URL
    case noHostInUrl

    // MARK: - Errors specific to endpoints

    /// Empty query parameter
    case emptyQueryParam
    /// Space symbols in query parameter
    case spacesInQueryParam

    /// General HTTP error
    case httpFailure(error: Error)
    /// JSON serialization error
    case jsonSerialization(error: Error)
    /// JSON decoding error
    case jsonDecoding(error: Error)
    /// Some parameters are not present
    case missingRequestParameters(String)

    /// Retrieve the localized description for this error. From Error protocol.
    public var localizedDescription: String {
        switch self {
        case .httpFailure(error: let error):
            return "http failure: \(error.localizedDescription)"
        case .jsonSerialization(error: let error):
            return "json serialization: \(error.localizedDescription)"
        case .jsonDecoding(error: let error):
            return "json decoding: \(error.localizedDescription)"
        case .missingRequestParameters(let message):
            return "missing parameters: \(message)"
        case .notGoodStatusCode(let statusCode):
            return "not valid http response status code: \(statusCode)"
        case .invalidDomainName(error: let error):
            return "invalid domain name: \(error.message ?? "no message")"
        default:
            return "\(self)"
        }
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.zombieSelf, .zombieSelf),
             (.swiftVersionIsTooLowForAsyncAwait, .swiftVersionIsTooLowForAsyncAwait),
             (.noAuthenticationToken, .noAuthenticationToken),
             (.failedConstructRequestParameters, .failedConstructRequestParameters),
             (.failedKotlinRequestConstruct, .failedKotlinRequestConstruct),
             (.failedEncodeEncodable, .failedEncodeEncodable),
             (.noInternetConnectionWithHost, .noInternetConnectionWithHost),
             (.noHttpResponse, .noHttpResponse),
             (.notHttpUrlResponse, .notHttpUrlResponse),
             (.invalidURL, .invalidURL),
             (.noHostInUrl, .noHostInUrl),
             (.emptyQueryParam, .emptyQueryParam),
             (.spacesInQueryParam, .spacesInQueryParam):
            return true
        case (let .httpFailure(lhs), let .httpFailure(rhs)):
            guard type(of: lhs) == type(of: rhs) else { return false }
            let error1 = lhs as NSError
            let error2 = rhs as NSError
            return error1.domain == error2.domain && error1.code == error2.code && "\(lhs)" == "\(rhs)"
        case (let .jsonSerialization(lhs), let .jsonSerialization(rhs)):
            guard type(of: lhs) == type(of: rhs) else { return false }
            let error1 = lhs as NSError
            let error2 = rhs as NSError
            return error1.domain == error2.domain && error1.code == error2.code && "\(lhs)" == "\(rhs)"
        case (let .jsonDecoding(lhs), let .jsonDecoding(rhs)):
            guard type(of: lhs) == type(of: rhs) else { return false }
            let error1 = lhs as NSError
            let error2 = rhs as NSError
            return error1.domain == error2.domain && error1.code == error2.code && "\(lhs)" == "\(rhs)"
        case (let .missingRequestParameters(lStr), let .missingRequestParameters(rStr)):
            return lStr == rStr
        case (let .invalidDomainName(error: lhs), let .invalidDomainName(error: rhs)):
            return lhs == rhs
        default:
            return false
        }
    }
}
