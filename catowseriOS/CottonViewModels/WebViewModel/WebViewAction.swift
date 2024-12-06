//
//  WebViewAction.swift
//  catowser
//
//  Created by Andrei Ermoshin on 8/27/22.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import Foundation
import CottonBase
import CottonPlugins

protocol Actionable {
    associatedtype Action
    associatedtype State
    func transition(on action: Action, _ logging: Bool) throws -> State
}

typealias IPAddress = String

enum WebViewAction: Sendable {
    case loadSite
    case resetToSite(Site)
    case loadNextLink(_ url: URL)
    case injectPlugins((any JSPluginsProgram)?)
    case fetchDoHStatus
    case checkDNResolvingSupport(Bool)
    case resolveDomainName(_ useDoH: Bool)
    case createRequestAnyway(IPAddress?)
    case loadWebView
    case finishLoading(URL, JavaScriptEvaluateble, _ jsEnabled: Bool)
    case startView(URLInfo)

    // middle actions

    case changeJavaScript(JavaScriptEvaluateble, Bool)
    case reload
    case goBack
    case goForward
    /// Similar to `resolveDomainName`
    case changeDoH(Bool)
}

extension WebViewAction: CustomStringConvertible {
    var description: String {
        switch self {
        case .loadSite:
            return "loadSite"
        case .resetToSite(let site):
            return "resetToSite (\(site.urlInfo.platformURL.absoluteString)"
        case .loadNextLink(let nextURL):
            #if DEBUG
            return "loadNextLink (\(nextURL.absoluteString))"
            #else
            return "loadNextLink"
            #endif
        case .reload:
            return "reload"
        case .injectPlugins:
            return "injectPlugins"
        case .fetchDoHStatus:
            return "fetchDoHStatus"
        case .checkDNResolvingSupport:
            return "checkDNResolvingSupport"
        case .resolveDomainName:
            return "resolveDomainName"
        case .createRequestAnyway:
            return "createRequestAnyway"
        case .loadWebView:
            return "loadWebView"
        case .finishLoading:
            return "finishLoading"
        case .startView:
            return "startView"
        case .changeJavaScript:
            return "changeJavaScript"
        case .goBack:
            return "goBack"
        case .goForward:
            return "goForward"
        case .changeDoH:
            return "changeDoH"
        }
    }
}
