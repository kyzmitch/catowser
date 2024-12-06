//
//  WebViewModelState.swift
//  catowser
//
//  Created by Andrei Ermoshin on 8/27/22.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import Foundation
import CottonBase
import CottonPlugins

/// Settings of the site can be sendable cause it is a model.
/// Can mark it as retroactive because it is from my CottonBase library.
extension CottonBase.Site.Settings: @unchecked @retroactive Sendable {}

/// URL info type can be sendable cause it is a model.
/// Can mark it as retroactive because it is from my CottonBase library.
extension CottonBase.URLInfo: @unchecked @retroactive Sendable {}

enum WebViewModelState: Sendable {
    /// SwiftUI specific state to avoid waiting for the specific `Site` and create VM right away
    /// to call `load(site)` method when SwiftUI aware of specific `Site`
    case pendingLoad
    /// Old initial state for UIKit mode as well
    case initialized(Site)
    case pendingPlugins(URLInfo, Site.Settings)
    case injectingPlugins(any JSPluginsProgram, URLInfo, Site.Settings)
    case pendingDoHStatus(URLInfo, Site.Settings)
    case checkingDNResolveSupport(URLInfo, Site.Settings)
    case resolvingDN(URLInfo, Site.Settings)
    case creatingRequest(URLInfo, Site.Settings)
    case updatingWebView(Site.Settings, URLInfo)
    case waitingForNavigation(Site.Settings, URLInfo)
    case finishingLoading(Site.Settings, URL, JavaScriptEvaluateble, _ jsEnabled: Bool, URLInfo)
    case viewing(Site.Settings, URLInfo)
    case updatingJS(Site.Settings, JavaScriptEvaluateble, URLInfo)

    enum Error: LocalizedError {
        case unexpectedStateForAction(WebViewModelState, WebViewAction)
        case notImplemented

        public var localizedDescription: String {
            switch self {
            case .unexpectedStateForAction(let state, let action):
                return "Unexpected state \(state.description) for action \(action.description)"
            case .notImplemented:
                return "Not implemented"
            }
        }
    }

    /// Returns host with domain name (ignore ip address as a host even if it is present)
    var host: CottonBase.Host {
        switch self {
        case .pendingLoad:
            assertionFailure("No host name in pendingLoad state")
            // swiftlint:disable:next force_try
            return try! CottonBase.Host(input: "")
        case .initialized(let site):
            return site.host
        case .pendingPlugins(let uRLData, _):
            return uRLData.host()
        case .injectingPlugins(_, let uRLData, _):
            return uRLData.host()
        case .pendingDoHStatus(let uRLData, _):
            return uRLData.host()
        case .checkingDNResolveSupport(let uRLData, _):
            return uRLData.host()
        case .resolvingDN(let uRLData, _):
            return uRLData.host()
        case .creatingRequest(let uRLData, _):
            return uRLData.host()
        case .updatingWebView(_, let urlData):
            // Returns host with domain name, but it is possible to return host with ip address as well
            // host from request argument can't be used, because it could contain an ip address
            return urlData.host()
        case .waitingForNavigation(_, let urlInfo):
            return urlInfo.host()
        case .finishingLoading(_, _, _, _, let urlData):
            return urlData.host()
        case .viewing(_, let uRLInfo):
            return uRLInfo.host()
        case .updatingJS(_, _, let uRLInfo):
            return uRLInfo.host()
        }
    }

    /// Returns URL with domain name, not with ip address as a host
    var platformURL: URL {
        switch self {
        case .pendingLoad:
            assertionFailure("No url in pending load state")
            // swiftlint:disable:next force_unwrapping
            return URL(string: "")!
        case .initialized(let site):
            return site.urlInfo.platformURL
        case .pendingPlugins(let uRLData, _):
            return uRLData.platformURL
        case .injectingPlugins(_, let uRLData, _):
            return uRLData.platformURL
        case .pendingDoHStatus(let uRLData, _):
            return uRLData.platformURL
        case .checkingDNResolveSupport(let uRLData, _):
            return uRLData.platformURL
        case .resolvingDN(let uRLData, _):
            return uRLData.platformURL
        case .creatingRequest(let uRLData, _):
            return uRLData.platformURL
        case .updatingWebView(_, let uRLData):
            return uRLData.platformURL
        case .waitingForNavigation(_, let uRLData):
            return uRLData.platformURL
        case .finishingLoading(_, _, _, _, let uRLData):
            return uRLData.platformURL
        case .viewing(_, let uRLInfo):
            return uRLInfo.platformURL
        case .updatingJS(_, _, let uRLData):
            return uRLData.platformURL
        }
    }

    /// Returns settings which are always present in any VM state
    var settings: Site.Settings {
        switch self {
        case .pendingLoad:
            return Site.Settings(isPrivate: false,
                                 blockPopups: false,
                                 isJSEnabled: false,
                                 canLoadPlugins: false)
        case .initialized(let site):
            return site.settings
        case .pendingPlugins(_, let settings):
            return settings
        case .injectingPlugins(_, _, let settings):
            return settings
        case .pendingDoHStatus(_, let settings):
            return settings
        case .checkingDNResolveSupport(_, let settings):
            return settings
        case .resolvingDN(_, let settings):
            return settings
        case .creatingRequest(_, let settings):
            return settings
        case .updatingWebView(let settings, _):
            return settings
        case .waitingForNavigation(let settings, _):
            return settings
        case .finishingLoading(let settings, _, _, _, _):
            return settings
        case .viewing(let settings, _):
            return settings
        case .updatingJS(let settings, _, _):
            return settings
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    func sameHost(with url: URL) -> Bool {
        switch self {
        case .pendingLoad:
            return false
        case .initialized(let site):
            return site.host.isSimilar(with: url)
        case .pendingPlugins(let uRLData, _):
            return uRLData.sameHost(with: url)
        case .injectingPlugins(_, let uRLData, _):
            return uRLData.sameHost(with: url)
        case .pendingDoHStatus(let uRLData, _):
            return uRLData.sameHost(with: url)
        case .checkingDNResolveSupport(let uRLData, _):
            return uRLData.sameHost(with: url)
        case .resolvingDN(let uRLData, _):
            return uRLData.sameHost(with: url)
        case .creatingRequest(let uRLData, _):
            return uRLData.sameHost(with: url)
        case .updatingWebView(_, let urlData):
            return urlData.host().rawString == url.host || urlData.ipAddressString == url.host
        case .waitingForNavigation(_, let urlData):
            return urlData.host().rawString == url.host || urlData.ipAddressString == url.host
        case .finishingLoading(_, _, _, _, let urlData):
            return urlData.host().rawString == url.host || urlData.ipAddressString == url.host
        case .viewing(_, let uRLInfo):
            return uRLInfo.host().rawString == url.host || uRLInfo.ipAddressString == url.host
        case .updatingJS(_, _, let uRLInfo):
            return uRLInfo.host().rawString == url.host || uRLInfo.ipAddressString == url.host
        }
    }

    var urlInfo: URLInfo {
        switch self {
        case .pendingLoad:
            assertionFailure("No url info in pending load state")
            // swiftlint:disable:next force_unwrapping
            return URLInfo(URL(string: "")!)!
        case .initialized(let site):
            return site.urlInfo
        case .pendingPlugins(let uRLData, _):
            return uRLData
        case .injectingPlugins(_, let uRLData, _):
            return uRLData
        case .pendingDoHStatus(let uRLData, _):
            return uRLData
        case .checkingDNResolveSupport(let uRLData, _):
            return uRLData
        case .resolvingDN(let uRLData, _):
            return uRLData
        case .creatingRequest(let uRLData, _):
            return uRLData
        case .updatingWebView(_, let uRLData):
            return uRLData
        case .waitingForNavigation(_, let urlInfo):
            return urlInfo
        case .finishingLoading(_, _, _, _, let urlData):
            return urlData
        case .viewing(_, let uRLInfo):
            return uRLInfo
        case .updatingJS(_, _, let uRLInfo):
            return uRLInfo
        }
    }

    var isResetable: Bool {
        switch self {
        case .viewing:
            return true
        case .waitingForNavigation:
            // Workaround for now to fix tab changes
            // because for some reason view model is in wrong state
            return true
        default:
            return false
        }
    }
}

extension WebViewModelState: CustomStringConvertible {
    var description: String {
        switch self {
        case .pendingLoad:
            return "pendingLoad"
        case .initialized(let site):
            #if DEBUG
            return "initialized (\(site.urlInfo.debugDescription))"
            #else
            return "initialized"
            #endif
        case .pendingPlugins:
            return "pendingPlugins"
        case .injectingPlugins:
            return "injectingPlugins"
        case .pendingDoHStatus:
            return "pendingDoHStatus"
        case .checkingDNResolveSupport:
            return "checkingDNResolveSupport"
        case .resolvingDN(let urlData, let settings):
            #if DEBUG
            return "resolvingDN (\(urlData.debugDescription), \(settings.description))"
            #else
            return "resolvingDN"
            #endif
        case .creatingRequest:
            return "creatingRequest"
        case .updatingWebView(_, let urlData):
            #if DEBUG
            return "updatingWebView ([\(urlData.debugDescription)])"
            #else
            return "updatingWebView"
            #endif
        case .waitingForNavigation(_, let urlInfo):
            #if DEBUG
            return "waitingForNavigation ([\(urlInfo.debugDescription)])"
            #else
            return "waitingForNavigation"
            #endif
        case .finishingLoading(_, _, _, _, let urlInfo):
            #if DEBUG
            return "finishingLoading ([\(urlInfo.debugDescription)])"
            #else
            return "finishingLoading"
            #endif
        case .viewing(_, let urlInfo):
            #if DEBUG
            return "viewing ([\(urlInfo.debugDescription)])"
            #else
            return "viewing"
            #endif
        case .updatingJS(let settings, _, let urlData):
            #if DEBUG
            return "updatingJS (settings[\(settings.description)], [\(urlData.debugDescription)]"
            #else
            return "updatingJS"
            #endif
        }
    }
}

extension WebViewModelState: Equatable {
    // swiftlint:disable:next cyclomatic_complexity
    static func == (lhs: WebViewModelState, rhs: WebViewModelState) -> Bool {
        switch (lhs, rhs) {
        case (.initialized(let lSite), .initialized(let rSite)):
            return lSite == rSite
        case (.pendingPlugins(let lData, let lSettings), .pendingPlugins(let rData, let rSettings)):
            return lData == rData && lSettings == rSettings
        case (.injectingPlugins(let lProgram, let lData, let lSettings),
              .injectingPlugins(let rProgram, let rData, let rSettings)):
            if let lp = lProgram as? JSPluginsProgramImpl, let rp = rProgram as? JSPluginsProgramImpl, lp != rp {
                return false
            }
            return lData == rData && lSettings == rSettings
        case (.updatingWebView(let lSettings, let lData),
              .updatingWebView(let rSettings, let rData)):
            return lSettings == rSettings && lData == rData
        case (.viewing(let lSettings, let lInfo),
              .viewing(let rSettings, let rInfo)):
            return lSettings == rSettings && lInfo == rInfo
        case (.waitingForNavigation(let lSettings, let lInfo),
              .waitingForNavigation(let rSettings, let rInfo)):
            return lSettings == rSettings && lInfo == rInfo
        case (.resolvingDN(let lData, let lSettings),
              .resolvingDN(let rData, let rSettings)):
            return lData == rData && lSettings == rSettings
        case (.updatingJS(let lSettings, let lSubject, let lInfo),
              .updatingJS(let rSettings, let rSubject, let rInfo)):
            return lSettings == rSettings && lInfo == rInfo && lSubject === rSubject
        case (.creatingRequest(let lInfo, let lSettings),
              .creatingRequest(let rInfo, let rSettings)):
            return lInfo == rInfo && lSettings == rSettings
        default:
            return false
        }
    }
}
