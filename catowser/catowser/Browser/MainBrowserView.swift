//
//  MainBrowserView.swift
//  catowser
//
//  Created by Andrey Ermoshin on 10.12.2022.
//  Copyright © 2022 andreiermoshin. All rights reserved.
//

import SwiftUI

struct MainBrowserView<C: BrowserContentCoordinators>: View {
    @ObservedObject var model: MainBrowserModel<C>
    
    var body: some View {
        _MainBrowserView<C>(model: model)
            .environment(\.browserContentCoordinators, model.coordinatorsInterface)
    }
}

private struct _MainBrowserView<C: BrowserContentCoordinators>: View {
    @ObservedObject var model: MainBrowserModel<C>
    private let browserContentModel: BrowserContentModel
    private let toolbarModel: WebBrowserToolbarModel
    private let searchBarModel: SearchBarViewModel
    @State var websiteLoadProgress: Double
    @State var showProgress: Bool
    @State var showSearchSuggestions: Bool
    @State var searchQuery: String
    @State var searchBarState: SearchBarState
    
    init(model: MainBrowserModel<C>) {
        showProgress = false
        showSearchSuggestions = false
        searchQuery = ""
        searchBarState = .blankSearch
        websiteLoadProgress = 0.0
        self.model = model
        browserContentModel = BrowserContentModel(model.jsPluginsBuilder)
        toolbarModel = WebBrowserToolbarModel()
        searchBarModel = SearchBarViewModel()
        // Toolbar should know if current web view changes to provide navigation
        ViewsEnvironment.shared.reuseManager.addObserver(toolbarModel)
    }
    
    var body: some View {
        if isPad {
            tabletView()
        } else {
            phoneView()
        }
    }
}

private extension _MainBrowserView {
    func tabletView() -> some View {
        VStack {
            Spacer()
        }
    }
    
    func phoneView() -> some View {
        /*
         - ignoresSafeArea(.keyboard)
         Allows to not have the toolbar be attached to keyboard.
         So, the toolbar will stay on same position
         even after keyboard became visible.
         */
        
        VStack {
            SearchBarView(model: searchBarModel, stateBinding: $searchBarState)
            if showProgress {
                ProgressView(value: websiteLoadProgress)
            }
            if showSearchSuggestions {
                SearchSuggestionsView(searchQuery: $searchQuery, delegate: searchBarModel)
            } else {
                BrowserContentView(browserContentModel, toolbarModel)
            }
            ToolbarView(toolbarModel)
        }
        .ignoresSafeArea(.keyboard)
        .onReceive(toolbarModel.$showProgress) { value in
            showProgress = value
        }
        .onReceive(toolbarModel.$websiteLoadProgress) { value in
            websiteLoadProgress = value
        }
        .onReceive(searchBarModel.$showSuggestions) { value in
            showSearchSuggestions = value
        }
        .onReceive(searchBarModel.$searchText) { value in
            searchQuery = value
        }
        .onReceive(searchBarModel.$searchViewState.dropFirst(1)) { value in
            searchBarState = value
        }
    }
}

#if DEBUG
class DummyDelegate: BrowserContentCoordinators {
    let topSitesCoordinator: TopSitesCoordinator? = nil
    let webContentCoordinator: WebContentCoordinator? =  nil
    let globalMenuDelegate: GlobalMenuDelegate? = nil
    let toolbarCoordinator: MainToolbarCoordinator? = nil
    let toolbarPresenter: AnyViewController? = nil
}

struct MainBrowserView_Previews: PreviewProvider {
    static var previews: some View {
        let model = MainBrowserModel(DummyDelegate())
        MainBrowserView(model: model)
    }
}
#endif
