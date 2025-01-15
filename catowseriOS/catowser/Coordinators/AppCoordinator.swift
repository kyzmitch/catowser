//
//  AppCoordinator.swift
//  catowser
//
//  Created by Andrey Ermoshin on 13.11.2022.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import UIKit
import CoreBrowser
import CottonBase
import FeatureFlagsKit
import CottonPlugins
import CottonViewModels
import CottonDataServices

final class AppCoordinator: Coordinator, ContentCoordinatorsInterface, PluginsProxyDelegate {
    /// Could be accessed using `ViewsEnvironment.shared.vcFactory` singleton as well
    let vcFactory: ViewControllerFactory
    /// Currently presented (next) coordinator, to be able to stop it
    var startedCoordinator: Coordinator?
    /// Root coordinator doesn't have any parent
    weak var parent: CoordinatorOwner?
    /// This specific coordinator starts root view controller
    var startedVC: AnyViewController?
    /// There is no presenter view controller in App/root coordinator
    weak var presenterVC: AnyViewController?
    /// navigation view controller needed for some coordinators
    var navigationStack: UINavigationController?

    /// Progress view coordinator
    private var loadingProgressCoordinator: LoadingProgressCoordinator?
    /// Web content container coordinator
    private var webContentContainerCoordinator: (any Layouting)?
    /// Search bar coordinator
    private var searchBarCoordinator: SearchBarCoordinator?
    /// Specific link for tags coordinator
    private var linkTagsCoordinator: LinkTagsCoordinator?
    /// Dummy view coordinator
    private var bottomViewCoordinator: (any Layouting)?
    /// blank content vc
    private var blankContentCoordinator: (any Navigating)?
    /// Only needed on Tablet
    private var tabletTabsCoordinator: (any Layouting)?
    /// App window rectangle
    private let windowRectangle: CGRect = {
        CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
    }()
    /// main app window
    private lazy var window: UIWindow = {
        UIWindow(frame: windowRectangle)
    }()
    /// Not initialized, will be initialized after `TabsListManager`
    /// during tab opening. Used only during tab opening for optimization
    private var previousTabContent: CoreBrowser.Tab.ContentType?
    /// Not a constant because can't be initialized in init
    private var jsPluginsBuilder: (any JSPluginsSource)?

    /// Need to update this navigation delegate each time it changes,
    /// each time when new tab become visible, we have to set interface
    /// to a new web view associated with that tab.
    private weak var currentTabWebViewInterface: WebViewNavigatable?
    /// Web site navigation delegate
    private var navigationComponent: FullSiteNavigationComponent? {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return vcFactory.createdToolbaViewController as? FullSiteNavigationComponent
        } else {
            return vcFactory.createdDeviceSpecificSearchBarVC as? FullSiteNavigationComponent
        }
    }

    /// UI framework type
    var uiFramework: UIFrameworkType {
        appStartInfo.uiFramework
    }
    /// App start info (including view models and other data)
    private let appStartInfo: AppStartInfo
    /// Feature manager
    private let featureManager: FeatureManager.StateHolder
    /// UI service registry
    private let uiServiceRegistry: UIServiceRegistry
    /// Plugins handler
    private let pluginsDelegate: PluginsProxy

    init(
        _ vcFactory: ViewControllerFactory,
        _ featureManager: FeatureManager.StateHolder,
        _ uiServiceRegistry: UIServiceRegistry,
        _ pluginsDelegate: PluginsProxy,
        _ appStartInfo: AppStartInfo
    ) {
        self.vcFactory = vcFactory
        self.featureManager = featureManager
        self.uiServiceRegistry = uiServiceRegistry
        self.pluginsDelegate = pluginsDelegate
        self.appStartInfo = appStartInfo
        pluginsDelegate.delegate = self
    }

    func start() {
        let allTabsVM = appStartInfo.allTabsVM
        let topSitesVM = appStartInfo.topSitesVM
        let suggestionsVM = appStartInfo.suggestionsVM
        let webViewModel = appStartInfo.webViewModel
        let searchBarVM = appStartInfo.searchBarVM
        let vc = vcFactory.rootViewController(
            self,
            uiFramework,
            appStartInfo.defaultTabContent,
            allTabsVM,
            topSitesVM,
            suggestionsVM,
            webViewModel,
            searchBarVM
        )
        startedVC = vc
        
        window.rootViewController = startedVC?.viewController
        window.makeKeyAndVisible()
        // we need to attach observer only after adding all child coordinators
        if case .uiKit = uiFramework {
            Task {
                if #available(iOS 17.0, *), appStartInfo.observingType.isSystemObservation {
                    startTabsObservation()
                    await readTabsState()
                } else {
                    await ServiceRegistry.shared.tabsService.attach(self, notify: true)
                }
            }
        }
        if uiFramework.swiftUIBased {
            // Must do coordinators init earlier
            // to allow to use some of them in SwiftUI views
            insertTopSites()
            insertToolbar()
            if uiFramework.isUIKitFree {
                // Need to create PhoneTabs coordinator as well
                toolbarCoordinator?.showNext(.tabs)
            }
        }
    }
    
    @available(iOS 17.0, *)
    @MainActor
    private func startTabsObservation() {
        withObservationTracking {
            _ = uiServiceRegistry.tabsSubject.selectedTabId
        } onChange: {
            Task { [weak self] in
                await self?.handleTabSelection()
            }
        }
        withObservationTracking {
            _ = uiServiceRegistry.tabsSubject.replacedTabIndex
        } onChange: {
            Task { [weak self] in
                await self?.handleTabReplace()
            }
        }
    }
    
    @available(iOS 17.0, *)
    private func readTabsState() async {
        await handleTabSelection()
    }
    
    @available(iOS 17.0, *)
    @MainActor
    private func handleTabSelection() async {
        let subject = uiServiceRegistry.tabsSubject
        guard subject.tabsCount > 0 else {
            fatalError("Browser always should have at least 1 tab")
        }
        let tabId = subject.selectedTabId
        let selectedIndex = subject.tabs.firstIndex(where: { $0.id == tabId })
        if selectedIndex == nil {
            print("Error: unknown selected tab")
        }
        let index = selectedIndex ?? subject.tabs.startIndex
        await tabDidSelect(index, subject.tabs[index].contentType, tabId)
    }
    
    @available(iOS 17.0, *)
    @MainActor
    private func handleTabReplace() async {
        let subject = uiServiceRegistry.tabsSubject
        guard let index = subject.replacedTabIndex else {
            return
        }
        await tabDidReplace(subject.tabs[index], at: index)
    }

    // MARK: - BrowserContentCoordinators

    /// Coordinator for inserted child view controller. public for SwiftUI
    var topSitesCoordinator: TopSitesCoordinator?
    /// web view coordinator
    var webContentCoordinator: WebContentCoordinator?
    /// Global menu delegate
    var globalMenuDelegate: GlobalMenuDelegate? {
        self
    }
    /// Phone toolbar coordinator which should stay forever
    var toolbarCoordinator: MainToolbarCoordinator?
    /// Later initialized root view controller
    var toolbarPresenter: AnyViewController? {
        startedVC
    }
}

// MARK: - CoordinatorOwner

extension AppCoordinator: CoordinatorOwner {
    func coordinatorDidFinish(_ coordinator: Coordinator) {
        if coordinator === startedCoordinator {
            // GlobalMenuCoordinator is stored as started which is good
            startedCoordinator = nil
            return
        }
        // Now check layout related coordinators
        if coordinator === topSitesCoordinator {
            topSitesCoordinator = nil
            return
        } else if coordinator === blankContentCoordinator {
            blankContentCoordinator = nil
            return
        } else if coordinator === webContentCoordinator {
            webContentCoordinator = nil
            return
        }
    }
}

// MARK: - MainScreenRoute type

enum MainScreenRoute: Route {
    case menu(MenuViewModel, UIView, CGRect)
    case openTab(CoreBrowser.Tab.ContentType)
}

// MARK: - Navigating

extension AppCoordinator: Navigating {
    typealias R = MainScreenRoute

    func showNext(_ route: R) {
        switch route {
        case .menu(let model, let sourceView, let sourceRect):
            startMenu(model, sourceView, sourceRect)
        case .openTab(let content):
            open(tabContent: content)
        }
    }

    func stop() {
        // Probably it is not necessary because this is a root
        jsPluginsBuilder = nil
        // Next line is actually useless, because it is a root coordinator
        parent?.coordinatorDidFinish(self)
    }
}

// MARK: - MainScreenSubview type

enum MainScreenSubview: SubviewPart {
    case tabs
    case searchBar
    case loadingProgress
    case webContentContainer
    case filesGrid
    case linkTags
    case toolbar
    case dummyView
}

// MARK: - Layouting

extension AppCoordinator: Layouting {
    typealias SP = MainScreenSubview

    func insertNext(_ subview: SP) {
        switch subview {
        case .tabs:
            insertTabs()
        case .searchBar:
            insertSearchBar()
        case .loadingProgress:
            insertLoadingProgress()
        case .webContentContainer:
            insertWebContentContainer()
        case .toolbar:
            insertToolbar()
        case .dummyView:
            insertDummyView()
        case .linkTags:
            insertLinkTags()
        case .filesGrid:
            insertFilesGrid()
        }
    }

    func layout(_ step: OwnLayoutStep) {
        // Could do root layout here instead of view controller
    }

    // swiftlint:disable:next cyclomatic_complexity
    func layoutNext(_ step: LayoutStep<SP>) {
        switch step {
        case .viewDidLoad(let subview, _, _, _):
            switch subview {
            case .tabs:
                tabsViewDidLoad()
            case .searchBar:
                searchBarViewDidLoad()
            case .loadingProgress:
                loadingProgressViewDidLoad()
            case .webContentContainer:
                webContentContainerViewDidLoad()
            case .toolbar:
                toolbarViewDidLoad()
            case .dummyView:
                dummyViewDidLoad()
            case .linkTags:
                linkTagsViewDidLoad()
            case .filesGrid:
                filesGridViewDidLoad()
            }
        case .viewDidLayoutSubviews(let subview, _):
            switch subview {
            case .filesGrid:
                filesGridViewDidLayoutSubviews()
            default:
                break
            }
        case .viewSafeAreaInsetsDidChange(let subview):
            switch subview {
            case .dummyView:
                dummyViewSafeAreaInsetsDidChange()
            default:
                break
            }
        }
    }
}

// MARK: - SiteNavigationComponent

extension AppCoordinator: SiteNavigationComponent {
    func reloadNavigationElements(_ withSite: Bool, downloadsAvailable: Bool = false) {
        navigationComponent?.reloadNavigationElements(withSite, downloadsAvailable: downloadsAvailable)
    }

    var siteNavigator: WebViewNavigatable? {
        get {
            return nil
        }
        set(newValue) {
            navigationComponent?.siteNavigator = newValue
            currentTabWebViewInterface = newValue
        }
    }
}

// MARK: - InstagramContentDelegate

extension AppCoordinator: InstagramContentDelegate {
    func didReceiveVideoNodes(_ nodes: [InstagramVideoNode]) {
        linkTagsCoordinator?.showNext(.openInstagramTags(nodes))
        reloadNavigationElements(true, downloadsAvailable: true)
    }
}

// MARK: - BasePluginContentDelegate

extension AppCoordinator: BasePluginContentDelegate {
    func didReceiveVideoTags(_ tags: [HTMLVideoTag]) {
        linkTagsCoordinator?.showNext(.openHtmlTags(tags))
        reloadNavigationElements(true, downloadsAvailable: true)
    }
}

private extension AppCoordinator {

    // MARK: - insert methods to start subview coordinators

    func insertTabs() {
        guard isPad else {
            return
        }
        // swiftlint:disable:next force_unwrapping
        let presenter = startedVC!
        let coordinator: TabletTabsCoordinator = .init(vcFactory, presenter, appStartInfo.allTabsVM)
        coordinator.parent = self
        coordinator.start()
        tabletTabsCoordinator = coordinator
    }

    func insertSearchBar() {
        // swiftlint:disable:next force_unwrapping
        let presenter = startedVC!
        // Link tags coordinator MUST be initialized before Search bar
        // to have a reference to a delegate for it
        linkTagsCoordinator = LinkTagsCoordinator(vcFactory, presenter)
        linkTagsCoordinator?.parent = self

        let coordinator = SearchBarCoordinator(
            vcFactory,
            presenter,
            linkTagsCoordinator,
            self,
            self,
            uiFramework,
            appStartInfo.searchDataService,
            appStartInfo.searchBarVM
        )
        coordinator.parent = self
        coordinator.start()
        searchBarCoordinator = coordinator

        // The easiest way to pass the presenter which is Tablet search bar view controller.
        // Also, need to make sure that search bar coordinator was started before
        // this link tags coordinator to have a view controller initialized in vc factory
        linkTagsCoordinator?.mediaLinksPresenter = vcFactory.createdDeviceSpecificSearchBarVC as? MediaLinksPresenter
    }

    func insertLoadingProgress() {
        // swiftlint:disable:next force_unwrapping
        let presenter = startedVC!
        let coordinator: LoadingProgressCoordinator = .init(vcFactory, presenter)
        coordinator.parent = self
        coordinator.start()
        loadingProgressCoordinator = coordinator
    }

    func insertWebContentContainer() {
        // swiftlint:disable:next force_unwrapping
        let presenter = startedVC!
        let coordinator: WebContentContainerCoordinator = .init(vcFactory, presenter)
        coordinator.parent = self
        coordinator.start()
        webContentContainerCoordinator = coordinator
    }

    func insertFilesGrid() {
        linkTagsCoordinator?.insertNext(.filesGrid)
    }

    func insertLinkTags() {
        linkTagsCoordinator?.start()
    }

    func insertToolbar() {
        guard !isPad else {
            return
        }
        guard toolbarCoordinator == nil else {
            return
        }
        let presenter = startedVC
        // Link tags coordinator MUST be initialized before this toolbar
        // and it is initialized before Search bar coordinator now
        let coordinator: MainToolbarCoordinator = .init(
            vcFactory,
            presenter,
            linkTagsCoordinator,
            self,
            uiFramework,
            appStartInfo.phoneTabPreviewsVM
        )
        coordinator.parent = self
        coordinator.start()
        toolbarCoordinator = coordinator
    }

    func insertDummyView() {
        // swiftlint:disable:next force_unwrapping
        let presenter = startedVC!
        let coordinator: BottomViewCoordinator = .init(vcFactory, presenter)
        coordinator.parent = self
        coordinator.start()
        bottomViewCoordinator = coordinator
    }

    func insertTopSites() {
        guard topSitesCoordinator == nil else {
            return
        }
        let coordinator: TopSitesCoordinator
        switch uiFramework {
        case .uiKit:
            guard let containerView = webContentContainerCoordinator?.startedView else {
                assertionFailure("Root view controller must have content view")
                return
            }
            coordinator = .init(
                vcFactory,
                startedVC,
                containerView,
                uiFramework,
                appStartInfo.topSitesVM
            )
        case .swiftUIWrapper, .swiftUI:
            coordinator = .init(
                vcFactory,
                startedVC,
                nil,
                uiFramework,
                appStartInfo.topSitesVM
            )
        }

        coordinator.parent = self
        coordinator.start()
        topSitesCoordinator = coordinator
    }

    func insertBlankTab() {
        guard let containerView = webContentContainerCoordinator?.startedView else {
            assertionFailure("Root view controller must have content view")
            return
        }
        // swiftlint:disable:next force_unwrapping
        let presenter = startedVC!
        let coordinator: BlankContentCoordinator = .init(vcFactory, presenter, containerView)
        coordinator.parent = self
        coordinator.start()
        blankContentCoordinator = coordinator
    }

    func insertWebTab(_ site: Site) {
        switch uiFramework {
        case .uiKit:
            guard let containerView = webContentContainerCoordinator?.startedView else {
                assertionFailure("Root view controller must have content view")
                return
            }
            // swiftlint:disable:next force_unwrapping
            let presenter = startedVC!
            let coordinator: WebContentCoordinator = .init(vcFactory,
                                                           presenter,
                                                           containerView,
                                                           self,
                                                           site,
                                                           appStartInfo.jsPluginsBuilder,
                                                           uiFramework)
            coordinator.parent = self
            let context: WebViewContextImpl = .init(appStartInfo.jsPluginsBuilder)
            /// It is fine to do async coordinator start in this specific case
            /// first because it requires new Site every time
            /// second, layout is done in scope of start, so, coordinator won't be nil during layout request
            Task {
                /// Need to do init of view model from outside, because `start` needs to be synhronious to be able to get non nil `startedVC`
                let viewModel = await ViewModelFactory.shared.getWebViewModel(site, context, coordinator)
                coordinator.viewModel = viewModel
                coordinator.start()
                // Set new interface after starting, it is new for every site/webView
                siteNavigator = coordinator.startedVC as? WebViewNavigatable
                webContentCoordinator = coordinator
            }
        case .swiftUIWrapper, .swiftUI:
            break
        }
    }

    // MARK: - view did load

    func tabsViewDidLoad() {
        guard isPad else {
            return
        }
        tabletTabsCoordinator?.layout(.viewDidLoad())
    }

    func searchBarViewDidLoad() {
        // use specific bottom anchor when it is Tablet layout
        // and the most top view is not a superview but tabs view
        // if it is a Phone layout then topAnchor can be taken
        // easily from presenter
        let topAnchor = tabletTabsCoordinator?.startedView?.bottomAnchor
        searchBarCoordinator?.layout(.viewDidLoad(topAnchor))
    }

    func loadingProgressViewDidLoad() {
        let topAnchor = searchBarCoordinator?.startedVC?.controllerView.bottomAnchor
        loadingProgressCoordinator?.layout(.viewDidLoad(topAnchor))
    }

    func filesGridViewDidLoad() {
        linkTagsCoordinator?.layoutNext(.viewDidLoad(.filesGrid))
    }

    func webContentContainerViewDidLoad() {
        let topAnchor = loadingProgressCoordinator?.startedVC?.controllerView.bottomAnchor
        // Web content bottom border depends on device layout
        // for Phone layout it should be a toolbar,
        // for Tablet layout it should be a bottom dummy view

        // Below used coordinators MUST be started to be able to provide bottom anchors,
        // but it is not possible at this time, so that,
        // bottom dummy or toolbar view should use web content container view bottom anchor
        // MUST be attached later during layout of toolbar or dummy coordinators
        webContentContainerCoordinator?.layout(.viewDidLoad(topAnchor))
    }

    func toolbarViewDidLoad() {
        let topAnchor = webContentContainerCoordinator?.startedView?.bottomAnchor
        toolbarCoordinator?.layout(.viewDidLoad(topAnchor, nil))
    }

    func dummyViewDidLoad() {
        // top anchor is different on Tablet it is web content container bottom anchor
        // and on Phone it is toolbar bottom anchor
        let topAnchor: NSLayoutYAxisAnchor?
        if isPad {
            // maybe on Tablet it is better just to use super view bottom anchor
            topAnchor = webContentContainerCoordinator?.startedView?.bottomAnchor
        } else {
            topAnchor = toolbarCoordinator?.startedView?.bottomAnchor
        }
        bottomViewCoordinator?.layout(.viewDidLoad(topAnchor))
    }

    func linkTagsViewDidLoad() {
        let bottomAnchor: NSLayoutYAxisAnchor?
        if isPad {
            // bottom dummy view top or root view bottom
            // bottomViewCoordinator?.startedView?.topAnchor
            bottomAnchor = startedView?.bottomAnchor
        } else {
            bottomAnchor = toolbarCoordinator?.startedView?.topAnchor
        }
        linkTagsCoordinator?.layout(.viewDidLoad(nil, bottomAnchor))
    }

    // MARK: - lifecycle navigation methods

    func startMenu(_ model: MenuViewModel, _ sourceView: UIView, _ sourceRect: CGRect) {
        let presenter: UIViewController?
        if case .uiKit = uiFramework {
            presenter = vcFactory.createdDeviceSpecificSearchBarVC
        } else {
            presenter = startedVC?.viewController
        }
        let coordinator: GlobalMenuCoordinator = .init(vcFactory, presenter, model, sourceView, sourceRect)
        coordinator.parent = self
        coordinator.start()
        // Using standart child property, because normal navigation
        // would be used and not a subview layout
        startedCoordinator = coordinator
    }

    func open(tabContent: CoreBrowser.Tab.ContentType) {
        linkTagsCoordinator?.showNext(.closeTags)
        // hide suggestions as well
        searchBarCoordinator?.showNext(.hideSuggestions)

        if let previousValue = previousTabContent, previousValue.isStatic && previousValue == tabContent {
            // Optimization to not do remove & insert of the same static view
            return
        }

        switch previousTabContent {
        case .site:
            webContentCoordinator?.stop()
        case .topSites:
            topSitesCoordinator?.stop()
        default:
            blankContentCoordinator?.stop()
        }

        switch tabContent {
        case .site(let site):
            // need to display progress view before load start
            loadingProgressCoordinator?.showNext(.showProgress(true))
            insertWebTab(site)
        case .topSites:
            siteNavigator = nil
            // No need to notify searchBar, because it is `TabsObserver` too.
            // See https://github.com/kyzmitch/Cotton/issues/51
            insertTopSites()
        default:
            siteNavigator = nil
            // No need to notify searchBar, because it is `TabsObserver` too
            // See https://github.com/kyzmitch/Cotton/issues/51
            insertBlankTab()
        }

        previousTabContent = tabContent
    }

    // MARK: - safe area insets

    func dummyViewSafeAreaInsetsDidChange() {
        bottomViewCoordinator?.layout(.viewSafeAreaInsetsDidChange)
    }

    // MARK: - did layout subviews

    func filesGridViewDidLayoutSubviews() {
        // Files grid view height depends on web content view height,
        // search bar view should still be visible when files grid
        // become visible, that is why we need to calculate good enough
        // height of files grid view
        let containerHeight = webContentContainerCoordinator?.startedView?.bounds.height
        linkTagsCoordinator?.layoutNext(.viewDidLayoutSubviews(.filesGrid, containerHeight))
    }
}

// MARK: - TabsObserver

extension AppCoordinator: TabsObserver {
    func tabDidSelect(
        _ index: Int,
        _ content: CoreBrowser.Tab.ContentType,
        _ identifier: UUID
    ) async {
        open(tabContent: content)
    }

    func tabDidReplace(_ tab: CoreBrowser.Tab, at index: Int) async {
        switch previousTabContent {
        case .site:
            break
        default:
            open(tabContent: tab.contentType)
        }

        // need update navigation if the same tab was updated
        let withSite: Bool
        if case .site = tab.contentType {
            withSite = true
        } else {
            withSite = false
        }

        linkTagsCoordinator?.showNext(.closeTags)
        reloadNavigationElements(withSite)
    }
}

extension AppCoordinator: GlobalMenuDelegate {
    func settingsDidPress(from sourceView: UIView, and sourceRect: CGRect) {
        let style: BrowserMenuStyle
        if let interface = currentTabWebViewInterface {
            style = .withSiteMenu(interface.host, interface.siteSettings)
        } else {
            style = .onlyGlobalMenu
        }
        Task {
            async let isDohEnabled = featureManager.boolValue(of: .dnsOverHTTPSAvailable)
            async let isJavaScriptEnabled = featureManager.boolValue(of: .javaScriptEnabled)
            async let nativeAppRedirectEnabled = featureManager.boolValue(of: .nativeAppRedirect)
            let menuModel = await MenuViewModel(
                style,
                isDohEnabled,
                isJavaScriptEnabled,
                nativeAppRedirectEnabled
            )
            menuModel.developerMenuPresenter = self
            showNext(.menu(menuModel, sourceView, sourceRect))
        }
    }
}

extension AppCoordinator: WebContentDelegate {
    func provisionalNavigationDidStart() {
        linkTagsCoordinator?.showNext(.closeTags)
    }

    func loadingProgressdDidChange(_ progress: Float) {
        loadingProgressCoordinator?.showNext(.setProgress(progress, false))
    }

    func showLoadingProgress(_ show: Bool) {
        loadingProgressCoordinator?.showNext(.showProgress(show))
        loadingProgressCoordinator?.showNext(.setProgress(0, false))
    }
}

extension AppCoordinator: SearchBarDelegate {
    func openTab(_ content: CoreBrowser.Tab.ContentType) {
        showNext(.openTab(content))
    }

    func layoutSuggestions() {
        // Pass top and bottom anchors and toolbar height
        let topAnchor = searchBarCoordinator?.startedVC?.controllerView.bottomAnchor
        let bottomAnchor: NSLayoutYAxisAnchor?
        if isPad {
            // Probably better to use bottom dummy view anchor
            // bottomViewCoordinator?.startedView?.topAnchor
            bottomAnchor = startedVC?.controllerView.bottomAnchor
        } else {
            // Toolbar is only on Phone layout
            bottomAnchor = toolbarCoordinator?.startedView?.topAnchor
        }
        let toolbarHeight = toolbarCoordinator?.startedView?.bounds.height
        // Not used, can be random
        searchBarCoordinator?.layoutNext(.viewDidLoad(.simplySuggestions,
                                                      topAnchor,
                                                      bottomAnchor,
                                                      toolbarHeight))
    }
}

extension AppCoordinator: DeveloperMenuPresenter {
    func emulateLinkTags() {
        // swiftlint:disable:next force_unwrapping
        let url1 = URL(string: "https://www.mozilla.org/media/img/favicons/mozilla/apple-touch-icon.8cbe9c835c00.png")!
        // swiftlint:disable:next force_unwrapping
        let url2 = URL(string: "https://www.opennet.ru/opennet_120.png")!
        let tag1: HTMLVideoTag = .init(srcURL: url1, posterURL: url1, name: "example 1")
        let tag2: HTMLVideoTag = .init(srcURL: url2, posterURL: url2, name: "example 2")
        let tags: [HTMLVideoTag] = [tag1, tag2]
        didReceiveVideoTags(tags)
    }

    func host(_ host: Host, willUpdateJsState enabled: Bool) {
        webContentCoordinator?.showNext(.javaScript(enabled, host))
    }

    // swiftlint:disable:next file_length
}
