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

final class BrowserToolbarViewModelImpl: BrowserToolbarViewModelV2 {
    public override var context: Context? {
        BrowserToolbarStateContextProxy(subject: self)
    }
    
    public override func sendAction(_ action: Action) throws {
        state = try state.handleAction(action, with: context)
    }
}

extension BrowserToolbarViewModelImpl: BrowserToolbarStateContext {
    var siteNavigationDelegate: (any SiteNavigationChangable)? {
        #warning("TODO: implement and see state context commented code for that")
        return nil
    }
}

extension BrowserToolbarViewModelImpl: SiteExternalNavigationDelegate {
    public func didBackNavigationUpdate(to canGoBack: Bool) {
        state.goBackDisabled = !canGoBack
        siteNavigationDelegate?.changeBackButton(to: canGoBack)
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
