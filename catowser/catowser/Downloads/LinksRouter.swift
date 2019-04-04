//
//  LinksRouter.swift
//  catowser
//
//  Created by Andrei Ermoshin on 03/04/2019.
//  Copyright © 2019 andreiermoshin. All rights reserved.
//

import UIKit
import CoreBrowser
import ReactiveSwift

protocol MasterDelegate: class {
    var keyboardHeight: CGFloat? { get set }
    var toolbarHeight: CGFloat { get }
    var toolbarTopAnchor: NSLayoutYAxisAnchor { get }

    func handleSearchSuggestion(url: URL, suggestion: String)
}

/// Should contain copies for references to all needed constraints and view controllers. NSObject subclass to support system delegate protocol.
final class LinksRouter: NSObject {
    /// The table to display search suggestions list
    let searchSuggestionsController: SearchSuggestionsViewController = {
        let vc = SearchSuggestionsViewController()
        return vc
    }()

    /// The link tags controller to display segments with link types amount
    lazy var linkTagsController: AnyViewController & LinkTagsPresenter = {
        let vc = LinkTagsViewController.newFromStoryboard(delegate: self)
        return vc
    }()

    /// The files greed controller to display links for downloads
    lazy var filesGreedController: AnyViewController & FilesGreedPresenter = {
        let vc = FilesGreedViewController.newFromStoryboard()
        return vc
    }()

    lazy var searchBarController: AnyViewController & SearchBarControllerInterface = {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return TabletSearchBarViewController(self)
        } else {
            return SmartphoneSearchBarViewController(self)
        }
    }()

    var hiddenTagsConstraint: NSLayoutConstraint?

    var showedTagsConstraint: NSLayoutConstraint?

    var hiddenFilesGreedConstraint: NSLayoutConstraint?

    var showedFilesGreedConstraint: NSLayoutConstraint?

    var filesGreedHeightConstraint: NSLayoutConstraint?

    var underLinksViewHeightConstraint: NSLayoutConstraint?

    var isSuggestionsShowed: Bool = false

    var isLinkTagsShowed: Bool = false

    var isFilesGreedShowed: Bool = false

    private let isPad: Bool = UIDevice.current.userInterfaceIdiom == .pad ? true : false
    
    private var searchSuggestionsDisposable: Disposable?

    private let searchSuggestClient: SearchSuggestClient = {
        // TODO: implement parsing e.g. google.xml
        guard let sEngine = try? OpenSearchParser.parse("", engineID: "") else {
            return SearchSuggestClient(.googleEngine)
        }
        let client = SearchSuggestClient(sEngine)
        return client
    }()

    private let presenter: AnyViewController & MasterDelegate

    init(viewController: AnyViewController & MasterDelegate) {
        presenter = viewController
    }

    deinit {
        searchSuggestionsDisposable?.dispose()
    }

    func showLinkTagsControllerIfNeeded() {
        guard !isLinkTagsShowed else {
            return
        }

        isLinkTagsShowed = true
        // Order of disabling/enabling is important to not to cause errors in layout calculation.
        hiddenTagsConstraint?.isActive = false
        showedTagsConstraint?.isActive = true

        UIView.animate(withDuration: 0.33) {
            self.linkTagsController.view.layoutIfNeeded()
        }
    }

    func showFilesGreedIfNeeded() {
        guard !isFilesGreedShowed else {
            return
        }
        hiddenFilesGreedConstraint?.isActive = false
        showedFilesGreedConstraint?.isActive = true

        UIView.animate(withDuration: 0.33) {
            self.filesGreedController.view.layoutIfNeeded()
        }
        isFilesGreedShowed = true
    }

    func showSearchControllerIfNeeded() {
        guard !isSuggestionsShowed else {
            return
        }

        presenter.viewController.add(asChildViewController: searchSuggestionsController, to: presenter.view)
        isSuggestionsShowed = true
        searchSuggestionsController.delegate = self

        searchSuggestionsController.view.topAnchor.constraint(equalTo: searchBarController.view.bottomAnchor, constant: 0).isActive = true
        searchSuggestionsController.view.leadingAnchor.constraint(equalTo: presenter.view.leadingAnchor, constant: 0).isActive = true
        searchSuggestionsController.view.trailingAnchor.constraint(equalTo: presenter.view.trailingAnchor, constant: 0).isActive = true

        if let bottomShift = presenter.keyboardHeight {
            // fix wrong height of keyboard on Simulator when keyboard partly visible
            let correctedShift = bottomShift < presenter.toolbarHeight ? presenter.toolbarHeight : bottomShift
            searchSuggestionsController.view.bottomAnchor.constraint(equalTo: presenter.view.bottomAnchor, constant: -correctedShift).isActive = true
        } else {
            if isPad {
                searchSuggestionsController.view.bottomAnchor.constraint(equalTo: presenter.toolbarTopAnchor, constant: 0).isActive = true
            } else {
                searchSuggestionsController.view.bottomAnchor.constraint(equalTo: presenter.view.bottomAnchor, constant: 0).isActive = true
            }
        }
    }

    func hideLinkTagsController() {
        guard isLinkTagsShowed else {
            return
        }
        showedTagsConstraint?.isActive = false
        hiddenTagsConstraint?.isActive = true

        linkTagsController.view.layoutIfNeeded()
        isLinkTagsShowed = false
    }

    func hideFilesGreedIfNeeded() {
        guard isFilesGreedShowed else {
            return
        }

        showedFilesGreedConstraint?.isActive = false
        hiddenFilesGreedConstraint?.isActive = true

        filesGreedController.view.layoutIfNeeded()
        isFilesGreedShowed = false
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
}

fileprivate extension LinksRouter {
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

extension LinksRouter: LinkTagsDelegate {
    func didSelect(type: LinksType) {
        hideFilesGreedIfNeeded()

        if type == .video {
            showFilesGreedIfNeeded()
        }
    }
}

extension LinksRouter: SearchSuggestionsListDelegate {
    func didSelect(_ suggestion: String) {
        hideSearchController()
        guard let url = searchSuggestClient.searchURL(basedOn: suggestion) else {
            return
        }
        presenter.handleSearchSuggestion(url: url, suggestion: suggestion)
    }
}

extension LinksRouter: UISearchBarDelegate {
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
