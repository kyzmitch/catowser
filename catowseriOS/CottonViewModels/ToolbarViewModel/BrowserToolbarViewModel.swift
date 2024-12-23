//
//  BrowserToolbarViewModel.swift
//  catowser
//
//  Created by Andrey Ermoshin on 03.01.2023.
//  Copyright © 2023 Cotton (former Catowser). All rights reserved.
//

import Combine
import CoreBrowser
import ViewModelKit

public typealias BrowserToolbarViewModelV2 = BaseViewModel<
    BrowserToolbarState<BrowserToolbarStateContextProxy>,
    BrowserToolbarAction,
    BrowserToolbarStateContextProxy
>

/// External dependency for the toolbar view model
@MainActor public protocol BrowserToolbarViewContext: AnyObject {
    var siteNavigationDelegate: SiteNavigationChangable? { get }
}

/// Browser toolbar internal view model implementation
final class BrowserToolbarViewModelImpl: BrowserToolbarViewModelV2 {
    /// View model context but from the app side, not related to the state
    private let appContext: BrowserToolbarViewContext
    
    init(
        _ appContext: BrowserToolbarViewContext
    ) {
        self.appContext = appContext
        super.init()
    }
    
    public override var context: Context? {
        BrowserToolbarStateContextProxy(subject: self)
    }
    
    public override func sendAction(_ action: Action) throws {
        state = try state.handleAction(action, with: context)
    }
}

// MARK: - BrowserToolbarStateContext

extension BrowserToolbarViewModelImpl: BrowserToolbarStateContext {
    var siteNavigationDelegate: (any SiteNavigationChangable)? {
        appContext.siteNavigationDelegate
    }
}

// MARK: - SiteExternalNavigationDelegate

extension BrowserToolbarViewModelImpl: SiteExternalNavigationDelegate {
    public func didBackNavigationUpdate(to canGoBack: Bool) {
        try? sendAction(.updateBackNavigation(canGoBack: canGoBack))
    }

    public func didForwardNavigationUpdate(to canGoForward: Bool) {
        state.goForwardDisabled = !canGoForward
        siteNavigationDelegate?.changeForwardButton(to: canGoForward)
    }

    public func provisionalNavigationDidStart() {}

    public func didSiteOpen(appName: String) {}

    public func loadingProgressdDidChange(_ progress: Float) {
        state.websiteLoadProgress = Double(progress)
    }

    public func showLoadingProgress(_ show: Bool) {
        state.showProgress = show
    }

    public func webViewDidHandleReuseAction() {
        // web view was re-created, so, all next SwiftUI view updates can be ignored
        state.stopWebViewReuseAction = ()
    }

    public func webViewDidReplace(_ interface: WebViewNavigatable?) {
        // This will be called every time web view changes
        // in re-usable web view controller
        // so, it will be the same reference actually
        // that is why no need to check for dublication.
        state.webViewInterface = interface
        state.reloadDisabled = interface == nil
        state.goBackDisabled = !(interface?.canGoBack ?? false)
        state.goForwardDisabled = !(interface?.canGoForward ?? false)
    }
}
