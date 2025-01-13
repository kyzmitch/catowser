//
//  TabletSearchBarViewV2.swift
//  catowser
//
//  Created by Andrei Ermoshin on 4/26/23.
//  Copyright © 2023 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import SwiftUI
import CottonViewModels

struct TabletSearchBarViewV2: View {
    @Binding private var showSearchSuggestions: Bool
    @Binding private var showingMenu: Bool
    @Binding private var query: String
    @Binding private var action: SearchBarAction

    /// Toolbar vm is better to be stored in Environment, because tablet view wrapper doesn't need it
    @EnvironmentObject var toolbarVM: BrowserToolbarViewModel
    /// Search bar view model
    @ObservedObject var searchBarVM: SearchBarViewModel

    private let columns: [GridItem] = [
        GridItem(.fixed(CGFloat.toolbarViewHeight)),
        GridItem(.fixed(CGFloat.toolbarViewHeight)),
        GridItem(.fixed(CGFloat.toolbarViewHeight)),
        GridItem(.fixed(CGFloat.toolbarViewHeight)),
        GridItem(.flexible(), spacing: 2, alignment: .center)
    ]

    init(
        _ showingMenu: Binding<Bool>,
        _ showSearchSuggestions: Binding<Bool>,
        _ query: Binding<String>,
        _ action: Binding<SearchBarAction>,
        _ searchBarVM: SearchBarViewModel
    ) {
        _showingMenu = showingMenu
        _showSearchSuggestions = showSearchSuggestions
        _query = query
        _action = action
        self.searchBarVM = searchBarVM
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns) {
                MenuButton($showSearchSuggestions, $showingMenu).padding()
                DisableableButton(
                    "nav-back",
                    toolbarVM.state.goBackDisabled, {
                        toolbarVM.sendAction(.goBack)
                    }
                ).padding()
                DisableableButton(
                    "nav-forward",
                    toolbarVM.state.goForwardDisabled, {
                        toolbarVM.sendAction(.goForward)
                    }
                ).padding()
                DisableableButton(
                    "nav-refresh",
                    toolbarVM.state.reloadDisabled, {
                        toolbarVM.sendAction(.reload)
                    }
                ).padding()
                SearchBarViewV2($query, $action, searchBarVM)
            }
        }
    }
}
