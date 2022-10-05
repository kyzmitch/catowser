//
//  RestClientContext.swift
//  catowser
//
//  Created by Andrei Ermoshin on 6/21/22.
//  Copyright © 2022 andreiermoshin. All rights reserved.
//

import Foundation
import HttpKit
import ReactiveSwift
import Combine
import CoreHttpKit
import ReactiveHttpKit
import BrowserNetworking

public protocol RestClientContext: AnyObject {
    associatedtype Response: ResponseType
    associatedtype Server: ServerDescription
    associatedtype ReachabilityAdapter: NetworkReachabilityAdapter where ReachabilityAdapter.Server == Server
    
    typealias Observer = Signal<Response, HttpKit.HttpError>.Observer
    typealias ObserverWrapper = HttpKit.RxObserverWrapper<Response, Server, Observer>
    typealias HttpKitRxSubscriber = HttpKit.RxSubscriber<Response, Server, ObserverWrapper>
    typealias HttpKitSubscriber = HttpKit.Subscriber<Response, Server>
    typealias Client = HttpKit.Client<Server, ReachabilityAdapter>
    
    var client: Client { get }
    var rxSubscriber: HttpKitRxSubscriber { get }
    var subscriber: HttpKitSubscriber { get }
    
    init(_ client: Client,
         _ rxSubscriber: HttpKitRxSubscriber,
         _ subscriber: HttpKitSubscriber)
}
