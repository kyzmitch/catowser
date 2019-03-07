//
//  MasterBrowserViewController.swift
//  catowser
//
//  Created by Andrey Ermoshin on 27/09/2017.
//  Copyright © 2017 andreiermoshin. All rights reserved.
//

import UIKit
import ReactiveSwift
import CoreBrowser

/// An interface for component which suppose to render tabs
///
/// Class protocol is used because object gonna be stored by `weak` ref
/// `AnyObject` is new name for it, but will use old one to find when XCode
/// will start mark it as deprecated.
/// https://forums.swift.org/t/class-only-protocols-class-vs-anyobject/11507/4
protocol TabRendererInterface: AnyViewController {
    func open(tabContent: Tab.ContentType)
}

final class MasterBrowserViewController: BaseViewController {

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let searchSuggestClient: SearchSuggestClient = {
        // TODO: implement parsing e.g. google.xml
        guard let sEngine = try? OpenSearchParser.parse("", engineID: "") else {
            return SearchSuggestClient(.googleEngine)
        }
        let client = SearchSuggestClient(sEngine)
        return client
    }()
    
    /// Tabs list without previews. Needed only for tablets or landscape mode.
    private lazy var tabsViewController: TabsViewController = {
        let viewController = TabsViewController()
        return viewController
    }()
    
    private lazy var searchBarController: AnyViewController & SearchBarControllerInterface = {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return TabletSearchBarViewController(self)
        } else {
            return SmartphoneSearchBarViewController(self)
        }
    }()

    private let searchSuggestionsController: SearchSuggestionsViewController = {
        let vc = SearchSuggestionsViewController()
        return vc
    }()

    private var isSuggestionsShowed: Bool = false

    /// The view controller to manage blank tab, possibly will be enhaced
    /// to support favorite sites list.
    private let blankWebPageController = BlankWebPageViewController()

    /// The view needed to hold tab content like WebView or favorites table view.
    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = .black
        return v
    }()
    
    private var keyboardHeight: CGFloat?

    /// The controller for toolbar buttons. Used only for compact sizes/smartphones.
    private lazy var toolbarViewController: WebBrowserToolbarController = {
        let router = ToolbarRouter(presenter: self)
        let toolbar = WebBrowserToolbarController(router: router)
        return toolbar
    }()

    /// View to make color under toolbar is the same on iPhone x without home button
    private lazy var underToolbarView: UIView = {
        let v = UIView()
        ThemeProvider.shared.setupUnderToolbar(v)
        return v
    }()

    /// Dynamicly determined height because it can be different before layout finish it's work
    private var toolbarHeight: CGFloat {
        return toolbarViewController.view.bounds.size.height + underToolbarView.bounds.size.height
    }

    /// The current holder for WebView (controller) if browser has at least one
    private var currentWebViewController: WebViewController?

    private var disposables = [Disposable?]()

    private var searchSuggestionsDisposable: Disposable?

    private let tabsControllerAdded: Bool = UIDevice.current.userInterfaceIdiom == .pad ? true : false

    /// Not initialized, will be initialized after `TabsListManager`
    /// during tab opening. Used only during tab opening for optimization
    private var currentTabContent: Tab.ContentType?
    
    override func loadView() {
        // Your custom implementation of this method should not call super.
        view = UIView()
        
        // In that method, create your view hierarchy programmatically and assign
        // the root view of that hierarchy to the view controller’s view property.
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            add(asChildViewController: tabsViewController, to:view)
        }

        add(asChildViewController: searchBarController.viewController, to:view)
        view.addSubview(containerView)

        if UIDevice.current.userInterfaceIdiom == .phone {
            add(asChildViewController: toolbarViewController, to:view)
            // Need to not add it if it is not iPhone without home button
            view.addSubview(underToolbarView)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.white
        
        if tabsControllerAdded {
            tabsViewController.view.snp.makeConstraints { (maker) in
                // https://github.com/SnapKit/SnapKit/issues/448
                // https://developer.apple.com/documentation/uikit/uiviewcontroller/1621367-toplayoutguide
                // https://developer.apple.com/documentation/uikit/uiview/2891102-safearealayoutguide
                
                if #available(iOS 11, *) {
                    maker.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin)
                } else {
                    maker.top.equalTo(view)
                }
                
                maker.leading.equalTo(view)
                maker.trailing.equalTo(view)
                maker.height.equalTo(UIConstants.tabHeight)
            }
            
            searchBarController.view.snp.makeConstraints({ (maker) in
                maker.top.equalTo(tabsViewController.view.snp.bottom)
                maker.leading.equalTo(view)
                maker.trailing.equalTo(view)
                maker.height.equalTo(UIConstants.searchViewHeight)
            })
            
            // Need to have not simple view controller view but container view
            // to have ability to insert to it and show view controller with
            // bookmarks in case if search bar has no any address entered or
            // webpage controller with web view if some address entered in search bar
            containerView.snp.makeConstraints { (maker) in
                maker.top.equalTo(searchBarController.view.snp.bottom)
                maker.leading.equalTo(view)
                maker.trailing.equalTo(view)
                maker.bottom.equalTo(view)
            }
        } else {
            searchBarController.view.snp.makeConstraints({ (maker) in
                if #available(iOS 11, *) {
                    maker.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin)
                } else {
                    maker.top.equalTo(view)
                }
                
                maker.leading.equalTo(view)
                maker.trailing.equalTo(view)
                maker.height.equalTo(UIConstants.searchViewHeight)
            })
            
            containerView.snp.makeConstraints { (maker) in
                maker.top.equalTo(searchBarController.view.snp.bottom)
                maker.bottom.equalTo(toolbarViewController.view.snp.top)
                maker.leading.equalTo(view)
                maker.trailing.equalTo(view)
            }
            
            toolbarViewController.view.snp.makeConstraints({ (maker) in
                maker.top.equalTo(containerView.snp.bottom)
                maker.leading.equalTo(view)
                maker.trailing.equalTo(view)
                maker.height.equalTo(UIConstants.tabBarHeight)

                if #available(iOS 11, *) {
                    maker.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
                } else {
                    maker.bottom.equalTo(view)
                }
            })

            underToolbarView.snp.makeConstraints { (maker) in
                maker.top.equalTo(toolbarViewController.view.snp.bottom)
                maker.leading.equalTo(view)
                maker.trailing.equalTo(view)
                maker.bottom.equalTo(view.snp.bottom)
            }
        }

        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: nil, using: keyboardWillHideClosure())

        let disposeA = NotificationCenter.default.reactive
            .notifications(forName: UIResponder.keyboardDidChangeFrameNotification)
            .observe(on: UIScheduler())
            .observeValues {[weak self] notification in
                self?.keyboardWillChangeFrameClosure()(notification)
        }

        disposables.append(disposeA)

        TabsListManager.shared.attach(self)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        get {
            return ThemeProvider.shared.theme.statusBarStyle
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }

    deinit {
        TabsListManager.shared.detach(self)
        disposables.forEach { $0?.dispose() }
        searchSuggestionsDisposable?.dispose()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}

extension MasterBrowserViewController: TabRendererInterface {
    func open(tabContent: Tab.ContentType) {
        if let currentType = currentTabContent, currentType == tabContent {
            print("same site")
            return
        }

        switch tabContent {
        case .site(let site):
            guard let webViewController = try? WebViewsReuseManager.shared.getControllerFor(site) else {
                return
            }

            updateSiteNavigator(to: webViewController)
            currentWebViewController?.removeFromChild()
            blankWebPageController.removeFromChild()
            add(asChildViewController: webViewController, to: containerView)
            webViewController.view.snp.makeConstraints { make in
                make.left.right.top.bottom.equalTo(containerView)
            }
        default:
            updateSiteNavigator(to: nil)
            searchBarController.changeState(to: .blankSearch, animated: true)
            currentWebViewController?.removeFromChild()
            add(asChildViewController: blankWebPageController, to: containerView)
            blankWebPageController.view.snp.makeConstraints { maker in
                maker.left.right.top.bottom.equalTo(containerView)
            }
            break
        }
    }
}

extension MasterBrowserViewController {
    private func keyboardWillChangeFrameClosure() -> (Notification) -> Void {
        func handling(_ notification: Notification) {
            guard let info = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] else { return }
            guard let value = info as? NSValue else { return }
            let rect = value.cgRectValue
            
            print("\(#function): keyboard will show with height \(rect.size.height)")
            // need to reduce search suggestions list height
            keyboardHeight = rect.size.height
        }
        
        return handling
    }
    
    private func keyboardWillHideClosure() -> (Notification) -> Void {
        func handling(_ notification: Notification) {
            print("\(#function): keyboard will hide")
            keyboardHeight = nil
        }
        
        return handling
    }
}

private extension MasterBrowserViewController {
    func navigationComponent() -> SiteNavigationComponent? {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return toolbarViewController
        } else if let tabletVc = searchBarController as? SiteNavigationComponent {
            // complex type casting
            return tabletVc
        }
        return nil
    }

    func showSearchControllerIfNeeded() {
        guard !isSuggestionsShowed else {
            return
        }

        add(asChildViewController: searchSuggestionsController, to: view)
        isSuggestionsShowed = true
        searchSuggestionsController.delegate = self
        searchSuggestionsController.view.translatesAutoresizingMaskIntoConstraints = false
        searchSuggestionsController.view.topAnchor.constraint(equalTo: searchBarController.view.bottomAnchor, constant: 0).isActive = true
        searchSuggestionsController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
        searchSuggestionsController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
        
        if let bottomShift = keyboardHeight {
            // fix wrong height of keyboard on Simulator when keyboard partly visible
            let correctedShift = bottomShift < toolbarHeight ? toolbarHeight : bottomShift
            searchSuggestionsController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -correctedShift).isActive = true
        } else {
            if tabsControllerAdded {
                searchSuggestionsController.view.bottomAnchor.constraint(equalTo: toolbarViewController.view.topAnchor, constant: 0).isActive = true
            } else {
                searchSuggestionsController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
            }
        }
    }

    func hideSearchController() {
        guard isSuggestionsShowed else {
            print("Attempted to hide suggestions when they are not showed")
            return
        }

        searchSuggestionsController.willMove(toParent: nil)
        searchSuggestionsController.removeFromParent()
        // remove view and constraints
        searchSuggestionsController.view.removeFromSuperview()
        searchSuggestionsController.suggestions = [String]()

        isSuggestionsShowed = false
    }

    func startSearch(_ searchText: String) {
        searchSuggestionsDisposable?.dispose()
        searchSuggestionsDisposable = searchSuggestClient.suggestionsProducer(basedOn: searchText)
            .observe(on: UIScheduler())
            .startWithResult { [weak self] result in
                switch result {
                case .success(let suggestions):
                    self?.searchSuggestionsController.suggestions = suggestions
                    break
                case .failure:
                    break
                }
        }
    }
}

extension MasterBrowserViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            hideSearchController()
        } else {
            showSearchControllerIfNeeded()
            // TODO: How to delay network request
            // https://stackoverflow.com/a/2471977/483101
            // or using Reactive api
            startSearch(searchText)
        }
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBarController.changeState(to: .startSearch, animated: true)
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        hideSearchController()
        searchBar.resignFirstResponder()
        searchBarController.changeState(to: .cancelTapped, animated: true)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // need to open web view with url of search engine
        // and specific search queue
        guard let suggestion = searchBar.text else {

            return
        }
        didSelect(suggestion)
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        // called when `Cancel` pressed or search bar no more a first responder
    }
}

extension MasterBrowserViewController: SearchSuggestionsListDelegate {
    func didSelect(_ suggestion: String) {
        guard let url = searchSuggestClient.searchURL(basedOn: suggestion) else {
            return
        }
        hideSearchController()
        let site = Site(url: url, searchSuggestion: suggestion)

        if let currentTab = try? TabsListManager.shared.selectedTab() {
            var updatedTab = currentTab
            updatedTab.contentType = .site(site)
            do {
                try TabsListManager.shared.replaceSelectedTab(with: updatedTab)
                open(tabContent: updatedTab.contentType)
            } catch {
                print("Failed to replace current tab")
            }
        } else {
            // Most likely this code never will be triggered because always one selected tab is availbale
            fatalError("Can't found selected tab to replace it")
        }
    }
}

extension MasterBrowserViewController: TabsObserver {
    func didSelect(index: Int, content: Tab.ContentType) {
        open(tabContent: content)
    }

    func tabDidReplace(_ tab: Tab, at index: Int) {
        // need update navigation if the same tab was updated
        reloadNavigationElements()
    }
}

extension MasterBrowserViewController: SiteNavigationComponent {
    func updateSiteNavigator(to navigator: SiteNavigationDelegate?) {
        navigationComponent()?.updateSiteNavigator(to: navigator)
    }

    func reloadNavigationElements() {
        navigationComponent()?.reloadNavigationElements()
    }
}
