//
//  ClosureWrappers.swift
//  HttpKit
//
//  Created by Andrei Ermoshin on 2/10/22.
//  Copyright © 2022 Cotton (former Catowser). All rights reserved.
//

#if canImport(Combine)
import Combine
#endif
import CottonBase

// gryphon ignore
public class ClosureWrapper<Response: ResponseType, Server: ServerDescription>: Hashable {
    /// Should be let constant, but var is needed to get ab address of it which should be added to a hash value
    public var closure: (Result<Response, HttpError>) -> Void
    /// Don't need to use endpoint here, but it is needed to create unique hash value for the closure
    let endpoint: Endpoint<Server>
    let responseType: Response.Type

    public init(_ closure: @escaping (Result<Response, HttpError>) -> Void,
                _ endpoint: Endpoint<Server>) {
        self.closure = closure
        self.endpoint = endpoint
        responseType = Response.self
    }

    public func hash(into hasher: inout Hasher) {
        let typeString = String(describing: responseType)
        hasher.combine(typeString)
        hasher.combine("closure")
        hasher.combine(responseType.successCodes)
        hasher.combine(endpoint)
        withUnsafePointer(to: &closure) {
            let strAddrs = "\($0)"
            hasher.combine(strAddrs)
        }
    }

    public static func == (lhs: ClosureWrapper<Response, Server>, rhs: ClosureWrapper<Response, Server>) -> Bool {
        return lhs.responseType == rhs.responseType && lhs.endpoint == rhs.endpoint
    }
}

// gryphon ignore
public class CombinePromiseWrapper<Response: ResponseType, Server: ServerDescription>: Hashable {
    /// Should be let constant, but var is needed to get ab address of it which should be added to a hash value
    public var promise: Future<Response, HttpError>.Promise
    /// Don't need to use endpoint here, but it is needed to create unique hash value for the closure
    let endpoint: Endpoint<Server>
    let responseType: Response.Type

    public init(_ promise: @escaping Future<Response, HttpError>.Promise,
                _ endpoint: Endpoint<Server>) {
        self.promise = promise
        self.endpoint = endpoint
        responseType = Response.self
    }

    public func hash(into hasher: inout Hasher) {
        let typeString = String(describing: responseType)
        hasher.combine(typeString)
        hasher.combine("combine.promise")
        hasher.combine(responseType.successCodes)
        hasher.combine(endpoint)
        withUnsafePointer(to: &promise) {
            let strAddrs = "\($0)"
            hasher.combine(strAddrs)
        }
    }

    public static func == (
        lhs: CombinePromiseWrapper<Response, Server>,
        rhs: CombinePromiseWrapper<Response, Server>
    ) -> Bool {
        return lhs.responseType == rhs.responseType && lhs.endpoint == rhs.endpoint
    }
}
