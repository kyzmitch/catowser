//
//  TopSitesCoordinator.swift
//  catowser
//
//  Created by Andrei Ermoshin on 11/20/22.
//  Copyright © 2022 andreiermoshin. All rights reserved.
//

import UIKit
import CottonBase
import CoreBrowser
import FeaturesFlagsKit

final class TopSitesCoordinator: Coordinator {
    let vcFactory: ViewControllerFactory
    var startedCoordinator: Coordinator?
    weak var parent: CoordinatorOwner?
    var startedVC: AnyViewController?
    weak var presenterVC: AnyViewController?
    var navigationStack: UINavigationController?
    
    private let contentContainerView: UIView?
    let uiFramework: UIFrameworkType
    
    init(_ vcFactory: ViewControllerFactory,
         _ presenter: AnyViewController?,
         _ contentContainerView: UIView?,
         _ uiFramework: UIFrameworkType) {
        self.vcFactory = vcFactory
        self.presenterVC = presenter
        self.contentContainerView = contentContainerView
        self.uiFramework = uiFramework
    }
    
    func start() {
        guard uiFramework == .uiKit else {
            return
        }
        guard let contentContainerView = contentContainerView else {
            return
        }
        let vc = vcFactory.topSitesViewController(self)
        startedVC = vc
        Task {
            let isJsEnabled = await FeatureManager.shared.boolValue(of: .javaScriptEnabled)
            vc.reload(with: DefaultTabProvider.shared.topSites(isJsEnabled))
            presenterVC?.viewController.add(asChildViewController: vc.viewController, to: contentContainerView)
            
            let topSitesView: UIView = vc.controllerView
            topSitesView.translatesAutoresizingMaskIntoConstraints = false
            topSitesView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor).isActive = true
            topSitesView.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor).isActive = true
            topSitesView.topAnchor.constraint(equalTo: contentContainerView.topAnchor).isActive = true
            topSitesView.bottomAnchor.constraint(equalTo: contentContainerView.bottomAnchor).isActive = true
        }
    }
}

enum TopSitesRoute: Route {
    case select(Site)
}

extension TopSitesCoordinator: Navigating {
    typealias R = TopSitesRoute
    
    func showNext(_ route: R) {
        switch route {
        case .select(let site):
            // Open selected top site
            Task {
                do {
                    try await TabsDataService.shared.replaceSelected(.site(site))
                } catch {
                    print("Fail to replace selected tab: \(error)")
                }
            }
        }
    }
    
    func stop() {
        guard uiFramework == .uiKit else {
            return
        }
        startedVC?.viewController.removeFromChild()
        parent?.coordinatorDidFinish(self)
    }
}
