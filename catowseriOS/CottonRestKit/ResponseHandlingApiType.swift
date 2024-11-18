//
//  ResponseHandlingApiType.swift
//  HttpKit
//
//  Created by Andrei Ermoshin on 2/10/22.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

#if canImport(Combine)
import Combine
#endif
import CottonBase
import AutoMockable

public protocol RxAnyObserver {
    associatedtype Response: ResponseType
    func newSend(value: Response)
    func newSend(error: HttpError)
    func newComplete()
}

/// Reactive specific Lifetime protocol.
///
/// Can't add similar Lifetime method because it returns a Disposable which is not a type but protocol already
/// So, can't extend swift protocol like RxAnyDisposable, in other words
/// can't extend swift protocol Disposable with our RxAnyDisposable
/// As a workaround this method doesn't return Disposable
public protocol RxAnyLifetime {
    func newObserveEnded(_ action: @escaping () -> Void)
}

/// This protocol is needed to not use ReactiveSwift dependency directly
/// It should be implemented by RxObserverWrapper which is in different Framework
public protocol RxInterface: Hashable, AnyObject {
    associatedtype Observer: RxAnyObserver
    associatedtype Server: ServerDescription

    var observer: Observer { get }
    var lifetime: RxAnyLifetime { get }
    /// Not needed actually, but maybe we have to use S type somewhere
    var endpoint: Endpoint<Server> { get }
}

/// Combine Future type is only available from ios 13 https://stackoverflow.com/a/68754297
/// Can't mark specific enum case to be available for certain OS version
/// Deployment target was set to 13.0 from 12.1 from now
@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
// gryphon ignore
public enum ResponseHandlingApi<Response,
                                Server,
                                Observer: RxInterface>: Hashable
where Observer.Observer.Response == Response, Observer.Server == Server {
    case closure(ClosureWrapper<Response, Server>)
    case rxObserver(Observer)
    case waitsForRxObserver
    case combine(CombinePromiseWrapper<Response, Server>)
    case waitsForCombinePromise
    case asyncAwaitConcurrency

    public typealias ResponseApi<R, S, O> = ResponseHandlingApi<Response, Server, Observer>

    // MARK: - convenience methods

    public static func closure(_ closure: @escaping (Result<Response, HttpError>) -> Void,
                               _ endpoint: Endpoint<Server>) -> ResponseApi<Response, Server, Observer> {
        let closureWrapper: ClosureWrapper<Response, Server> = .init(closure, endpoint)
        return ResponseHandlingApi<Response, Server, Observer>.closure(closureWrapper)
    }

    public func hash(into hasher: inout Hasher) {
        /// https://github.com/kyzmitch/Cotton/issues/79
        let caseNumber: Int
        switch self {
        case .closure(let closureWrapper):
            caseNumber = 0
            hasher.combine(closureWrapper)
        case .rxObserver(let observerWrapper):
            caseNumber = 1
            hasher.combine(observerWrapper)
        case .waitsForRxObserver:
            caseNumber = 2
        case .waitsForCombinePromise:
            caseNumber = 3
        case .combine(let promiseWrapper):
            caseNumber = 4
            hasher.combine(promiseWrapper)
        case .asyncAwaitConcurrency:
            caseNumber = 5
        }
        hasher.combine(caseNumber)
    }

    public static func == (lhs: ResponseHandlingApi<Response, Server, Observer>,
                           rhs: ResponseHandlingApi<Response, Server, Observer>) -> Bool {
        /**
         Can't compare closures/functions and it is intended.

         https://stackoverflow.com/a/25694072
         equality of this sort would be extremely surprising in some generics contexts,
         where you can get reabstraction thunks that adjust the actual signature
         of a function to the one the function type expects.
         */
        switch (lhs, rhs) {
        case (.closure(let lClosure), .closure(let rClosure)):
            return lClosure == rClosure
        case (.rxObserver(let lObserver), .rxObserver(let rObserver)):
            return lObserver == rObserver
        case (.waitsForRxObserver, .waitsForRxObserver):
            return true
        case (.combine(let lPromise), .combine(let rPromise)):
            return lPromise == rPromise
        case (.waitsForCombinePromise, .waitsForCombinePromise):
            return true
        case (.asyncAwaitConcurrency, .asyncAwaitConcurrency):
            return true
        default:
            return false
        }
    }
}
