//
//  SiteNavigationProtocols.swift
//  CottonViewModels
//
//  Created by Andrei Ermoshin on 3/20/20.
//  Copyright © 2020 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

/// Interface for the site navigation for the external consumers.
/// Should be in CottonViewModels module because it is used by the view model.
///
/// Can be sendable because it is a main actor.
@MainActor public protocol SiteExternalNavigationDelegate: AnyObject, Sendable {
    /// Provisional navigation of we kit started
    func provisionalNavigationDidStart()
    /// Web site opened for native application name
    func siteDidOpen(appName: String)
    /// Change in loading progress
    func loadingProgressDidChange(_ progress: Float)
    /// Back navigation button update
    func backNavigationDidUpdate(to canGoBack: Bool)
    /// Forward navigation button update
    func forwardNavigationDidUpdate(to canGoForward: Bool)
    /// Show loading progress
    func showLoadingProgress(_ show: Bool)
    /// SwiftUI specific callback to notify that no need to initiate a re-use of web view anymore
    func webViewDidHandleReuseAction()
    /// SwiftUI specific to notify about the same view controller when web view changes.
    /// It will pass the existing web view controller because it is reused.
    /// It is the only way to reset interface when web view is re-created.
    func webViewDidReplace(_ interface: WebViewNavigatable?)
}
