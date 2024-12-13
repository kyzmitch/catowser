//
//  SearchSuggestionsLegacyView.swift
//  catowser
//
//  Created by Andrei Ermoshin on 4/21/23.
//  Copyright © 2023 Cotton (former Catowser). All rights reserved.
//

import SwiftUI
import CottonViewModels

struct SearchSuggestionsLegacyView<S: SearchSuggestionsViewModel>: CatowserUIVCRepresentable {
    typealias UIViewControllerType = UIViewController

    private let searchQuery: String
    private weak var delegate: SearchSuggestionsListDelegate?
    @EnvironmentObject private var viewModel: S

    init(_ searchQuery: String,
         _ delegate: SearchSuggestionsListDelegate?) {
        self.searchQuery = searchQuery
        self.delegate = delegate
    }

    func makeUIViewController(context: Context) -> UIViewControllerType {
        let vc = vcFactory.searchSuggestionsViewController(delegate, viewModel)
        return vc.viewController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        guard let interface = uiViewController as? SearchSuggestionsControllerInterface else {
            return
        }
        Task {
            await interface.prepareSearch(for: searchQuery)
        }
    }
}
