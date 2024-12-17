//
//  TabletTabsCoordinator.swift
//  catowser
//
//  Created by Andrei Ermoshin on 11/28/22.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import UIKit
import CottonViewModels

final class TabletTabsCoordinator: Coordinator {
    let vcFactory: any ViewControllerFactory
    var startedCoordinator: Coordinator?
    weak var parent: CoordinatorOwner?
    var startedVC: AnyViewController?
    weak var presenterVC: AnyViewController?
    var navigationStack: UINavigationController?
    private let viewModel: AllTabsViewModel

    init(_ vcFactory: any ViewControllerFactory,
         _ presenter: AnyViewController,
         _ viewModel: AllTabsViewModel) {
        self.vcFactory = vcFactory
        self.presenterVC = presenter
        self.viewModel = viewModel
    }

    func start() {
        guard isPad else {
            return
        }
        guard let vc = vcFactory.tabsViewController(viewModel), let superView = presenterVC?.controllerView else {
            return
        }
        startedVC = vc
        vc.controllerView.translatesAutoresizingMaskIntoConstraints = false
        presenterVC?.viewController.add(asChildViewController: vc.viewController, to: superView)
    }
}

enum TabletTabsSubview: SubviewPart {}

extension TabletTabsCoordinator: Layouting {
    typealias SP = TabletTabsSubview

    func insertNext(_ subview: SP) {}

    func layout(_ step: OwnLayoutStep) {
        switch step {
        case .viewDidLoad:
            viewDidLoad()
        default:
            break
        }
    }

    func layoutNext(_ step: LayoutStep<SP>) {}
}

private extension TabletTabsCoordinator {
    func viewDidLoad() {
        guard isPad else {
            return
        }
        guard let tabsView = startedVC?.controllerView, let superView = presenterVC?.controllerView else {
            return
        }
        // https://github.com/SnapKit/SnapKit/issues/448
        // https://developer.apple.com/documentation/uikit/uiviewcontroller/1621367-toplayoutguide
        // https://developer.apple.com/documentation/uikit/uiview/2891102-safearealayoutguide
        if #available(iOS 11, *) {
            let topAnchor = superView.safeAreaLayoutGuide.topAnchor
            tabsView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        } else {
            tabsView.topAnchor.constraint(equalTo: superView.topAnchor).isActive = true
        }
        tabsView.leadingAnchor.constraint(equalTo: superView.leadingAnchor).isActive = true
        tabsView.trailingAnchor.constraint(equalTo: superView.trailingAnchor).isActive = true
        tabsView.heightAnchor.constraint(equalToConstant: .tabHeight).isActive = true
    }
}
