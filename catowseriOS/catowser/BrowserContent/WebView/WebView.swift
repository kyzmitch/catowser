//
//  WebView.swift
//  catowser
//
//  Created by Andrei Ermoshin on 12/19/22.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import SwiftUI
import CottonBase
import CottonData

/// A special case web view interface only for SwiftUI
/// because we have to reuse existing web view for all the tabs
protocol WebViewReusable: AnyObject {
    func resetTo(_ site: Site) async
}

/// web view specific to SwiftUI
struct WebView<W: WebViewModel>: View {
    @ObservedObject private var viewModel: W
    /// Initial site with an url to load the web view
    private let site: Site
    /// A workaround to avoid unnecessary web view updates
    private let webViewNeedsUpdate: Bool
    /// Selected swiftUI mode which is set at app start
    private let mode: SwiftUIMode

    init(_ viewModel: W,
         _ site: Site,
         _ webViewNeedsUpdate: Bool,
         _ mode: SwiftUIMode) {
        self.viewModel = viewModel
        self.site = site
        self.webViewNeedsUpdate = webViewNeedsUpdate
        self.mode = mode
    }

    var body: some View {
        /// There is no system WebView type for SwiftUI,  so that, the mode is not used for now
        WebViewLegacyView(viewModel, site, webViewNeedsUpdate)
    }
}

/// SwiftUI wrapper around UIKit web view view controller
private struct WebViewLegacyView: CatowserUIVCRepresentable {
    typealias UIViewControllerType = UIViewController

    private let viewModel: any WebViewModel
    /// Initial site with an url to load the web view
    private let site: Site
    /// A workaround to avoid unnecessary web view updates
    private let webViewNeedsUpdate: Bool
    /// Usual coordinator can't really be used for SwiftUI navigation
    /// but for the legacy view it has to be passed
    private let dummyArgument: WebContentCoordinator? = nil

    init(_ viewModel: any WebViewModel,
         _ site: Site,
         _ webViewNeedsUpdate: Bool) {
        self.viewModel = viewModel
        self.site = site
        self.webViewNeedsUpdate = webViewNeedsUpdate
    }

    func makeUIViewController(context: Context) -> UIViewControllerType {
        /**
         - Can't save web view interface here because
         `View` & `UIViewControllerRepresentable` is immutable type,
         or actually this function `makeUIViewController` is not mutable.

         - Could be possible to fetch it from `WebViewsReuseManager` if it is
         configured to use web views cache.

         - `makeUIViewController` is not called more than once
         which is not expected, but at least `updateUIViewController`
         is getting called when the state changes. So, that a web view controller
         can't be replaced with a new one on SwiftUI level
         and most likely advantage of `WebViewsReuseManager` can't be used here.
         We have to re-create web view inside view controller.
         */
        let manager = UIServiceRegistry.shared().reuseManager
        let vc = try? manager.controllerFor(site, dummyArgument, viewModel, .swiftUIWrapper)
        Task {
            await viewModel.reset(site)
        }
        // swiftlint:disable:next force_unwrapping
        return vc!.viewController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        guard let reusableWebView = uiViewController as? WebViewReusable else {
            return
        }
        // View update is getting called sometimes when it is not expected
        // so, that, using a boolean state variable to avoid unnecessary updates
        guard webViewNeedsUpdate else {
            return
        }
        Task {
            await reusableWebView.resetTo(site)
        }
    }
}
