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

/// Browser toolbar base view model
public typealias BrowserToolbarViewModel = BaseViewModel<
    BrowserToolbarState<BrowserToolbarStateContextProxy>,
    BrowserToolbarAction,
    BrowserToolbarStateContextProxy
>

/// Browser toolbar internal view model implementation
final class BrowserToolbarViewModelImpl: BrowserToolbarViewModel {
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
    
    public override func sendAction(_ action: Action) async throws {
        try await super.sendAction(action)
        state.stopWebViewReusage = false
    }
}

// MARK: - BrowserToolbarStateContext

extension BrowserToolbarViewModelImpl: BrowserToolbarStateContext {
    var siteNavigationDelegate: (any SiteNavigationChangable)? {
        appContext.siteNavigationDelegate
    }
    
    var siteExternalDelegate: SiteExternalNavigationDelegate? {
        self
    }
}

// MARK: - SiteExternalNavigationDelegate

extension BrowserToolbarViewModelImpl: SiteExternalNavigationDelegate {
    public func backNavigationDidUpdate(to canGoBack: Bool) {
        Task {
            try? await sendAction(.updateNavigation(
                canGoBack: canGoBack,
                canGoForward: nil
            ))
        }
    }

    public func forwardNavigationDidUpdate(to canGoForward: Bool) {
        Task {
            try? await sendAction(.updateNavigation(
                canGoBack: nil,
                canGoForward: canGoForward
            ))
        }
    }

    public func provisionalNavigationDidStart() {}

    public func siteDidOpen(appName: String) {}

    public func loadingProgressDidChange(_ progress: Float) {
        Task {
            try? await sendAction(.updateProgress(show: nil, value: progress))
        }
    }

    public func showLoadingProgress(_ show: Bool) {
        Task {
            try? await sendAction(.updateProgress(show: show, value: nil))
        }
    }

    public func webViewDidHandleReuseAction() {
        Task {
            try? await sendAction(.stopWebViewReusage)
        }
    }

    public func webViewDidReplace(_ interface: WebViewNavigatable?) {
        Task {
            try? await sendAction(.replaceWebInterface(interface))
        }
    }
}
