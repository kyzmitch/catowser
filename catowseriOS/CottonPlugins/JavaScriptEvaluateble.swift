//
//  JavaScriptEvaluateble.swift
//  JSPlugins
//
//  Created by Andrei Ermoshin on 5/30/22.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import Foundation
import Combine
@preconcurrency import ReactiveSwift

/// Протокол для вэб вью по выполнения JavaScript, должно быть на main thread
@MainActor
public protocol JavaScriptEvaluateble: AnyObject, Sendable {
    func evaluateJavaScriptV2(
        _ javaScriptString: String,
        completionHandler: (@MainActor @Sendable (Any?, (any Error)?) -> Void)?
    )
    func evaluateJavaScriptV1(
        _ javaScriptString: String,
        completionHandler: ((Any?, Error?) -> Void)?
    )
}

extension JavaScriptEvaluateble {
    func commonHandleJavaScript(
        _ javaScriptString: String,
        _ completionHandler: (@Sendable (Any?, (any Error)?) -> Void)?
    ) {
        if #available(iOS 18.0, *) {
            evaluateJavaScriptV2(javaScriptString, completionHandler: completionHandler)
        } else {
            #if swift(<6.0)
            evaluateJavaScriptV1(javaScriptString, completionHandler: completionHandler)
            #endif
        }
    }
}

extension JavaScriptEvaluateble {
    func evaluate(jsScript: String) {
        // https://github.com/WebKit/WebKit/blob/main/Source/WebKit/UIProcess/API/Cocoa/WKWebView.mm
        commonHandleJavaScript(jsScript, {(something, error) in
            if let err = error {
                print("Error evaluating JavaScript: \(err)")
            } else if let thing = something {
                print("Received value after evaluating: \(thing)")
            }
        })
    }

    @available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func evaluatePublisher(jsScript: String) -> AnyPublisher<String, Error> {
        let future = Future<String, Error> { @MainActor @Sendable [weak self] promise in
            guard let self = self else {
                promise(.failure(CottonPluginError.zombiError))
                return
            }
#if swift(>=6)
            // workaround until Apple Combine fixes the future/promise by adding Sendable conformance
            nonisolated(unsafe) let promise = promise
#endif
            commonHandleJavaScript(jsScript) { @Sendable (something, error) in
                if let error {
                    promise(.failure(error))
                    return
                }
                guard let anyResult = something, let stringResult = anyResult as? String else {
                    promise(.failure(CottonPluginError.nilJSEvaluationResult))
                    return
                }
                promise(.success(stringResult))
            }
        }
        // Internally it is a WebView, so that, scheduler should be a Main thread
        return Deferred {
            future
                .subscribe(on: RunLoop.main)
        }.eraseToAnyPublisher()
    }

    func rxEvaluate(jsScript: String) -> SignalProducer<Any, Error> {
        let producer: SignalProducer<Any, Error> = .init { [weak self] (observer, _) in
            guard let self = self else {
                observer.send(error: CottonPluginError.zombiError)
                return
            }
            self.commonHandleJavaScript(jsScript) { (something, error) in
                if let realError = error {
                    observer.send(error: realError)
                    return
                }
                guard let anyResult = something else {
                    observer.send(error: CottonPluginError.nilJSEvaluationResult)
                    return
                }
                observer.send(value: anyResult)
                observer.sendCompleted()
            }
        }
        return producer
    }

    @available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func titlePublisher() -> AnyPublisher<String, Error> {
        typealias StringResult = Result<String, Error>
        return evaluatePublisher(jsScript: "document.title").flatMap { (documentTitle) -> StringResult.Publisher in
            return StringResult.Publisher(.success(documentTitle))
        }.eraseToAnyPublisher()
    }

    @available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func finalURLPublisher() -> AnyPublisher<URL, Error> {
        typealias URLResult = Result<URL, Error>
        // If we have JavaScript blocked, these will be empty.
        return evaluatePublisher(jsScript: .locationHREF).flatMap { (urlString) -> URLResult.Publisher in
            guard let url = URL(string: urlString) else {
                return URLResult.Publisher(.failure(CottonPluginError.jsEvaluationIsNotURL))
            }
            return URLResult.Publisher(.success(url))
        }.eraseToAnyPublisher()
    }

    public func rxFinalURL() -> SignalProducer<URL, Error> {
        return rxEvaluate(jsScript: .locationHREF)
            .flatMap(.latest) { (anyResult) -> SignalProducer<URL, Error> in
                guard let urlString = anyResult as? String else {
                    return .init(error: CottonPluginError.jsEvaluationIsNotString)
                }
                guard let url = URL(string: urlString) else {
                    return .init(error: CottonPluginError.jsEvaluationIsNotURL)
                }
                return .init(value: url)
            }
    }
}

fileprivate extension String {
    static let locationHREF: String = "window.location.href"
}
