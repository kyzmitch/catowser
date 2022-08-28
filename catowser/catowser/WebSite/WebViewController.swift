//
//  WebViewController.swift
//  catowser
//
//  Created by Andrey Ermoshin on 27/09/2017.
//  Copyright © 2017 andreiermoshin. All rights reserved.
//

import UIKit
import WebKit
import CoreBrowser
import JSPlugins
import CoreHttpKit
import BrowserNetworking
import FeaturesFlagsKit
import ReactiveSwift
#if canImport(Combine)
import Combine
#endif

extension WKWebView: JavaScriptEvaluateble {}

final class WebViewController: BaseViewController,
                               AnyViewController,
                               WKUIDelegate,
                               WKNavigationDelegate {
    /// A view model
    let viewModel: WebViewModel
    
    /// Own navigation delegate
    private(set) weak var externalNavigationDelegate: SiteExternalNavigationDelegate?
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
    
    /// lazy loaded web view to use correct config
    lazy var webView: WKWebView = {
        webViewObserversAdded = false
        loadingProgressObservation?.invalidate()
        return createWebView(with: viewModel.configuration)
    }()

    /**
     Constructs web view controller for specific site with set of plugins and navigation handler
     */
    init(_ viewModel: WebViewModel,
         _ externalNavigationDelegate: SiteExternalNavigationDelegate) {
        self.viewModel = viewModel
        self.externalNavigationDelegate = externalNavigationDelegate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        unsubscribe()
    }
    
    override func loadView() {
        view = UIView(frame: .zero)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // try create web view only after creating
        view.addSubview(webView)
        isWebViewLoaded = true
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        webView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        subscribe()
        viewModel.load()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        unsubscribe()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touchedView = touches.first?.view {
            if touchedView === webView {
                // to fix keypad for textfields on websites
                webView.becomeFirstResponder()
            }
        }
    }
    
    private func onStateChange(_ state: WebPageLoadingAction) {
        switch state {
        case .idle:
            break
        case .load(let uRLRequest):
            webView.load(uRLRequest)
        case .recreateView:
            recreateWebView(forceRecreate: true)
        case .reattachViewObservers:
            reattachWebViewObservers()
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
    
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let correspondingDomain = viewModel.nativeAppDomainNameString {
            externalNavigationDelegate?.didOpenSiteWith(appName: correspondingDomain)
            // no need to interrupt
        }
        viewModel.decidePolicyFor(navigationAction, decisionHandler)
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        externalNavigationDelegate?.showProgress(true)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        externalNavigationDelegate?.showProgress(false)
        
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
                    self?.externalNavigationDelegate?.updateTabPreview(img)
                default:
                    print("failed to take a screenshot")
                }
            }
        }
        
        guard let newURL = webView.url else {
            print("web view without url")
            return
        }
        /**
         you must inject/re-enable plugins even if web view loaded page from same Host
         and even if ip address is used instead of domain name
         */
        let jsEnabled = FeatureManager.boolValue(of: .javaScriptEnabled)
        viewModel.finishLoading(newURL, webView, jsEnabled)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("Error occured during a committed main frame: \(error.localizedDescription)")
        externalNavigationDelegate?.showProgress(false)
    }
    
    func webView(_ webView: WKWebView,
                 didReceive challenge: URLAuthenticationChallenge,
                 completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let info = viewModel.urlInfo else { return }
        let handler = WebViewAuthChallengeHandler(info, webView, challenge, completionHandler)
        handler.solve { [weak self] in
            self?.externalNavigationDelegate?.showProgress(false)
        }
    }
    
    func webView(_ webView: WKWebView,
                 didFailProvisionalNavigation navigation: WKNavigation!,
                 withError error: Error) {
        print("Error occured while starting to load data: \(error.localizedDescription)")
        externalNavigationDelegate?.showProgress(false)
        let handler = WebViewLoadingErrorHandler(error, webView)
        handler.recover(self)
    }
}

// MARK: - private functions

private extension WebViewController {
    func unsubscribe() {
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
            assertionFailure("Resubscribtion for web view isn't implemented yet")
        }
        
        switch FeatureManager.appAsyncApiTypeValue() {
        case .reactive:
            disposable?.dispose()
            disposable = viewModel.rxWebPageState.signal.producer.startWithValues(onStateChange)
        case .combine:
            cancellable?.cancel()
            cancellable = viewModel.combineWebPageState.sink(receiveValue: onStateChange)
        case .asyncAwait:
            taskHandler?.cancel()
            taskHandler = viewModel.webPageStatePublisher.sink(receiveValue: onStateChange)
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
        loadingProgressObservation = webView.observe(\.estimatedProgress,
                                                     options: [.new]) { [weak self] (_, change) in
            guard let self = self else { return }
            guard let value = change.newValue else { return }
            self.externalNavigationDelegate?.displayProgress(value)
        }
    }
    
    func addWebViewCanGoBackObserver() {
        canGoBackObservation?.invalidate()
        canGoBackObservation = webView.observe(\.canGoBack, options: [.new]) { [weak self] (_, change) in
            guard let self = self else { return }
            guard let value = change.newValue else { return }
            self.externalNavigationDelegate?.didUpdateBackNavigation(to: value)
        }
    }
    
    func addWebViewCanGoForwardObserver() {
        canGoForwardObservation?.invalidate()
        canGoForwardObservation = webView.observe(\.canGoForward, options: [.new]) { [weak self] (_, change) in
            guard let self = self else { return }
            guard let value = change.newValue else { return }
            self.externalNavigationDelegate?.didUpdateForwardNavigation(to: value)
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
    
    func recreateWebView(forceRecreate: Bool = false) {
        if !forceRecreate {
            guard !isWebViewLoaded else {
                return
            }
        }
        
        loadingProgressObservation?.invalidate()
        webViewObserversAdded = false
        
        webView.removeFromSuperview()
        webView = createWebView(with: viewModel.configuration)
        view.addSubview(webView)
        
        webView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        webView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
}

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
