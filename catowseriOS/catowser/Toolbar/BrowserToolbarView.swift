//
//  BrowserToolbarView.swift
//  catowser
//
//  Created by Andrei Ermoshin on 17/04/2019.
//  Copyright © 2019 Cotton (former Catowser). All rights reserved.
//

import UIKit
import CoreBrowser
import CottonData
import FeatureFlagsKit
import CottonViewModels
import CottonDataServices

enum WebToolbarState {
    case nothingToNavigate
    case readyForNavigation
    case readyForDownloads
    case downloadsTapped
    case updateBackState(Bool)
    case updateForwardState(Bool)

    var downloadsAvailable: Bool {
        switch self {
        case .nothingToNavigate:
            return false
        case .readyForNavigation:
            return false
        case .readyForDownloads:
            return true
        case .downloadsTapped:
            return true
        case .updateBackState, .updateForwardState:
            // Not possible to determine actual state
            return false
        }
    }
}

final class BrowserToolbarView: UIToolbar {
    /// global settings delegate
    weak var globalSettingsDelegate: GlobalMenuDelegate?
    /// web view navigation interface
    weak var webViewInterface: WebViewNavigatable?
    /// Feature manager
    private let featureManager: FeatureManager.StateHolder
    /// service registry to not depend on ios 17 for the tabs subject
    private let uiServiceRegistry: UIServiceRegistry

    // MARK: - state properties

    var state: WebToolbarState = .nothingToNavigate {
        didSet {
            onStateChange(state)
        }
    }

    // MARK: - private stored properties

    private var enableDownloadsButton: Bool = false {
        didSet {
            downloadLinksButton.isEnabled = enableDownloadsButton
            downloadsView.alpha = enableDownloadsButton ? 1.0 : 0.3
        }
    }

    private var downloadsViewHidden: Bool = true {
        didSet {
            animateDownloadsArrow(down: !downloadsViewHidden)
        }
    }

    // MARK: - subviews

    let counterView: CounterView = .init(frame: .zero)

    lazy var downloadsView: UIImageView = {
        let img = UIImage(named: "nav-downloads")
        let imgView = UIImageView(image: img)
        return imgView
    }()

    private lazy var downloadLinksButton: UIBarButtonItem = {
        let btn = UIBarButtonItem(customView: downloadsView)
        // Setting the action handler doesn't work.
        // Using `touchesBegan` in view controller instead.
        return btn
    }()

    private lazy var backButton: UIBarButtonItem = {
        let img = UIImage(named: "nav-back")
        let back = #selector(BrowserToolbarView.handleBackPressed)
        let btn = UIBarButtonItem(image: img, style: .plain, target: self, action: back)
        return btn
    }()

    private lazy var forwardButton: UIBarButtonItem = {
        let img = UIImage(named: "nav-forward")
        let forward = #selector(BrowserToolbarView.handleForwardPressed)
        let btn = UIBarButtonItem(image: img, style: .plain, target: self, action: forward)
        return btn
    }()

    private lazy var reloadButton: UIBarButtonItem = {
        let img = UIImage(named: "nav-refresh")
        let reload = #selector(BrowserToolbarView.handleReloadPressed)
        let btn = UIBarButtonItem(image: img, style: .plain, target: self, action: reload)
        return btn
    }()

    private lazy var actionsButton: UIBarButtonItem = {
        let btn: UIBarButtonItem
        let actions = #selector(BrowserToolbarView.handleActionsPressed)
        if #available(iOS 13.0, *) {
            if let systemImage = UIImage.arropUp {
                btn = .init(image: systemImage, style: .plain, target: self, action: actions)
            } else {
                btn = .init(barButtonSystemItem: .action, target: self, action: actions)
            }
        } else {
            btn = .init(barButtonSystemItem: .action, target: self, action: actions)
        }
        return btn
    }()

    private lazy var openedTabsButton: UIBarButtonItem = {
        // Can't use simple bar button with text because it positioned incorrectly
        let btn = UIBarButtonItem(customView: counterView)
        return btn
    }()

    private lazy var standardToolbarButtons: [UIBarButtonItem] = {
        var barItems = [UIBarButtonItem]()
        barItems.append(backButton)
        let space1 = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        barItems.append(space1)
        barItems.append(forwardButton)
        let space2 = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        barItems.append(space2)
        barItems.append(reloadButton)
        let space3 = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        barItems.append(space3)
        barItems.append(openedTabsButton)
        return barItems
    }()

    /// Instead of `didMoveToSuperview`
    func attachToTabsListManager() async {
        await TabsDataServiceFactory.shared.attach(self, notify: false)
        await TabsDataServiceFactory.shared.attach(counterView, notify: true)
    }

    // MARK: - initialization

    init(
        frame: CGRect,
        featureManager: FeatureManager.StateHolder,
        uiServiceRegistry: UIServiceRegistry
    ) {
        self.featureManager = featureManager
        self.uiServiceRegistry = uiServiceRegistry
        if frame.width <= 10 {
            // iOS 13.x fix for layout errors for code
            // which works on iOS 13.x on iPad
            // and worked for iOS 12.x for all kind of devices

            // swiftlint:disable:next line_length
            // https://github.com/hackiftekhar/IQKeyboardManager/pull/1598/
            // files#diff-f73f23d86e3154de71cd5bd9abf275f0R146
            super.init(frame: CGRect(x: 0, y: 0, width: 1000, height: .toolbarViewHeight))
        } else {
            super.init(frame: frame)
        }
        
        Task {
            let observingType = await featureManager.observingApiTypeValue()
            if #available(iOS 17.0, *), observingType == .systemObservation {
                startTabsObservation()
                await readTabsState()
            } else {
                await attachToTabsListManager()
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - state handler

    private func onStateChange(_ nextState: WebToolbarState) {
        // See `diff` comment to find a difference with previos state handling

        switch nextState {
        case .nothingToNavigate:
            backButton.isEnabled = false
            forwardButton.isEnabled = false
            reloadButton.isEnabled = false
            // allow to show actions even for top sites view
            // to be able for user to get to global settings
            updateToolbar(downloadsAvailable: false, actionsAvailable: true)
            downloadsViewHidden = true
            enableDownloadsButton = false
        case .readyForNavigation:
            let canGoBack = webViewInterface?.canGoBack ?? false
            let canGoForward = webViewInterface?.canGoForward ?? false
            // this will be useful when user will change current web view
            backButton.isEnabled = canGoBack
            forwardButton.isEnabled = canGoForward
            reloadButton.isEnabled = true // diff
            updateToolbar(downloadsAvailable: false, actionsAvailable: true)
            downloadsViewHidden = true
            enableDownloadsButton = false
        case .readyForDownloads:
            let canGoBack = webViewInterface?.canGoBack ?? false
            let canGoForward = webViewInterface?.canGoForward ?? false
            backButton.isEnabled = canGoBack
            forwardButton.isEnabled = canGoForward
            reloadButton.isEnabled = true
            updateToolbar(downloadsAvailable: true, actionsAvailable: true)
            downloadsViewHidden = true
            enableDownloadsButton = true // diff
        case .downloadsTapped:
            let canGoBack = webViewInterface?.canGoBack ?? false
            let canGoForward = webViewInterface?.canGoForward ?? false
            backButton.isEnabled = canGoBack
            forwardButton.isEnabled = canGoForward
            reloadButton.isEnabled = true
            updateToolbar(downloadsAvailable: true, actionsAvailable: true)
            downloadsViewHidden = false // diff
            enableDownloadsButton = true
        case .updateBackState(let canGoBack):
            backButton.isEnabled = canGoBack
        case .updateForwardState(let canGoForward):
            forwardButton.isEnabled = canGoForward
        }
    }

    // MARK: - overrides

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isUserInteractionEnabled else { return nil }

        guard !isHidden else { return nil }

        guard alpha >= 0.01 else { return nil }

        guard self.point(inside: point, with: event) else { return nil }

        if counterView.point(inside: convert(point, to: counterView), with: event) {
            return counterView
        }

        if downloadsView.point(inside: convert(point, to: downloadsView), with: event) {
            return downloadsView
        }

        for subview in subviews.reversed() {
            let convertedPoint = subview.convert(point, from: self)
            if let candidate = subview.hitTest(convertedPoint, with: event) {
                return candidate
            }
        }

        return super.hitTest(point, with: event)
    }

    // MARK: - action handlers

    @objc private func handleBackPressed() {
        forwardButton.isEnabled = webViewInterface?.canGoForward ?? false
        backButton.isEnabled = webViewInterface?.canGoBack ?? false
        webViewInterface?.goBack()
    }

    @objc private func handleForwardPressed() {
        forwardButton.isEnabled = webViewInterface?.canGoForward ?? false
        backButton.isEnabled = webViewInterface?.canGoBack ?? false
        webViewInterface?.goForward()
    }

    @objc private func handleReloadPressed() {
        webViewInterface?.reload()
    }

    @objc private func handleActionsPressed() {
        globalSettingsDelegate?.settingsDidPress(from: self, and: .zero)
    }
}

private extension BrowserToolbarView {
    func updateToolbar(downloadsAvailable: Bool, actionsAvailable: Bool) {
        var barItems = standardToolbarButtons
        if actionsAvailable {
            let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            barItems.append(space)
            barItems.append(actionsButton)
        }
        if downloadsAvailable {
            let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            barItems.append(space)
            barItems.append(downloadLinksButton)
        }
        setItems(barItems, animated: true)
    }

    func animateDownloadsArrow(down: Bool) {
        let rotate = UIViewPropertyAnimator(duration: 0.33, curve: .easeIn)
        rotate.addAnimations {
            let angle = down ? CGFloat.pi : 0
            self.downloadsView.transform = CGAffineTransform(rotationAngle: angle)
        }
        rotate.startAnimation()
    }
    
    @available(iOS 17.0, *)
    func readTabsState() async {
        await handleSelectedTabChange()
        await handleTabsCountChange()
    }
    
    @available(iOS 17.0, *)
    @MainActor
    func startTabsObservation() {
        withObservationTracking {
            _ = uiServiceRegistry.tabsSubject.selectedTabId
        } onChange: {
            Task { [weak self] in
                await self?.handleSelectedTabChange()
            }
        }

        withObservationTracking {
            _ = uiServiceRegistry.tabsSubject.tabsCount
        } onChange: {
            Task { [weak self] in
                await self?.handleTabsCountChange()
            }
        }
    }
    
    @available(iOS 17.0, *)
    @MainActor
    func handleSelectedTabChange() async {
        let subject = uiServiceRegistry.tabsSubject
        let tabId = subject.selectedTabId
        guard let index = subject.tabs
            .firstIndex(where: { $0.id == tabId }) else {
            return
        }
        await tabDidSelect(index, subject.tabs[index].contentType, tabId)
    }

    @available(iOS 17.0, *)
    @MainActor
    func handleTabsCountChange() async {
        let subject = uiServiceRegistry.tabsSubject
        await counterView.updateTabsCount(with: subject.tabsCount)
    }
}

// MARK: - TabsObserver

extension BrowserToolbarView: TabsObserver {
    func tabDidSelect(
        _ index: Int,
        _ content: CoreBrowser.Tab.ContentType,
        _ identifier: UUID
    ) async {
        switch content {
        case .site:
            updateToolbar(downloadsAvailable: false, actionsAvailable: true)
        default:
            // allow to show actions even for top sites view
            // to be able for user to get to global settings
            updateToolbar(downloadsAvailable: false, actionsAvailable: true)
        }
    }
}
