//
//  MainToolbarCoordinator.swift
//  catowser
//
//  Created by Andrey Ermoshin on 14.11.2022.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import UIKit
import CoreBrowser
import FeatureFlagsKit
import CottonViewModels

@MainActor
final class MainToolbarCoordinator: Coordinator {
    let vcFactory: ViewControllerFactory
    var startedCoordinator: Coordinator?
    weak var parent: CoordinatorOwner?
    var startedVC: AnyViewController?
    weak var presenterVC: AnyViewController?
    var navigationStack: UINavigationController?
    private let phoneTabPreviewsVM: TabsPreviewsViewModel

    private weak var downloadDelegate: DownloadPanelPresenter?
    private weak var settingsDelegate: GlobalMenuDelegate?

    let uiFramework: UIFrameworkType

    init(_ vcFactory: ViewControllerFactory,
         _ presenter: AnyViewController?,
         _ downloadDelegate: DownloadPanelPresenter?,
         _ settingsDelegate: GlobalMenuDelegate,
         _ uiFramework: UIFrameworkType,
         _ phoneTabPreviewsVM: TabsPreviewsViewModel
    ) {
        self.vcFactory = vcFactory
        self.presenterVC = presenter
        self.downloadDelegate = downloadDelegate
        self.settingsDelegate = settingsDelegate
        self.uiFramework = uiFramework
        self.phoneTabPreviewsVM = phoneTabPreviewsVM
    }

    func start() {
        guard uiFramework == .uiKit else {
            return
        }
        guard !isPad else {
            return
        }
        guard let vc = vcFactory.toolbarViewController(downloadDelegate, settingsDelegate, self, nil) else {
            assertionFailure("Toolbar is only available on Phone layout")
            return
        }
        guard let containerView = presenterVC?.controllerView else {
            return
        }
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        startedVC = vc
        presenterVC?.viewController.add(asChildViewController: vc, to: containerView)
    }
}

extension MainToolbarCoordinator: CoordinatorOwner {
    func coordinatorDidFinish(_ coordinator: Coordinator) {
        if coordinator === startedCoordinator {
            // Tabs view coordinator is stored as started
            startedCoordinator = nil
        }
    }
}

enum ToolbarRoute: Route {
    case tabs
}

extension MainToolbarCoordinator: Navigating {
    typealias R = ToolbarRoute

    func showNext(_ route: R) {
        switch route {
        case .tabs:
            showTabs()
        }
    }

    func showNext(_ route: R, _ presenter: AnyViewController?) {
        if presenter != nil {
            presenterVC = presenter
        }

        showNext(route)
    }
}

enum ToolbarPart: SubviewPart {}

extension MainToolbarCoordinator: Layouting {
    typealias SP = ToolbarPart

    func insertNext(_ subview: SP) {}

    func layout(_ step: OwnLayoutStep) {
        switch step {
        case .viewDidLoad(let topAnchor, _, _):
            viewDidLoad(topAnchor)
        default:
            break
        }
    }

    func layoutNext(_ step: LayoutStep<SP>) {

    }
}

private extension MainToolbarCoordinator {
    func viewDidLoad(_ topAnchor: NSLayoutYAxisAnchor?) {
        guard let toolbarView = startedVC?.controllerView else {
            return
        }
        guard let superView = presenterVC?.controllerView else {
            return
        }
        guard let topViewAnchor = topAnchor else {
            return
        }
        toolbarView.topAnchor.constraint(equalTo: topViewAnchor).isActive = true
        toolbarView.leadingAnchor.constraint(equalTo: superView.leadingAnchor).isActive = true
        toolbarView.trailingAnchor.constraint(equalTo: superView.trailingAnchor).isActive = true
        toolbarView.heightAnchor.constraint(equalToConstant: .tabBarHeight).isActive = true
        // Using superview's bottom here, but still on the upper level
        // we have to use a dummy view to fix a visual bug on Phone layout
        // for some iOS versions, toolbar buttons are fully visible
        // even with a dummy view
        if #available(iOS 11, *) {
            let bottomAnchor = superView.safeAreaLayoutGuide.bottomAnchor
            toolbarView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        } else {
            toolbarView.bottomAnchor.constraint(equalTo: superView.bottomAnchor).isActive = true
        }
    }

    func showTabs() {
        let presenter: AnyViewController?
        if case .uiKit = uiFramework {
            presenter = startedVC
        } else {
            presenter = presenterVC
        }

        // Do we really need to re-create coordinator every time?
        // Because user could tap on tab previews button in toolbar
        // more than once.
        if let existingPhoneTabsCrdr = startedCoordinator as? PhoneTabsCoordinator {
            existingPhoneTabsCrdr.start()
        } else {
            let coordinator = PhoneTabsCoordinator(
                vcFactory,
                presenter,
                uiFramework,
                phoneTabPreviewsVM
            )
            coordinator.parent = self
            coordinator.start()
            startedCoordinator = coordinator
        }
    }
}
