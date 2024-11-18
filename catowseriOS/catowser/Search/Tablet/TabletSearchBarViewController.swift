//
//  TabletSearchBarViewController.swift
//  catowser
//
//  Created by admin on 19/02/2018.
//  Copyright © 2018 Cotton (former Catowser). All rights reserved.
//

import UIKit
import CoreBrowser
import CottonData

final class TabletSearchBarViewController: BaseViewController {

    private let searchBarViewController: SearchBarBaseViewController

    /// Site navigation delegate. It is always `nil` during initialization because no active web view is present
    private weak var webViewInterface: WebViewNavigatable? {
        didSet {
            guard webViewInterface != nil else {
                goBackButton.isEnabled = false
                goForwardButton.isEnabled = false
                reloadButton.isEnabled = false
                downloadLinksButton.isEnabled = false
                return
            }

            // this will be useful when user will change current web view
            reloadNavigationElements(true)
        }
    }

    private weak var globalSettingsDelegate: GlobalMenuDelegate?

    private weak var downloadPanelDelegate: DownloadPanelPresenter?

    init(_ searchBarDelegate: UISearchBarDelegate?,
         _ settingsDelegate: GlobalMenuDelegate?,
         _ downloadDelegate: DownloadPanelPresenter?,
         _ uiFramework: UIFrameworkType) {
        searchBarViewController = UIServiceRegistry.shared()
            .vcFactory
            .searchBarViewController(searchBarDelegate, uiFramework)
        globalSettingsDelegate = settingsDelegate
        downloadPanelDelegate = downloadDelegate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var actionsButton: UIButton = {
        let btn: UIButton
        if #available(iOS 13.0, *) {
            if let systemImage = UIImage.arropUp {
                btn = UIButton()
                btn.setImage(systemImage, for: .normal)
                btn.addTarget(self, action: .actionsPressed, for: .touchUpInside)
            } else {
                btn = .systemButton(with: .actions, target: self, action: .actionsPressed)
            }
        } else {
            btn = UIButton(type: .infoLight)
            btn.addTarget(self, action: .actionsPressed, for: .touchUpInside)
        }
        btn.backgroundColor = ThemeProvider.shared.theme.searchBarButtonBackgroundColor
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private lazy var downloadLinksButton: UIButton = {
        let img = UIImage(named: "nav-downloads")
        let btn = UIButton()
        btn.setImage(img, for: .normal)
        btn.addTarget(self, action: .downloads, for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private lazy var goBackButton: UIButton = {
        let btn = UIButton()
        let img = UIImage(named: "nav-back")
        btn.backgroundColor = ThemeProvider.shared.theme.searchBarButtonBackgroundColor
        btn.setImage(img, for: .normal)
        btn.addTarget(self, action: .backPressed, for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private lazy var goForwardButton: UIButton = {
        let btn = UIButton()
        let img = UIImage(named: "nav-forward")
        btn.backgroundColor = ThemeProvider.shared.theme.searchBarButtonBackgroundColor
        btn.setImage(img, for: .normal)
        btn.addTarget(self, action: .forwardPressed, for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private lazy var reloadButton: UIButton = {
        let btn = UIButton()
        let img = UIImage(named: "nav-refresh")
        btn.backgroundColor = ThemeProvider.shared.theme.searchBarButtonBackgroundColor
        btn.setImage(img, for: .normal)
        btn.addTarget(self, action: .reloadPressed, for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let lineView: UIView = {
        let view = UIView()
        view.backgroundColor = ThemeProvider.shared.theme.searchBarSeparatorColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override func loadView() {
        view = UIView()

        view.addSubview(actionsButton)
        view.addSubview(goBackButton)
        view.addSubview(goForwardButton)
        view.addSubview(reloadButton)
        view.addSubview(downloadLinksButton)
        add(asChildViewController: searchBarViewController, to: view)
        view.addSubview(lineView)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // enable actions even for non site content
        // to allow user to get to global settings
        actionsButton.isEnabled = true
        // disabled after `init` because no web view is present
        goBackButton.isEnabled = false
        goForwardButton.isEnabled = false
        reloadButton.isEnabled = false
        downloadLinksButton.isEnabled = false

        view.backgroundColor = UIConstants.searchBarBackgroundColour

        actionsButton.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        actionsButton.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        actionsButton.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        actionsButton.widthAnchor.constraint(equalTo: view.heightAnchor).isActive = true

        goBackButton.leadingAnchor.constraint(equalTo: actionsButton.trailingAnchor).isActive = true
        goBackButton.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        goBackButton.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        goBackButton.widthAnchor.constraint(equalTo: view.heightAnchor).isActive = true

        goForwardButton.leadingAnchor.constraint(equalTo: goBackButton.trailingAnchor).isActive = true
        goForwardButton.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        goForwardButton.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        goForwardButton.widthAnchor.constraint(equalTo: view.heightAnchor).isActive = true

        reloadButton.leadingAnchor.constraint(equalTo: goForwardButton.trailingAnchor).isActive = true
        reloadButton.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        reloadButton.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        reloadButton.widthAnchor.constraint(equalTo: view.heightAnchor).isActive = true

        downloadLinksButton.leadingAnchor.constraint(equalTo: reloadButton.trailingAnchor).isActive = true
        downloadLinksButton.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        downloadLinksButton.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        downloadLinksButton.widthAnchor.constraint(equalTo: view.heightAnchor).isActive = true

        let searchBarView: UIView = searchBarViewController.view
        searchBarView.translatesAutoresizingMaskIntoConstraints = false

        searchBarView.leadingAnchor.constraint(equalTo: downloadLinksButton.trailingAnchor).isActive = true
        searchBarView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        searchBarView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        searchBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true

        lineView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        lineView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        lineView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        lineView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }

    @objc fileprivate func actionsPressed() {
        let sourceRect = actionsButton.frame
        globalSettingsDelegate?.settingsDidPress(from: view, and: sourceRect)
    }

    @objc func downloadsPressed() {
        let sourceRect = downloadLinksButton.frame
        downloadPanelDelegate?.didPressTabletLayoutDownloads(from: view, and: sourceRect)
    }

    @objc fileprivate func backPressed() {
        webViewInterface?.goBack()
        refreshNavigation()
    }

    @objc fileprivate func forwardPressed() {
        webViewInterface?.goForward()
        refreshNavigation()
    }

    @objc fileprivate func reloadPressed() {
        webViewInterface?.reload()
    }

    private func refreshNavigation() {
        // actions should be always enabled to get to global settings
        goBackButton.isEnabled = webViewInterface?.canGoBack ?? false
        goForwardButton.isEnabled = webViewInterface?.canGoForward ?? false
    }
}

extension TabletSearchBarViewController: FullSiteNavigationComponent {
    func changeBackButton(to canGoBack: Bool) {
        goBackButton.isEnabled = canGoBack
    }

    func changeForwardButton(to canGoForward: Bool) {
        goForwardButton.isEnabled = canGoForward
    }

    var siteNavigator: WebViewNavigatable? {
        get {
            return webViewInterface
        }
        set (newValue) {
            webViewInterface = newValue
        }
    }

    func reloadNavigationElements(_ withSite: Bool, downloadsAvailable: Bool = false) {
        goBackButton.isEnabled = webViewInterface?.canGoBack ?? false
        goForwardButton.isEnabled = webViewInterface?.canGoForward ?? false
        reloadButton.isEnabled = withSite
        downloadLinksButton.isEnabled = downloadsAvailable
    }
}

extension TabletSearchBarViewController: SearchBarControllerInterface {
    func handleAction(_ action: SearchBarAction) {
        searchBarViewController.handleAction(action)
    }
}

extension TabletSearchBarViewController: MediaLinksPresenter {
    func didReceiveMediaLinks() {
        downloadLinksButton.isEnabled = true
        // can animate button to make it more noticeable for user
    }

    var downloadsPopoverStartInfo: (UIView, CGRect) {
        (view, downloadLinksButton.frame)
    }
}

fileprivate extension Selector {
    static let backPressed = #selector(TabletSearchBarViewController.backPressed)
    static let forwardPressed = #selector(TabletSearchBarViewController.forwardPressed)
    static let reloadPressed = #selector(TabletSearchBarViewController.reloadPressed)
    static let actionsPressed = #selector(TabletSearchBarViewController.actionsPressed)
    static let downloads = #selector(TabletSearchBarViewController.downloadsPressed)
}
