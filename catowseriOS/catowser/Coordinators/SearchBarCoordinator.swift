//
//  SearchBarCoordinator.swift
//  catowser
//
//  Created by Andrey Ermoshin on 22.11.2022.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import UIKit
import CoreBrowser
import FeaturesFlagsKit
import BrowserNetworking
import CottonBase
import CottonData

@MainActor
protocol SearchBarDelegate: AnyObject {
    func openTab(_ content: CoreBrowser.Tab.ContentType)
    func layoutSuggestions()
}

/// Need to inherit from NSobject to confirm to search bar delegate
final class SearchBarCoordinator: NSObject, Coordinator {
    let vcFactory: ViewControllerFactory
    var startedCoordinator: Coordinator?
    weak var parent: CoordinatorOwner?
    var startedVC: AnyViewController?
    weak var presenterVC: AnyViewController?
    var navigationStack: UINavigationController?

    private weak var downloadPanelDelegate: DownloadPanelPresenter?
    private weak var globalMenuDelegate: GlobalMenuDelegate?
    private weak var delegate: SearchBarDelegate?

    private var searhSuggestionsCoordinator: SearchSuggestionsCoordinator?

    /// Temporary property which automatically removes leading spaces.
    /// Can't declare it private due to compiler error.
    @LeadingTrimmed private var tempSearchText: String = ""
    /// Tells if coordinator was already started
    private var isSuggestionsShowed: Bool = false

    let uiFramework: UIFrameworkType

    init(_ vcFactory: ViewControllerFactory,
         _ presenter: AnyViewController,
         _ downloadPanelDelegate: DownloadPanelPresenter?,
         _ globalMenuDelegate: GlobalMenuDelegate?,
         _ delegate: SearchBarDelegate?,
         _ uiFramework: UIFrameworkType) {
        self.vcFactory = vcFactory
        self.presenterVC = presenter
        self.downloadPanelDelegate = downloadPanelDelegate
        self.globalMenuDelegate = globalMenuDelegate
        self.delegate = delegate
        self.uiFramework = uiFramework
    }

    func start() {
        let createdVC: (any AnyViewController)?
        if isPad {
            createdVC = vcFactory.deviceSpecificSearchBarViewController(self,
                                                                        downloadPanelDelegate,
                                                                        globalMenuDelegate,
                                                                        uiFramework)
        } else {
            createdVC = vcFactory.deviceSpecificSearchBarViewController(self, uiFramework)
        }
        guard let vc = createdVC, let controllerView = presenterVC?.controllerView else {
            return
        }

        vc.controllerView.translatesAutoresizingMaskIntoConstraints = false
        startedVC = vc
        presenterVC?.viewController.add(asChildViewController: vc.viewController, to: controllerView)
    }
}

enum SearchBarRoute: Route {
    case handleAction(SearchBarAction)
    case suggestions(String)
    case hideSuggestions
}

extension SearchBarCoordinator: Navigating {
    typealias R = SearchBarRoute

    func showNext(_ route: R) {
        switch route {
        case .handleAction(let action):
            guard let searchInterface = startedVC as? SearchBarControllerInterface else {
                return
            }
            searchInterface.handleAction(action)
        case .suggestions(let query):
            searhSuggestionsCoordinator?.showNext(.startSearch(query))
        case .hideSuggestions:
            hideSearchController()
        }
    }

    func stop() {
        startedVC?.viewController.removeFromChild()
    }
}

enum SearchBarPart: SubviewPart {
    case suggestions(any SearchSuggestionsViewModel)
    /// Similar case to the existing one, just to be able to create it without a dummy view model
    case simplySuggestions
}

extension SearchBarCoordinator: Layouting {
    typealias SP = SearchBarPart

    func insertNext(_ subview: SP) {
        switch subview {
        case .suggestions(let viewModel):
            insertSearchSuggestions(viewModel)
        case .simplySuggestions:
            assertionFailure("Not possible case")
        }
    }

    func layout(_ step: OwnLayoutStep) {
        switch step {
        case .viewDidLoad(let topAnchor, _, _):
            viewDidLoad(topAnchor)
        default:
            break
        }
    }

    func layoutNext(_ step: LayoutStep<SP>) {
        switch step {
        case .viewDidLoad(let subview, let topAnchor, let bottomAnchor, let toolbarHeight):
            switch subview {
            case .simplySuggestions:
                searhSuggestionsCoordinator?.layout(.viewDidLoad(topAnchor, bottomAnchor, toolbarHeight))
            case .suggestions:
                assertionFailure("Not possible case")
            }
        default:
            break
        }
    }
}

extension SearchBarCoordinator: CoordinatorOwner {
    func coordinatorDidFinish(_ coordinator: Coordinator) {
        if coordinator === searhSuggestionsCoordinator {
            // maybe need to reuse it actually and not create it each time
            searhSuggestionsCoordinator = nil
        }
    }
}

private extension SearchBarCoordinator {
    func viewDidLoad(_ topAnchor: NSLayoutYAxisAnchor?) {
        guard let presenterView = presenterVC?.controllerView else {
            return
        }
        guard let searchView = startedVC?.controllerView else {
            return
        }
        if isPad, let topViewAnchor = topAnchor {
            searchView.topAnchor.constraint(equalTo: topViewAnchor).isActive = true
        } else {
            if #available(iOS 11, *) {
                searchView.topAnchor.constraint(equalTo: presenterView.safeAreaLayoutGuide.topAnchor).isActive = true
            } else {
                searchView.topAnchor.constraint(equalTo: presenterView.topAnchor).isActive = true
            }
        }
        searchView.leadingAnchor.constraint(equalTo: presenterView.leadingAnchor).isActive = true
        searchView.trailingAnchor.constraint(equalTo: presenterView.trailingAnchor).isActive = true
        searchView.heightAnchor.constraint(equalToConstant: .searchViewHeight).isActive = true
    }

    func insertSearchSuggestions(_ viewModel: any SearchSuggestionsViewModel) {
        guard !isSuggestionsShowed else {
            return
        }
        isSuggestionsShowed = true
        // Presenter for suggestions is root view controller

        // swiftlint:disable:next force_unwrapping
        let presenter = presenterVC!
        let coordinator: SearchSuggestionsCoordinator = .init(vcFactory, presenter, self, viewModel)
        coordinator.parent = self
        coordinator.start()
        searhSuggestionsCoordinator = coordinator
    }

    func hideSearchController() {
        guard isSuggestionsShowed else {
            print("Attempted to hide suggestions when they are not showed")
            return
        }
        isSuggestionsShowed = false
        searhSuggestionsCoordinator?.stop()
    }

    func replaceTab(with url: URL, with suggestion: String? = nil) async {
        let blockPopups = DefaultTabProvider.shared.blockPopups
        let isJSEnabled = await FeatureManager.shared.boolValue(of: .javaScriptEnabled)
        let settings = Site.Settings(isPrivate: false,
                                     blockPopups: blockPopups,
                                     isJSEnabled: isJSEnabled,
                                     canLoadPlugins: true)
        guard let site = Site(url, suggestion, settings) else {
            assertionFailure("\(#function) failed to replace current tab - failed create site")
            return
        }
        // tab content replacing will happen in `didCommit`
        delegate?.openTab(.site(site))
    }
}

extension SearchBarCoordinator: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchQuery: String) {
        if searchQuery.isEmpty || searchQuery.looksLikeAURL() {
            showNext(.hideSuggestions)
        } else {
            /// Async layout is fine for this case because both insert & show operations are together in one closure
            Task {
                let searchProviderType = await FeatureManager.shared.webSearchAutoCompleteValue()
                let viewModel = await ViewModelFactory.shared.searchSuggestionsViewModel(searchProviderType)
                insertNext(.suggestions(viewModel))
                /// Use delegate and not a direct call
                /// because it requires layout info
                /// about neighbour views (anchors and height)
                delegate?.layoutSuggestions()
                showNext(.suggestions(searchQuery))
            }
        }
    }

    func searchBar(_ searchBar: UISearchBar,
                   shouldChangeTextIn range: NSRange,
                   replacementText text: String) -> Bool {
        guard let value = searchBar.text else {
            return text != " "
        }
        // UIKit's searchbar delegate uses modern String type
        // but at the same time legacy NSRange type
        // which can't be used in String API,
        // since it requires modern Range<String.Index>
        // https://exceptionshub.com/nsrange-to-rangestring-index.html
        let future = (value as NSString).replacingCharacters(in: range, with: text)
        // Only need to check that no leading spaces
        // trailing space is allowed to be able to construct
        // query requests with more than one word.
        tempSearchText = future
        // 400 IQ approach
        return tempSearchText == future
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        showNext(.handleAction(.startSearch))
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        showNext(.hideSuggestions)
        searchBar.resignFirstResponder()
        showNext(.handleAction(.cancelTapped))
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text else {
            return
        }
        let content: SuggestionType
        if text.looksLikeAURL() {
            content = .looksLikeURL(text)
        } else {
            // need to open web view with url of search engine
            // and specific search queue
            content = .suggestion(text)
        }
        Task {
            await searchSuggestionDidSelect(content)
        }
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        // called when `Cancel` pressed or search bar no more a first responder
    }
}

extension SearchBarCoordinator: SearchSuggestionsListDelegate {
    func searchSuggestionDidSelect(_ content: SuggestionType) async {
        showNext(.hideSuggestions)

        switch content {
        case .looksLikeURL(let likeURL):
            guard let url = URL(string: likeURL) else {
                assertionFailure("Failed construct site URL using edited URL")
                return
            }
            await replaceTab(with: url)
        case .knownDomain(let domain):
            guard let url = URL(string: "https://\(domain)") else {
                assertionFailure("Failed construct site URL using domain name")
                return
            }
            await replaceTab(with: url)
        case .suggestion(let suggestion):
            await handleSuggestion(suggestion)
        }
    }
}

extension FeatureManager.StateHolder {
    func searchPluginName() async -> KnownSearchPluginName {
        switch await webSearchAutoCompleteValue() {
        case .google:
            return .google
        case .duckduckgo:
            return .duckduckgo
        }
    }
}

// MARK: - Async private methods

private extension SearchBarCoordinator {
    func handleSuggestion(_ suggestion: String) async {
        let client = await ServiceRegistry.shared.searchSuggestClient()
        guard let url = client.searchURLForQuery(suggestion) else {
            assertionFailure("Failed construct search engine url from suggestion string")
            return
        }
        await replaceTab(with: url, with: suggestion)
    }
}
