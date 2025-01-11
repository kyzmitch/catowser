//
//  BrowserToolbarState.swift
//  catowser
//
//  Created by Andrey Ermoshin on 23.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import ViewModelKit

enum BrowserToolbarError: Error {
    case navigationUpdateWithoutData
    case progressUpdateWithoutData
}

/// Toolbar view model state
public struct BrowserToolbarState<C: BrowserToolbarStateContext>: ViewModelState {
    public typealias Context = C
    public typealias Action = BrowserToolbarAction
    public typealias BaseState = BrowserToolbarState
    
    // MARK: - States only for SwiftUI toolbar
    
    public var goBackDisabled: Bool = true
    public var goForwardDisabled: Bool = true
    public var reloadDisabled: Bool = true
    public var downloadsDisabled: Bool = true
    
    // MARK: - other states
    
    /// Tells if there is a web view content loading is in progress
    public var showProgress: Bool = false
    /// Tells that web view has handled re-use action and it is not needed anymore.
    public var stopWebViewReusage: Bool = false
    /// Max value should be 1.0 because total is equals to that by default
    public var loadingProgress: Double = 0.0
    
    // MARK: - reference type states
    
    /// Toolbar web view interface changes in scope of the state depending on current web site or lack of it
    public var webViewInterface: WebViewNavigatable?
    
    public static func createInitial() -> BrowserToolbarState {
        .init()
    }
    
    @MainActor public func transitionOn(
        _ action: Action,
        with context: Context?
    ) async throws -> Self {
        var copy = self
        switch action {
        case .goBack:
            webViewInterface?.goBack()
        case .goForward:
            webViewInterface?.goForward()
        case .reload:
            webViewInterface?.reload()
        case .updateNavigation(let canGoBack?, _):
            copy.goBackDisabled = !canGoBack
            context?.siteNavigationDelegate?.changeBackButton(to: canGoBack)
        case .updateNavigation(_, let canGoForward?):
            copy.goForwardDisabled = !canGoForward
            context?.siteNavigationDelegate?.changeForwardButton(to: canGoForward)
        case .updateNavigation(nil, nil):
            throw BrowserToolbarError.navigationUpdateWithoutData
        case let .updateProgress(_, progress?):
            copy.loadingProgress = Double(progress)
        case let .updateProgress(show?, _):
            copy.showProgress = show
        case .updateProgress(nil, nil):
            throw BrowserToolbarError.progressUpdateWithoutData
        case .replaceWebInterface(let interface):
            // This will be called every time web view changes
            // in re-usable web view controller
            // so, it will be the same reference actually
            // that is why no need to check for dublication.
            copy.update(with: interface)
        case .stopWebViewReusage:
            // web view was re-created, so that,
            // all next SwiftUI view updates can be ignored
            copy.stopWebViewReusage = true
        }
        return copy
    }
    
    /// Separate function to update several fields and trigger the update only once
    @MainActor mutating func update(with interface: WebViewNavigatable?) {
        webViewInterface = interface
        reloadDisabled = interface == nil
        goBackDisabled = !(interface?.canGoBack ?? false)
        goForwardDisabled = !(interface?.canGoForward ?? false)
    }
    
    public static func == (
        lhs: BrowserToolbarState<C>,
        rhs: BrowserToolbarState<C>
    ) -> Bool {
        let valueFieldsEqual = lhs.goBackDisabled == rhs.goBackDisabled &&
        lhs.goForwardDisabled == rhs.goForwardDisabled &&
        lhs.reloadDisabled == rhs.reloadDisabled &&
        lhs.downloadsDisabled == rhs.downloadsDisabled &&
        lhs.showProgress == rhs.showProgress &&
        lhs.stopWebViewReusage == rhs.stopWebViewReusage &&
        lhs.loadingProgress == rhs.loadingProgress
        let refFieldsEqual = lhs.webViewInterface === rhs.webViewInterface
        return valueFieldsEqual && refFieldsEqual
    }
}
