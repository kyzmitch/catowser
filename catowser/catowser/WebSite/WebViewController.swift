//
//  WebViewController.swift
//  catowser
//
//  Created by Andrey Ermoshin on 27/09/2017.
//  Copyright © 2017 andreiermoshin. All rights reserved.
//

import UIKit
import SnapKit
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

protocol SiteNavigationComponent {
    func updateSiteNavigator(to navigator: SiteNavigationDelegate?)
    /// Reloads state of UI components
    func reloadNavigationElements()
}

final class WebViewController: BaseViewController {
    
    private(set) var currentUrl: URL

    /// Configuration should be transferred from `Site`
    private let configuration: WKWebViewConfiguration

    /// Content controller should be created every time when `Site` is changed
    private var contentController: WKUserContentController

    private var pluginsPresented: Bool = false

    func load(_ url: URL, canLoadPlugins: Bool = true) {
        if canLoadPlugins && !pluginsPresented {
            injectPlugins()
        } else if !canLoadPlugins {
            webView.configuration.userContentController = WKUserContentController()
            pluginsPresented = false
        }

        let request = URLRequest(url: url)
        webView.load(request)
    }

    private func injectPlugins() {
        contentController = WKUserContentController()

        // inject only for specific sites, to fix case
        // then instagram related plugin is injected to google site
        JSPluginsManager.shared.visit(contentController)
        // can't use `didSet` because it is called inside `init` and web view is not available yet
        webView.configuration.userContentController = contentController
        pluginsPresented = true
    }

    init(_ site: Site) {
        currentUrl = site.url
        configuration = site.webViewConfig
        contentController = WKUserContentController()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var webView: WKWebView = {
        configuration.userContentController = contentController
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.backgroundColor = .black
        
        return webView
    }()
    
    override func loadView() {
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.uiDelegate = self
        webView.navigationDelegate = self
        load(currentUrl)
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
}

extension WebViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
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

        if ["http", "https"].contains(url.scheme) {
            decisionHandler(.allow)
            return
        }

        decisionHandler(.cancel)
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        guard let webViewUrl = webView.url else {
            print("web view without url")
            return
        }

        currentUrl = webViewUrl
        let site: Site = .init(url: webViewUrl)

        do {
            try TabsListManager.shared.replaceSelected(tabContent: .site(site))
        } catch {
            print("\(#function) - failed to replace current tab")
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
    }
}

extension WebViewController: WKNavigationDelegate {
    
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
        _ = webView.goForward()
    }

    func goBack() {
        guard isViewLoaded else { return }
        _ = webView.goBack()
    }

    func reload() {
        guard isViewLoaded else { return }
        _ = webView.reload()
    }
}
