//
//  PhoneTabsCoordinator.swift
//  catowser
//
//  Created by Andrei Ermoshin on 11/15/22.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import UIKit
import CoreBrowser
import FeaturesFlagsKit

final class PhoneTabsCoordinator: Coordinator {
    let vcFactory: any ViewControllerFactory
    var startedCoordinator: Coordinator?
    weak var parent: CoordinatorOwner?
    var startedVC: AnyViewController?
    weak var presenterVC: AnyViewController?
    private let vm: TabsPreviewsViewModel
    var navigationStack: UINavigationController?

    let uiFramework: UIFrameworkType

    init(_ vcFactory: any ViewControllerFactory,
         _ presenter: AnyViewController?,
         _ uiFramework: UIFrameworkType,
         _ viewModel: TabsPreviewsViewModel
    ) {
        self.vcFactory = vcFactory
        self.presenterVC = presenter
        self.uiFramework = uiFramework
        self.vm = viewModel
    }

    func start() {
        guard let vc = vcFactory.tabsPreviewsViewController(self, vm) else {
            assertionFailure("Tabs previews screen is only for Phone layout")
            return
        }
        startedVC = vc
        guard !uiFramework.isUIKitFree else {
            // For SwiftUI mode we still need to create view controller
            // but presenting should happen on SwiftUI level
            return
        }
        presenterVC?.viewController.present(vc, animated: true, completion: nil)
    }
}

enum TabsScreenRoute: Route {
    case error
}

extension PhoneTabsCoordinator: Navigating {

    typealias R = TabsScreenRoute

    func showNext(_ route: TabsScreenRoute) {
        switch route {
        case .error:
            showError()
        }
    }

    func stop() {
        startedVC?.viewController.dismiss(animated: true)
        guard !uiFramework.isUIKitFree else {
            // Need to try to save coordinator for SwiftUI mode
            // because it was started at App start and not when
            // user presses on tab previews button in toolbar
            // as it is done in UIKit mode
            return
        }
        parent?.coordinatorDidFinish(self)
    }
}

private extension PhoneTabsCoordinator {
    func showError() {
        Task {
            guard let vc = startedVC else {
                assertionFailure("Phone tabs coordinator is not started")
                return
            }
            AlertPresenter.present(on: vc.viewController)
        }
    }
}
