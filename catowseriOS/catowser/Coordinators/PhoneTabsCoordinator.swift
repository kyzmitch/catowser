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
    var navigationStack: UINavigationController?

    let uiFramework: UIFrameworkType

    init(_ vcFactory: any ViewControllerFactory,
         _ presenter: AnyViewController?,
         _ uiFramework: UIFrameworkType) {
        self.vcFactory = vcFactory
        self.presenterVC = presenter
        self.uiFramework = uiFramework
    }

    func start() {
        /// Async start should be fine, because there are no layout steps in this coordinator
        /// which could be done later after start
        Task {
            #warning("TODO: in SwiftUI this VM should be constructed before use case registering, but it is not")
            let vm = await ViewModelFactory.shared.tabsPreviewsViewModel()
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
