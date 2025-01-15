//
//  TabletSearchBarLegacyView.swift
//  catowser
//
//  Created by Andrei Ermoshin on 4/21/23.
//  Copyright © 2023 Cotton (former Catowser). All rights reserved.
//

import SwiftUI
import CottonViewModels

struct TabletSearchBarLegacyView: CatowserUIVCRepresentable {
    private weak var searchBarDelegate: UISearchBarDelegate?
    private let action: SearchBarAction
    private let webViewInterface: WebViewNavigatable?
    @EnvironmentObject var viewModel: SearchBarViewModel

    init(
        _ searchBarDelegate: UISearchBarDelegate?,
        _ action: SearchBarAction,
        _ webViewInterface: WebViewNavigatable?
    ) {
        self.searchBarDelegate = searchBarDelegate
        self.action = action
        self.webViewInterface = webViewInterface
    }

    typealias UIViewControllerType = UIViewController

    func makeUIViewController(context: Context) -> UIViewControllerType {
        let interface = context.environment.browserContentCoordinators
        let vc = vcFactory.deviceSpecificSearchBarViewController(
            searchBarDelegate,
            nil,
            interface?.globalMenuDelegate,
            .swiftUIWrapper,
            viewModel
        )
        // swiftlint:disable:next force_unwrapping
        return vc!.viewController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        if let interface = uiViewController as? SearchBarControllerInterface {
            // Update UIKit search bar view when SwiftUI detects tab content replacement
            // or User taps on Cancel button and it is detected by search bar delegate.
            interface.handleAction(action)
        }

        if let vc = uiViewController as? TabletSearchBarViewController {
            // This is the only way to set the web view interface for the tablet toolbar
            vc.siteNavigator = webViewInterface
        }
    }
}
