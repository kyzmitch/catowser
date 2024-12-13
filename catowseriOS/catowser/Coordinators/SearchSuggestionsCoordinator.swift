//
//  SearchSuggestionsCoordinator.swift
//  catowser
//
//  Created by Andrei Ermoshin on 11/14/22.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import UIKit
@preconcurrency import ReactiveSwift
import FeatureFlagsKit
import CottonViewModels

protocol SearchSuggestionsControllerInterface: AnyObject {
    func prepareSearch(for searchQuery: String) async
}

final class SearchSuggestionsCoordinator: Coordinator {
    let vcFactory: any ViewControllerFactory
    var startedCoordinator: Coordinator?
    weak var parent: CoordinatorOwner?
    var startedVC: AnyViewController?
    weak var presenterVC: AnyViewController?
    var navigationStack: UINavigationController?

    private weak var delegate: SearchSuggestionsListDelegate?
    private var _keyboardHeight: CGFloat?
    private var keyboardHeight: CGFloat? {
        get {
            return _keyboardHeight
        }
        set (newValue) {
            _keyboardHeight = newValue
        }
    }
    private var disposables = [Disposable?]()
    private let viewModel: any SearchSuggestionsViewModel

    init(
        _ vcFactory: any ViewControllerFactory,
        _ presenter: AnyViewController,
        _ delegate: SearchSuggestionsListDelegate,
        _ viewModel: any SearchSuggestionsViewModel
    ) {
        self.vcFactory = vcFactory
        self.presenterVC = presenter
        self.delegate = delegate
        self.viewModel = viewModel
    }

    func start() {
        guard let controllerView = presenterVC?.controllerView else {
            return
        }
        let vc = vcFactory.searchSuggestionsViewController(delegate, viewModel)
        startedVC = vc
        // adds suggestions view to root view controller
        presenterVC?.viewController.add(asChildViewController: vc.viewController, to: controllerView)

        disposables.forEach { $0?.dispose() }

        let disposeB = NotificationCenter.default.reactive
            .notifications(forName: UIResponder.keyboardWillHideNotification)
            .observe(on: UIScheduler())
            .observeValues { [weak self] (notification) in
                self?.keyboardWillHideClosure()(notification)
            }

        let disposeA = NotificationCenter.default.reactive
            .notifications(forName: UIResponder.keyboardDidChangeFrameNotification)
            .observe(on: UIScheduler())
            .observeValues { [weak self] notification in
                self?.keyboardWillChangeFrameClosure()(notification)
            }

        disposables.append(disposeB)
        disposables.append(disposeA)
    }
}

enum SearchSuggestionsRoute: Route {
    case startSearch(String)
}

extension SearchSuggestionsCoordinator: Navigating {
    typealias R = SearchSuggestionsRoute

    func showNext(_ route: SearchSuggestionsRoute) {
        switch route {
        case .startSearch(let searchQuery):
            guard let interface = startedVC?.viewController as? SearchSuggestionsControllerInterface else {
                return
            }
            Task {
                await interface.prepareSearch(for: searchQuery)
            }
        }
    }

    func stop() {
        disposables.forEach { $0?.dispose() }
        startedVC?.viewController.removeFromChild()
        parent?.coordinatorDidFinish(self)
    }
}

enum SearchSuggestionsPart: SubviewPart {}

extension SearchSuggestionsCoordinator: Layouting {
    typealias SP = SearchSuggestionsPart

    func insertNext(_ subview: SP) {

    }

    func layout(_ step: OwnLayoutStep) {
        switch step {
        case .viewDidLoad(let topAnchor, let bottomAnchor, let toolbarHeight):
            viewDidLoad(topAnchor, bottomAnchor, toolbarHeight)
        default:
            break
        }
    }

    func layoutNext(_ step: LayoutStep<SP>) {

    }
}

private extension SearchSuggestionsCoordinator {
    func keyboardWillChangeFrameClosure() -> @MainActor @Sendable (Notification) -> Void {
        let handling: @MainActor @Sendable (Notification) -> Void = { [weak self] notification in
            guard let info = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] else { return }
            guard let value = info as? NSValue else { return }
            let rect = value.cgRectValue

            // need to reduce search suggestions list height
            self?._keyboardHeight = rect.size.height
        }

        return handling
    }

    func keyboardWillHideClosure() -> @MainActor @Sendable (Notification) -> Void {
        let handling: @MainActor @Sendable (Notification) -> Void = { [weak self] notification in
            self?._keyboardHeight = nil
        }

        return handling
    }

    func viewDidLoad(_ topAnchor: NSLayoutYAxisAnchor?,
                     _ bottomAnchor: NSLayoutYAxisAnchor?,
                     _ toolbarHeight: CGFloat?) {
        guard let suggestionsView = startedVC?.controllerView,
              let presenterView = presenterVC?.controllerView else {
            return
        }
        guard let topAnchor = topAnchor,
              let bottomAnchor = bottomAnchor else {
            return
        }
        suggestionsView.topAnchor.constraint(equalTo: topAnchor, constant: 0).isActive = true
        suggestionsView.leadingAnchor.constraint(equalTo: presenterView.leadingAnchor, constant: 0).isActive = true
        suggestionsView.trailingAnchor.constraint(equalTo: presenterView.trailingAnchor, constant: 0).isActive = true

        if let bottomShift = keyboardHeight {
            let correctedShift: CGFloat
            // fix wrong height of keyboard on Simulator when keyboard partly visible
            if let toolbarViewHeight = toolbarHeight {
                // toolbar height is only on Phone
                correctedShift = bottomShift < toolbarViewHeight ? toolbarViewHeight : bottomShift
            } else {
                correctedShift = bottomShift
            }
            suggestionsView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -correctedShift).isActive = true
        } else {
            if isPad {
                suggestionsView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).isActive = true
            } else {
                suggestionsView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).isActive = true
            }
        }
    }
}
