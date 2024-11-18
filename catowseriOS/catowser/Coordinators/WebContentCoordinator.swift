//
//  WebContentCoordinator.swift
//  catowser
//
//  Created by Andrei Ermoshin on 11/21/22.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import UIKit
import CottonBase
import CoreBrowser
import CottonPlugins
import CottonData

@MainActor
protocol WebContentDelegate: AnyObject {
    func provisionalNavigationDidStart()
    func loadingProgressdDidChange(_ progress: Float)
    func showLoadingProgress(_ show: Bool)
}

@MainActor
final class WebContentCoordinator: Coordinator {
    let vcFactory: ViewControllerFactory
    var startedCoordinator: Coordinator?
    weak var parent: CoordinatorOwner?
    var startedVC: AnyViewController?
    weak var presenterVC: AnyViewController?
    var navigationStack: UINavigationController?

    private let site: Site
    private let jsPluginsSource: any JSPluginsSource
    private let contentContainerView: UIView

    private var siteNavigationDelegate: SiteNavigationChangable? {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return vcFactory.createdToolbaViewController as? SiteNavigationChangable
        } else {
            return vcFactory.createdDeviceSpecificSearchBarVC as? SiteNavigationChangable
        }
    }
    private weak var delegate: WebContentDelegate?
    /// Points to web view controller, can be a strong reference, because it is the same with `startedVC`
    private var sitePresenter: WebViewNavigatable?
    /// Mode is needed only to determine if web view model needs to call the load method or not (SwiftUI mode need to not call it)
    private let mode: UIFrameworkType
    /// View model should be not private to be able to set it later, because it has async init
    var viewModel: (any WebViewModel)?

    init(_ vcFactory: ViewControllerFactory,
         _ presenter: AnyViewController,
         _ contentContainerView: UIView,
         _ delegate: WebContentDelegate,
         _ site: Site,
         _ jsPluginsSource: any JSPluginsSource,
         _ mode: UIFrameworkType) {
        self.vcFactory = vcFactory
        self.presenterVC = presenter
        self.contentContainerView = contentContainerView
        self.site = site
        self.jsPluginsSource = jsPluginsSource
        self.delegate = delegate
        self.mode = mode
    }

    func start() {
        let manager = UIServiceRegistry.shared().reuseManager
        guard let viewModel else {
            return
        }
        let webViewController = try? manager.controllerFor(site, self, viewModel, mode)
        guard let vc = webViewController else {
            assertionFailure("Failed create new web view for tab")
            return
        }
        startedVC = vc
        sitePresenter = vc
        presenterVC?.viewController.add(asChildViewController: vc.viewController, to: contentContainerView)
        let topSitesView: UIView = vc.controllerView
        topSitesView.translatesAutoresizingMaskIntoConstraints = false
        topSitesView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor).isActive = true
        topSitesView.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor).isActive = true
        topSitesView.topAnchor.constraint(equalTo: contentContainerView.topAnchor).isActive = true
        topSitesView.bottomAnchor.constraint(equalTo: contentContainerView.bottomAnchor).isActive = true
    }
}

enum WebContentRoute: Route {
    case javaScript(Bool, Host)
    case openApp(URL)
}

extension WebContentCoordinator: Navigating {
    typealias R = WebContentRoute

    func showNext(_ route: R) {
        switch route {
        case .javaScript(let enable, let host):
            sitePresenter?.enableJavaScript(enable, for: host)
        case .openApp(let url):
            UIApplication.shared.open(url, options: [:])
        }
    }

    func stop() {
        // need to stop any video/audio on corresponding web view
        // before removing it from parent view controller.
        // on iphones the video is always played in full-screen (probably need to invent workaround)
        // https://webkit.org/blog/6784/new-video-policies-for-ios/
        // "and, on iPhone, the <video> will enter fullscreen when starting playback."
        // on ipads it is played in normal mode, so, this is why need to stop/pause it

        // also need to invalidate and cancel all observations
        // in viewDidDisappear, and not in dealloc,
        // because currently web view controller reference
        // stored in reuse manager which probably
        // not needed anymore even with unsolved memory issue when it's
        // a lot of tabs are opened.
        // It is because it's very tricky to save navigation history
        // for reused web view and for some other reasons.
        startedVC?.viewController.removeFromChild()
        parent?.coordinatorDidFinish(self)
    }
}

extension WebContentCoordinator: SiteExternalNavigationDelegate {
    func didBackNavigationUpdate(to canGoBack: Bool) {
        siteNavigationDelegate?.changeBackButton(to: canGoBack)
    }

    func didForwardNavigationUpdate(to canGoForward: Bool) {
        siteNavigationDelegate?.changeForwardButton(to: canGoForward)
    }

    func provisionalNavigationDidStart() {
        delegate?.provisionalNavigationDidStart()
    }

    func didSiteOpen(appName: String) {
        // notify user to remove specific application from iOS
        // to be able to use Cotton browser features
    }

    func loadingProgressdDidChange(_ progress: Float) {
        delegate?.loadingProgressdDidChange(progress)
    }

    func showLoadingProgress(_ show: Bool) {
        delegate?.showLoadingProgress(show)
    }

    func webViewDidHandleReuseAction() {
        // no need to handle, this is SwiftUI specific
    }

    func webViewDidReplace(_ interface: WebViewNavigatable?) {
        // no need to handle, this is SwiftUI specific
    }
}
