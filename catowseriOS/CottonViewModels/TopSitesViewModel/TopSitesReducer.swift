//
//  TopSitesReducer.swift
//  catowser
//
//  Created by Andrey Ermoshin on 16.01.2025.
//  Copyright © 2025 Cotton (Catowser). All rights reserved.
//

import ComposableArchitecture
import CottonBase
import CoreBrowser
import CottonUseCases

/// Top sites reducer.
///
/// View model analog from MVVM using composable arhitecture framework.
@Reducer public struct TopSitesReducer: Sendable {
    @ObservableState public enum State: Equatable {
        /// Initial state
        case loading
        /// Preferred state
        case loaded([Site])
    }
    
    public enum Action {
        // MARK: - API actions
        
        /// Load data or preferred state
        case fetchSites
        /// Side effect of replacing content in currently selected tab
        case selectSite(CoreBrowser.Tab.ContentType)
        
        // MARK: - internal actions
        
        /// Save loaded data to transit to the next state
        case handleSites([Site])
        /// Site was selected, now need to close the top sites (this screen)
        case closeTopSites
    }
    
    private let writeTabUseCase: WriteTabsUseCase
    private let appContext: TopSitesAppContext
    
    private enum CancelID {
        case replaceSelected
        case fetchSites
    }
    
    public init(
        _ appContext: TopSitesAppContext,
        _ writeTabUseCase: WriteTabsUseCase
    ) {
        self.appContext = appContext
        self.writeTabUseCase = writeTabUseCase
    }
    
    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .fetchSites:
                return .run { send in
                    let sites = await appContext.topSites()
                    await send(.handleSites(sites))
                }.cancellable(id: CancelID.fetchSites)
            case .selectSite(let content):
                if case let .topSites = content {
                    return .none
                } else {
                    return .run { send in
                        try await writeTabUseCase.replaceSelected(content)
                        await send(.closeTopSites)
                    }.cancellable(id: CancelID.replaceSelected)
                }
            case .handleSites(let sites):
                state = .loaded(sites)
                return .none
            case .closeTopSites:
                #warning("TODO: dismiss the view")
                return .none
            }
        }
    }
}
