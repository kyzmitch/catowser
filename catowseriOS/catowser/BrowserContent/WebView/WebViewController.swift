//
//  WebViewController.swift
//  catowser
//
//  Created by Andrey Ermoshin on 27/09/2017.
//  Copyright © 2017 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import UIKit
import WebKit
import CoreBrowser
import CottonPlugins
import CottonBase
import CottonNetworking
import FeatureFlagsKit
import ReactiveSwift
#if canImport(Combine)
@preconcurrency import Combine
#endif
import CottonViewModels

/// Can't retroactivly mark web view as sendable, it is a system type and protocol.
extension WKWebView: @unchecked Sendable { }

/// Can be retroactive because Web view Apple devs don't know about JavaScriptEvaluateble protocol.
extension WKWebView: @retroactive JavaScriptEvaluateble {
    public func evaluateJavaScriptV2(
        _ javaScriptString: String,
        completionHandler: (@MainActor @Sendable (Any?, (any Error)?) -> Void)?
    ) {
        evaluateJavaScript(javaScriptString, completionHandler: completionHandler)
    }
    public func evaluateJavaScriptV1(
        _ javaScriptString: String,
        completionHandler: ((Any?, Error?) -> Void)?
    ) {
#if swift(<6.0)
            evaluateJavaScript(javaScriptString, completionHandler: completionHandler)
#endif
    }
}

final class WebViewController<C: Navigating>: BaseViewController, WKUIDelegate, WKNavigationDelegate where C.R == WebContentRoute {
    /// A view model, optional because it is tricky to inject it in constructor in init because of async dependencies
    let viewModel: any WebViewModel
    /// A coordinator reference
    private weak var coordinator: C?
    /// State of observers
    private var webViewObserversAdded = false
    /// State of web view
    private var isWebViewLoaded: Bool = false
    /// Controller first appearance
    private var isFirstAppearance = true

    /// Need to use KVO for web view property because for some WKNavigations for
    /// not usual URLs like about:srcdoc the didCommit and didFinish won't be called
    /// and navigation button won't be updated based on state.
    private var canGoBackObservation: NSKeyValueObservation?
    private var canGoForwardObservation: NSKeyValueObservation?
    private var loadingProgressObservation: NSKeyValueObservation?

    /// reactive disposanble needed to be able to cancel producer
    private var disposable: Disposable?
    /// needed to be able to cancel publisher
    private var cancellable: AnyCancellable?
    /// Combine cancellable for Concurrency Published property
    private var taskHandler: AnyCancellable?
    /// DoH changes cancellable for combine
    private var dohCancellable: AnyCancellable?
    /// DoH changes disposable for rx
    private var dohDisposable: Disposable?
    /// JS subscriber
    private var jsStateCancellable: AnyCancellable?

    /// lazy loaded web view to use correct config
    private(set) var webView: WKWebView?
    /// A reference to the optional auth handler to allow use background queue for the callback
    private(set) var authHandlers: Set<WebViewAuthChallengeHandler> = []
    /// A proxy value for re-usable web view, only one needed
    private var proxy: WebViewControllerProxy?
    /// UI framework mode to determine if need to call viewModel.load or not
    private let mode: UIFrameworkType

    /**
     Constructs web view controller for specific site with set of plugins and navigation handler.

     Currently it is too tricky to inject view model right away because it has to be async
     */
    init(_ coordinator: C?,
         _ viewModel: any WebViewModel,
         _ mode: UIFrameworkType) {
        self.coordinator = coordinator
        self.viewModel = viewModel
        self.mode = mode
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = UIView(frame: .zero)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Not creating a web view and hoping to create it
        // during view model state handling for `.initialized` value
        // See `onStateChange` and `recreateView` with `reattachViewObservers`
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        subscribe()

        guard mode == .uiKit else {
            /// No need to load view model, because SwiftUI wrapper calls resetToSite
            /// see `WebViewLegacyView` and `WebView.swift`
            return
        }
        Task {
            /// Load initial site or just wait for the reset to site action
            await viewModel.load()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // The only re-usable view controller is not visible now
        // it means that it was replaced with some different content
        // maybe top sites, so, we have to reset navigation controls
        // and it can be done by sending `nil` interface
        viewModel.siteNavigation?.webViewDidReplace(nil)
        authHandlers.removeAll()
        unsubscribe()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touchedView = touches.first?.view {
            if touchedView === webView {
                // to fix keypad for textfields on websites
                webView?.becomeFirstResponder()
            }
        }
    }

    private func onStateChange(_ state: WebPageLoadingAction) {
        switch state {
        case .load(let uRLRequest):
            webView?.load(uRLRequest)
        case .recreateView(let forcefullyRecreate):
            recreateWebView(forcefullyRecreate)
        case .reattachViewObservers:
            reattachWebViewObservers()
        case .openApp(let url):
            coordinator?.showNext(.openApp(url))
        @unknown default:
            fatalError("Not handled web page loading state")
        }
    }

    // MARK: - WKUIDelegate

    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {

        return nil
    }

    // MARK: - WKNavigationDelegate

    private func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let domain = viewModel.nativeAppDomainNameString {
            viewModel.siteNavigation?.siteDidOpen(appName: domain)
            // no need to interrupt
        }
        Task {
            await viewModel.decidePolicy(navigationAction, decisionHandler)
        }
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        viewModel.siteNavigation?.showLoadingProgress(true)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        viewModel.siteNavigation?.showLoadingProgress(false)

        defer {
            let snapshotConfig = WKSnapshotConfiguration()
            let w = webView.bounds.size.width
            let h = webView.bounds.size.height
            snapshotConfig.rect = CGRect(x: 0, y: 0, width: w, height: h)
            snapshotConfig.snapshotWidth = 256
            webView.takeSnapshot(with: snapshotConfig) { [weak self] (image, error) in
                switch (image, error) {
                case (_, let err?):
                    print("failed to take a screenshot \(err)")
                case (let img?, _):
                    Task {
                        await self?.viewModel.updateTabPreview(img.pngData())
                    }
                default:
                    print("failed to take a screenshot")
                }
            }
        }

        guard let newURL = webView.url else {
            print("web view without url")
            return
        }

        Task {
            await viewModel.finishLoading(newURL, webView)
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("Error occured during a committed main frame: \(error.localizedDescription)")
        viewModel.siteNavigation?.showLoadingProgress(false)
    }

    private func webView(_ webView: WKWebView,
                         didReceive challenge: URLAuthenticationChallenge,
                         completionHandler: @escaping @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let handler = WebViewAuthChallengeHandler(viewModel.urlInfo, webView, challenge, completionHandler)
        authHandlers.insert(handler)
        handler.solve { [weak self, weak handler] stopLoadingProgress in
            guard let self else {
                return
            }
            if stopLoadingProgress != nil {
                viewModel.siteNavigation?.showLoadingProgress(false)
            }
            guard let handler else {
                return
            }
            self.authHandlers.remove(handler)
        }
    }

    func webView(_ webView: WKWebView,
                 didFailProvisionalNavigation navigation: WKNavigation!,
                 withError error: Error) {
        print("Error occured while starting to load data: \(error.localizedDescription)")
        viewModel.siteNavigation?.showLoadingProgress(false)
        let handler = WebViewLoadingErrorHandler(error, webView)
        handler.recover(self)
    }
}

// MARK: - private functions

private extension WebViewController {
    func unsubscribe() {
        dohCancellable?.cancel()
        dohDisposable?.dispose()
        disposable?.dispose()
        cancellable?.cancel()
        taskHandler?.cancel()
        loadingProgressObservation?.invalidate()
        canGoForwardObservation?.invalidate()
        canGoBackObservation?.invalidate()
    }

    func subscribe() {
        if isFirstAppearance {
            isFirstAppearance = false
        } else {
            // so, reuse of web view controller isn't ready
            // but probably not needed
            print("Resubscribtion for web view isn't implemented yet")
        }

        // Using only Concurrency (ReactiveSwift and Combine are not easy to maintain for this method)

        taskHandler?.cancel()
        taskHandler = viewModel.webPageStatePublisher.sink(receiveValue: onStateChange)
        dohCancellable?.cancel()
        jsStateCancellable?.cancel()

        Task {
            dohCancellable = await FeatureManager.shared
                .featureChangesPublisher(for: .dnsOverHTTPSAvailable)
                .sink { _ in
                    Task { [weak self] in
                        let useDoH = await FeatureManager.shared.boolValue(of: .dnsOverHTTPSAvailable)
                        await self?.viewModel.setDoH(useDoH)
                    }
                }

            jsStateCancellable = await FeatureManager.shared
                .featureChangesPublisher(for: .javaScriptEnabled)
                .sink { _ in
                    Task { [weak self] in
                        guard let self, let jsSubject = self.webView  else {
                            return
                        }
                        let enabled = await FeatureManager.shared.boolValue(of: .javaScriptEnabled)
                        await self.viewModel.setJavaScript(jsSubject, enabled)
                    }
                }
        }
    }

    func createWebView(with config: WKWebViewConfiguration) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.backgroundColor = .white
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true

        return webView
    }

    func addWebViewProgressObserver() {
        // https://github.com/ole/whats-new-in-swift-4/blob/master/
        // Whats-new-in-Swift-4.playground/Pages/Key%20paths.xcplaygroundpage/Contents.swift#L53-L95

        loadingProgressObservation?.invalidate()
        loadingProgressObservation = webView?.observe(
            \.estimatedProgress,
             options: [.new]) { [weak self] (_, change) in
                 guard let self, let value = change.newValue else {
                     return
                 }
                 Task {
                     await viewModel
                         .siteNavigation?
                         .loadingProgressDidChange(Float(value))
                 }
        }
    }

    func addWebViewCanGoBackObserver() {
        canGoBackObservation?.invalidate()
        canGoBackObservation = webView?.observe(\.canGoBack, options: [.new]) { [weak self] (_, change) in
            guard let self, let value = change.newValue else {
                return
            }
            Task {
                await viewModel.siteNavigation?.backNavigationDidUpdate(to: value)
            }
        }
    }

    func addWebViewCanGoForwardObserver() {
        canGoForwardObservation?.invalidate()
        canGoForwardObservation = webView?.observe(\.canGoForward, options: [.new]) { [weak self] (_, change) in
            guard let self, let value = change.newValue else {
                return
            }
            Task {
                await viewModel.siteNavigation?.forwardNavigationDidUpdate(to: value)
            }
        }
    }

    func reattachWebViewObservers() {
        guard !webViewObserversAdded else {
            return
        }
        webViewObserversAdded = true
        addWebViewProgressObserver()
        addWebViewCanGoBackObserver()
        addWebViewCanGoForwardObserver()
    }

    func recreateWebView(_ forcefullyRecreate: Bool = false) {
        if !forcefullyRecreate {
            guard !isWebViewLoaded else {
                return
            }
        }

        loadingProgressObservation?.invalidate()
        canGoForwardObservation?.invalidate()
        canGoBackObservation?.invalidate()
        webViewObserversAdded = false

        // Removing of web view from superview leads to
        // `AttributeGraph: cycle detected through attribute` warning
        // https://developer.apple.com/forums/thread/126890
        // but for re-usable web view there is no other way
        // of resetting the old navigation history
        webView?.removeFromSuperview()
        let newWebView = createWebView(with: viewModel.configuration)
        view.addSubview(newWebView)

        newWebView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        newWebView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        newWebView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        newWebView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        webView = newWebView

        // Somehow would be good to reset web view interface
        // to reset navigation delegate (toolbar or table search bar)
        // because for SwiftUI mode the same view controller stays
        // and only web view changes, so, `WebViewsReuseManager`
        // won't create a new view controller and notify navigation delegates
        // that is why we have to use same `self` and it shouldn't
        // be checked that it is the same reference.
        let proxyValue = WebViewControllerProxy(self)
        proxy = proxyValue
        viewModel.siteNavigation?.webViewDidReplace(proxyValue)
    }
}

/// Can't be retroactive for CustomDebugStringConvertible cause it is a system protocol.
extension WKNavigationType: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .linkActivated:
            return "linkActivated"
        case .formSubmitted:
            return "formSubmitted"
        case .backForward:
            return "backForward"
        case .reload:
            return "reload"
        case .formResubmitted:
            return "formResubmitted"
        case .other:
            return "other"
        @unknown default:
            return "default \(rawValue)"
        }
    }
}

/// Can be retroactive because NavigationActionable is unknown for web view Apple devs.
extension WKNavigationAction: @retroactive NavigationActionable {}
