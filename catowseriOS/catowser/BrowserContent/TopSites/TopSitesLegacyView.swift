//
//  TopSitesLegacyView.swift
//  catowser
//
//  Created by Andrei Ermoshin on 4/23/23.
//  Copyright © 2023 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import SwiftUI
import UIKit

struct TopSitesLegacyView: CatowserUIVCRepresentable {
    @EnvironmentObject private var vm: TopSitesViewModel
    typealias UIViewControllerType = UIViewController

    init() { }

    func makeUIViewController(context: Context) -> UIViewControllerType {
        let interface = context.environment.browserContentCoordinators
        let vc: AnyViewController = vcFactory.topSitesViewController(
            interface?.topSitesCoordinator,
            vm
        )
        return vc.viewController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}
