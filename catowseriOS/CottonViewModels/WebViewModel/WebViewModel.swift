//
//  WebViewModel.swift
//  catowser
//
//  Created by Andrei Ermoshin on 7/26/22.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import Foundation
import CottonBase
import CottonPlugins
import FeatureFlagsKit
import Combine
import WebKit

/// Web view model interface, can be sendable because it is an actor (main one)
@MainActor public protocol WebViewModel: ObservableObject, Sendable {

    // MARK: - main public methods

    func load() async
    func reset(_ site: Site) async
    func reload() async
    func goBack() async
    func goForward() async
    func finishLoading(
        _ newURL: URL,
        _ subject: JavaScriptEvaluateble
    ) async
    func decidePolicy(
        _ navigationAction: NavigationActionable,
        _ decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) async
    func decidePolicy(
        _ navigationAction: NavigationActionable
    ) async -> WKNavigationActionPolicy
    func setJavaScript(
        _ subject: JavaScriptEvaluateble,
        _ enabled: Bool
    ) async
    func setDoH(_ enabled: Bool) async
    func updateTabPreview(_ screenshot: Data?) async

    // MARK: - public properties

    var nativeAppDomainNameString: String? { get }
    var configuration: WKWebViewConfiguration { get }
    var host: CottonBase.Host { get }
    var currentURL: URL? { get }
    var settings: Site.Settings { get }
    var urlInfo: URLInfo { get }
    /// Only for SwiftUI check to avoid handling of view updates
    var isResetable: Bool { get }

    // MARK: - main state observers

    /// wrapped value for Published
    var webPageState: WebPageLoadingAction { get }
    var webPageStatePublisher: Published<WebPageLoadingAction>.Publisher { get }

    // MARK: - new properties to have single view model for Web

    /// Site navigation delegate property should allow to set it later, e.g. in case of SwiftUI mode (e.g. with ToolbarViewModel)
    var siteNavigation: SiteExternalNavigationDelegate? { get set }
}
