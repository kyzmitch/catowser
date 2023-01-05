//
//  WebViewModel.swift
//  catowser
//
//  Created by Andrei Ermoshin on 7/26/22.
//  Copyright © 2022 andreiermoshin. All rights reserved.
//

import Foundation
import CoreHttpKit
import JSPlugins
import FeaturesFlagsKit
import ReactiveSwift
import Combine
import WebKit

/// Simplified view actions for view use
public enum WebPageLoadingAction: Equatable {
    case recreateView(Bool)
    case load(URLRequest)
    case reattachViewObservers
    case openApp(URL)
}

/// Interface for system's type `WKNavigationAction` from WebKit framework to be able to mock it
public protocol NavigationActionable: AnyObject {
    var navigationType: WKNavigationType { get }
    var request: URLRequest { get }
}

public protocol WebViewModel: AnyObject {
    // MARK: - main public methods
    
    func load()
    @discardableResult
    func load(_ site: Site) -> Bool
    func reload()
    func goBack()
    func goForward()
    func finishLoading(_ newURL: URL, _ subject: JavaScriptEvaluateble)
    func decidePolicy(_ navigationAction: NavigationActionable,
                      _ decisionHandler: @escaping (WKNavigationActionPolicy) -> Void)
    func setJavaScript(_ subject: JavaScriptEvaluateble, _ enabled: Bool)
    func setDoH(_ enabled: Bool)
    
    // MARK: - public properties
    
    var nativeAppDomainNameString: String? { get }
    var configuration: WKWebViewConfiguration { get }
    var host: CoreHttpKit.Host { get }
    var currentURL: URL? { get }
    var settings: Site.Settings { get }
    var urlInfo: URLInfo { get }
    /// Only for SwiftUI check to avoid handling of view updates
    var isResetable: Bool { get }
    
    // MARK: - main state observers
    
    var rxWebPageState: MutableProperty<WebPageLoadingAction> { get }
    var combineWebPageState: CurrentValueSubject<WebPageLoadingAction, Never> { get }
    /// wrapped value for Published
    var webPageState: WebPageLoadingAction { get }
    var webPageStatePublisher: Published<WebPageLoadingAction>.Publisher { get }
}
