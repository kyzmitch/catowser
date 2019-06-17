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

protocol SiteNavigationDelegate: class {
    var canGoBack: Bool { get }
    var canGoForward: Bool { get }

    func goForward()
    func goBack()
    func reload()
}

protocol SiteExternalNavigationDelegate: class {
    func didStartProvisionalNavigation()
    func didOpenSiteWith(appName: String)
    func displayProgress(_ progress: Double)
    func showProgress(_ show: Bool)
    func updateTabPreview(_ screenshot: UIImage)
}

protocol SiteNavigationComponent: class {
    /// Use `nil` to tell that navigation actions should be disabled
    var siteNavigator: SiteNavigationDelegate? { get set }
    /// Reloads state of UI components
    func reloadNavigationElements(_ withSite: Bool, downloadsAvailable: Bool)
}

extension WKWebView: JavaScriptEvaluateble {}

final class WebViewController: BaseViewController {
    
    private(set) var currentUrl: URL

    /// Configuration should be transferred from `Site`
    private var configuration: WKWebViewConfiguration

    private var pluginsFacade: WebViewJSPluginsFacade?

    private weak var externalNavigationDelegate: SiteExternalNavigationDelegate?
    
    private var webViewProgressObserverAdded = false

    func load(_ url: URL, canLoadPlugins: Bool = true) {
        currentUrl = url

        if canLoadPlugins {
            injectPlugins()
        } else if !canLoadPlugins {
            configuration.userContentController.removeAllUserScripts()
        }

        addWebViewProgressObserver()
        let request = URLRequest(url: url)
        webView.load(request)
    }

    /// Reload by creating new webview
    func load(site: Site, canLoadPlugins: Bool = true) {
        currentUrl = site.url
        configuration = site.webViewConfig
        
        if isWebViewLoaded {
            webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
            webView.removeFromSuperview()
            webViewProgressObserverAdded = false
            webView = WebViewController.createWebView(with: configuration)
            webView.navigationDelegate = self
            view.addSubview(webView)
            webView.snp.makeConstraints { (maker) in
                maker.leading.trailing.top.bottom.equalTo(view)
            }
        }
        
        if canLoadPlugins { injectPlugins() }
        
        addWebViewProgressObserver()
        let request = URLRequest(url: currentUrl)
        webView.load(request)
    }

    private func injectPlugins() {
        configuration.userContentController.removeAllUserScripts()
        // inject only for specific sites, to fix case
        // then instagram related plugin is injected to google site
        guard let facade = pluginsFacade else {
            return
        }
        facade.visit(configuration.userContentController)
    }

    init(_ site: Site, plugins: [CottonJSPlugin], externalNavigationDelegate: SiteExternalNavigationDelegate) {
        self.externalNavigationDelegate = externalNavigationDelegate
        currentUrl = site.url
        configuration = site.webViewConfig
        if site.canLoadPlugins {
            pluginsFacade = WebViewJSPluginsFacade(plugins)
        }

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var isWebViewLoaded: Bool = false

    private lazy var webView: WKWebView = {
        webViewProgressObserverAdded = false
        return WebViewController.createWebView(with: configuration)
    }()
    
    private static func createWebView(with config: WKWebViewConfiguration) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.backgroundColor = .white
        return webView
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            externalNavigationDelegate?.displayProgress(webView.estimatedProgress)
        }
    }
    
    override func loadView() {
        view = UIView(frame: .zero)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        load(currentUrl)
        // try create web view only after creating
        view.addSubview(webView)
        isWebViewLoaded = true
        webView.navigationDelegate = self
        webView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        webView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // TODO: don't remember why it is needed
        if let touchedView = touches.first?.view {
            if touchedView === webView {
                webView.becomeFirstResponder()
            }
        }
    }
}

private extension WebViewController {
    func addWebViewProgressObserver() {
        if !webViewProgressObserverAdded {
            webViewProgressObserverAdded = true
            webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        }
    }
}

fileprivate extension WebViewController {
    func isAppleMapsURL(_ url: URL) -> Bool {
        if url.scheme == "http" || url.scheme == "https" {
            if url.host == "maps.apple.com" && url.query != nil {
                return true
            }
        }
        return false
    }

    func isStoreURL(_ url: URL) -> Bool {
        if url.scheme == "http" || url.scheme == "https" || url.scheme == "itms-apps" {
            if url.host == "itunes.apple.com" {
                return true
            }
        }
        return false
    }
    
    func handleNavigationCommit(_ wkView: WKWebView) {
        guard let webViewUrl = wkView.url else {
            print("web view without url")
            return
        }
        
        let sameHost: Bool = currentUrl.host == webViewUrl.host
        
        currentUrl = webViewUrl
        guard let site = Site(url: webViewUrl) else {
            assertionFailure("failed create site from URL")
            return
        }
        
        if !sameHost {
            // enabling plugin works here for instagram, but not for t4 site
            pluginsFacade?.enablePlugins(for: wkView, with: currentUrl.host)
            InMemoryDomainSearchProvider.shared.rememberDomain(name: site.host)
        }
        
        do {
            try TabsListManager.shared.replaceSelected(tabContent: .site(site))
        } catch {
            print("\(#function) - failed to replace current tab")
        }
    }
}

extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }

        if url.scheme == "about" {
            // This will handle about:blank from youtube.
            
            // sometimes url can be unexpected
            // this one is when you tap on some youtube video
            // when you was browsing youtube
            // also, you can get url to Ad when you're browsing it
            // https://accounts.google.com/ServiceLogin.....
            
            if let aboutHost = navigationAction.request.mainDocumentURL?.host, let currentHost = currentUrl.host {
                if aboutHost.contains(currentHost) || aboutHost == currentHost {
                    decisionHandler(.allow)
                } else {
                    decisionHandler(.cancel)
                }
            } else if let hiddenURL = webView.url {
                decisionHandler(.cancel)
                let req = URLRequest(url: hiddenURL)
                _ = webView.load(req)
                // this will give next:
                // 1) page reload to trigger JS plugin
                // 2) trigger URL update in address field
                // it will not fix:
                // - double item in backForwardList
                // - wrong URL after tap on back, only web view reload will
                // THIS triggers infinite reload for 4tube site
            } else {
                decisionHandler(.allow)
            }
            return
        }
        
        if url.scheme == "tel" || url.scheme == "facetime" || url.scheme == "facetime-audio" {
            UIApplication.shared.open(url, options: [:])
            decisionHandler(.cancel)
            return
        }

        if isAppleMapsURL(url) {
            UIApplication.shared.open(url, options: [:])
            decisionHandler(.cancel)
            return
        }

        if isStoreURL(url) {
            UIApplication.shared.open(url, options: [:])
            decisionHandler(.cancel)
            return
        }

        if url.scheme == "mailto" {
            UIApplication.shared.open(url, options: [:])
            decisionHandler(.cancel)
            return
        }

        if let checker = try? DomainNativeAppChecker(url: url.absoluteString) {
            externalNavigationDelegate?.didOpenSiteWith(appName: checker.correspondingDomain)

            let ignoreAppRawValue = WKNavigationActionPolicy.allow.rawValue + 2
            guard let _ = WKNavigationActionPolicy(rawValue: ignoreAppRawValue) else {
                externalNavigationDelegate?.showProgress(true)
                decisionHandler(.allow)
                return
            }
            externalNavigationDelegate?.showProgress(true)
            decisionHandler(WKNavigationActionPolicy(rawValue: ignoreAppRawValue)!)
            return
        }

        if ["http", "https"].contains(url.scheme) {
            externalNavigationDelegate?.showProgress(true)
            decisionHandler(.allow)
            return
        }

        decisionHandler(.cancel)
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        handleNavigationCommit(webView)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        externalNavigationDelegate?.showProgress(false)
        pluginsFacade?.enablePlugins(for: webView, with: currentUrl.host)
        
        let snapshotConfig = WKSnapshotConfiguration()
        let w = webView.bounds.size.width
        let h = webView.bounds.size.height
        snapshotConfig.rect = CGRect(x: 0, y: 0, width: w, height: h)
        snapshotConfig.snapshotWidth = NSNumber(integerLiteral: 256)
        webView.takeSnapshot(with: snapshotConfig) { [weak self] (image, error) in
            switch (image, error) {
            case (_, let err?):
                print("failed to take a screenshot \(err)")
            case (let img?, _):
                self?.externalNavigationDelegate?.updateTabPreview(img)
            case (.none, .none):
                print("failed to take a screenshot")
            }
        }
    }
}

extension WebViewController: SiteNavigationDelegate {
    var canGoBack: Bool {
        return isViewLoaded ? webView.canGoBack : false
    }

    var canGoForward: Bool {
        return isViewLoaded ? webView.canGoForward : false
    }

    func goForward() {
        guard isViewLoaded else { return }
        externalNavigationDelegate?.didStartProvisionalNavigation()
        _ = webView.goForward()
    }

    func goBack() {
        guard isViewLoaded else { return }
        externalNavigationDelegate?.didStartProvisionalNavigation()
        _ = webView.goBack()
    }

    func reload() {
        guard isViewLoaded else { return }
        externalNavigationDelegate?.didStartProvisionalNavigation()
        _ = webView.reload()
    }
}
