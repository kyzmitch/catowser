//
//  ToolbarLegacyView.swift
//  catowser
//
//  Created by Andrei Ermoshin on 4/21/23.
//  Copyright © 2023 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import SwiftUI
import CottonData
import CottonViewModels

struct ToolbarLegacyView: CatowserUIVCRepresentable {
    typealias UIViewControllerType = UIViewController
    private let webViewInterface: WebViewNavigatable?

    init(_ webViewInterface: WebViewNavigatable?) {
        self.webViewInterface = webViewInterface
    }

    func makeUIViewController(context: Context) -> UIViewControllerType {
        let interface = context.environment.browserContentCoordinators
        let vc = vcFactory.toolbarViewController(nil,
                                                 interface?.globalMenuDelegate,
                                                 interface?.toolbarCoordinator,
                                                 interface?.toolbarPresenter)
        // swiftlint:disable:next force_unwrapping
        return vc!
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        guard let vc = uiViewController as? BrowserToolbarController<MainToolbarCoordinator> else {
            return
        }
        // This is the only way to set the web view interface for the toolbar
        vc.siteNavigator = webViewInterface
    }
}
