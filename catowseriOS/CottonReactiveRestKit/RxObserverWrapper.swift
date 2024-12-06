//
//  RxObserverWrapper.swift
//  ReactiveHttpKit
//
//  Created by Andrei Ermoshin on 2/12/22.
//  Copyright © 2022 Cotton (former Catowser). All rights reserved.
//

import CottonRestKit
@preconcurrency import ReactiveSwift
import CottonBase

extension Signal.Observer: @retroactive RxAnyObserver where Value: ResponseType, Error == HttpError {
    public typealias Response = Value

    public func newSend(value: Response) {
        send(value: value)
    }
    public func newSend(error: HttpError) {
        send(error: error)
    }

    public func newComplete() {
        sendCompleted()
    }
}

extension Signal.Observer: @retroactive RxAnyVoidObserver where Value == Void, Error == HttpError {
    public func newSend(value: Value) {
        send(value: value)
    }
    public func newSend(error: HttpError) {
        send(error: error)
    }

    public func newComplete() {
        sendCompleted()
    }
}

extension Lifetime: @retroactive RxAnyLifetime {
    public func newObserveEnded(_ action: @escaping () -> Void) {
        observeEnded(action)
    }
}

public class RxObserverWrapper<RR,
                               SS: ServerDescription,
                               RX: RxAnyObserver>: RxInterface where RX.Response == RR {
    public typealias Server = SS
    public typealias Observer = RX

    public var observer: RX {
        // swiftlint:disable:next force_cast
        return rxObserver as! RX
    }

    public var lifetime: RxAnyLifetime {
        return rxLifetime
    }

    let rxObserver: Signal<RR, HttpError>.Observer
    let rxLifetime: Lifetime
    /// Don't need to use endpoint here, but it is needed to create unique hash value for the closure
    public let endpoint: Endpoint<Server>
    let responseType: RR.Type

    public init(_ observer: Signal<RR, HttpError>.Observer,
                _ lifetime: Lifetime,
                _ endpoint: Endpoint<Server>) {
        self.rxObserver = observer
        self.rxLifetime = lifetime
        self.endpoint = endpoint
        responseType = RR.self
    }

    public func hash(into hasher: inout Hasher) {
        let typeString = String(describing: responseType)
        hasher.combine(typeString)
        hasher.combine("rx.observer")
        hasher.combine(responseType.successCodes)
        hasher.combine(endpoint)
    }

    public static func == (lhs: RxObserverWrapper<RR, Server, Observer>,
                           rhs: RxObserverWrapper<RR, Server, Observer>) -> Bool {
        return lhs.responseType == rhs.responseType && lhs.endpoint == rhs.endpoint
    }
}

public class RxObserverVoidWrapper<SS: ServerDescription>: RxVoidInterface {
    public typealias S = SS

    public var observer: RxAnyVoidObserver {
        return rxObserver
    }

    public var lifetime: RxAnyLifetime {
        return rxLifetime
    }

    let rxObserver: Signal<Void, HttpError>.Observer
    let rxLifetime: Lifetime
    /// Don't need to use endpoint here, but it is needed to create unique hash value for the closure
    public let endpoint: Endpoint<S>

    public init(_ observer: Signal<Void, HttpError>.Observer,
                _ lifetime: Lifetime,
                _ endpoint: Endpoint<S>) {
        self.rxObserver = observer
        self.rxLifetime = lifetime
        self.endpoint = endpoint
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine("rx.observer")
        hasher.combine(endpoint)
    }

    public static func == (lhs: RxObserverVoidWrapper<S>, rhs: RxObserverVoidWrapper<S>) -> Bool {
        return lhs.endpoint == rhs.endpoint
    }
}
