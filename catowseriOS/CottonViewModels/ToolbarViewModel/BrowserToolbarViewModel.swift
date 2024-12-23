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
        try? sendAction(.updateNavigation(
            canGoBack: canGoBack,
            canGoForward: nil
        ))
    }

    public func didForwardNavigationUpdate(to canGoForward: Bool) {
        try? sendAction(.updateNavigation(
            canGoBack: nil,
            canGoForward: canGoForward
        ))
    }

    public func provisionalNavigationDidStart() {}

    public func didSiteOpen(appName: String) {}

    public func loadingProgressdDidChange(_ progress: Float) {
        try? sendAction(.updateProgress(show: nil, value: progress))
    }

    public func showLoadingProgress(_ show: Bool) {
        try? sendAction(.updateProgress(show: show, value: nil))
    }

    public func webViewDidHandleReuseAction() {
        try? sendAction(.stopWebViewReusage)
    }

    public func webViewDidReplace(_ interface: WebViewNavigatable?) {
        try? sendAction(.replaceWebInterface(interface))
    }
}
