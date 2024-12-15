//
//  TopSitesCoordinator.swift
//  catowser
//
//  Created by Andrei Ermoshin on 11/20/22.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import UIKit
import CottonBase
import CoreBrowser
import FeatureFlagsKit
import CottonViewModels

@MainActor
final class TopSitesCoordinator: Coordinator {
    let vcFactory: ViewControllerFactory
    var startedCoordinator: Coordinator?
    weak var parent: CoordinatorOwner?
    var startedVC: AnyViewController?
    weak var presenterVC: AnyViewController?
    var navigationStack: UINavigationController?

    private let contentContainerView: UIView?
    let uiFramework: UIFrameworkType
    private let topSitesVM: TopSitesViewModel

    init(_ vcFactory: ViewControllerFactory,
         _ presenter: AnyViewController?,
         _ contentContainerView: UIView?,
         _ uiFramework: UIFrameworkType,
         _ topSitesVM: TopSitesViewModel
    ) {
        self.vcFactory = vcFactory
        self.presenterVC = presenter
        self.contentContainerView = contentContainerView
        self.uiFramework = uiFramework
        self.topSitesVM = topSitesVM
    }

    func start() {
        guard uiFramework == .uiKit else {
            return
        }
        guard let contentContainerView = contentContainerView else {
            return
        }
        let vc = vcFactory.topSitesViewController(self, topSitesVM)
        startedVC = vc
        presenterVC?.viewController.add(
            asChildViewController: vc.viewController,
            to: contentContainerView
        )

        let topSitesView: UIView = vc.controllerView
        topSitesView.translatesAutoresizingMaskIntoConstraints = false
        topSitesView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor).isActive = true
        topSitesView.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor).isActive = true
        topSitesView.topAnchor.constraint(equalTo: contentContainerView.topAnchor).isActive = true
        topSitesView.bottomAnchor.constraint(equalTo: contentContainerView.bottomAnchor).isActive = true
    }
}

enum TopSitesRoute: Route { }

extension TopSitesCoordinator: Navigating {
    typealias R = TopSitesRoute

    func showNext(_ route: R) { }

    func stop() {
        guard uiFramework == .uiKit else {
            return
        }
        startedVC?.viewController.removeFromChild()
        parent?.coordinatorDidFinish(self)
    }
}
