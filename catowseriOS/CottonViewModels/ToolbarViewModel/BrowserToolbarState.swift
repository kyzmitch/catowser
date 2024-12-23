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
    
    // MARK: - States only for SwiftUI toolbar
    
    public var goBackDisabled: Bool = true
    public var goForwardDisabled: Bool = true
    public var reloadDisabled: Bool = true
    public var downloadsDisabled: Bool = true
    
    // MARK: - other states
    
    /// Tells if there is a web view content loading is in progress
    public var showProgress: Bool = false
    /// Tells that web view has handled re-use action and it is not needed anymore.
    public var stopWebViewReuseAction: Void = ()
    /// Max value should be 1.0 because total is equals to that by default
    public var websiteLoadProgress: Double = 0.0
    
    // MARK: - reference type states
    
    /// Toolbar web view interface changes in scope of the state depending on current web site or lack of it
    public var webViewInterface: WebViewNavigatable?
    
    public static func createInitial() -> BrowserToolbarState {
        .init()
    }
    
    @MainActor public func handleAction(
        _ action: Action,
        with context: Context?
    ) throws -> Self {
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
            copy.websiteLoadProgress = Double(progress)
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
}
