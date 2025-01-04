//
//  PhoneSearchBarLegacyView.swift
//  catowser
//
//  Created by Andrei Ermoshin on 4/21/23.
//  Copyright © 2023 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import SwiftUI
import CottonViewModels

struct PhoneSearchBarLegacyView: CatowserUIVCRepresentable {
    private weak var searchBarDelegate: UISearchBarDelegate?
    /// Model also has action property
    private let action: SearchBarAction
    /// View model
    private let viewModel: SearchBarViewModelWithDelegates

    init(
        _ searchBarDelegate: UISearchBarDelegate?,
        _ action: SearchBarAction,
        _ viewModel: SearchBarViewModelWithDelegates
    ) {
        self.searchBarDelegate = searchBarDelegate
        self.action = action
        self.viewModel = viewModel
    }

    typealias UIViewControllerType = UIViewController

    func makeUIViewController(context: Context) -> UIViewControllerType {
        let vc = vcFactory.deviceSpecificSearchBarViewController(
            searchBarDelegate,
            .swiftUIWrapper,
            viewModel
        )
        // swiftlint:disable:next force_unwrapping
        return vc!.viewController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        guard let interface = uiViewController as? SearchBarControllerInterface else {
            return
        }
        // Update UIKit search bar view when SwiftUI detects tab content replacement
        // or User taps on Cancel button and it is detected by search bar delegate.
        interface.handleAction(action)
    }
}
