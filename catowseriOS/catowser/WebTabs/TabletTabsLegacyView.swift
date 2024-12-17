//
//  TabletTabsLegacyView.swift
//  catowser
//
//  Created by Andrei Ermoshin on 4/26/23.
//  Copyright © 2023 Cotton (former Catowser). All rights reserved.
//

import SwiftUI
import CottonViewModels

struct TabletTabsLegacyView: CatowserUIVCRepresentable {
    typealias UIViewControllerType = UIViewController

    @EnvironmentObject private var viewModel: AllTabsViewModel

    init() {}

    func makeUIViewController(context: Context) -> UIViewControllerType {
        let vc = vcFactory.tabsViewController(viewModel)
        // swiftlint:disable:next force_unwrapping
        return vc!.viewController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}
