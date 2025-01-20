//
//  TopSitesView.swift
//  catowser
//
//  Created by Andrei Ermoshin on 12/17/22.
//  Copyright © 2022 Cotton (former Catowser). All rights reserved.
//

import SwiftUI
import CottonViewModels
import ComposableArchitecture

/// Generic top sites view
struct TopSitesView: View {
    /// Selected swiftUI mode which is set at app start
    private let mode: SwiftUIMode
    /// Reducer
    private let reducer: TopSitesReducer

    init(
        _ mode: SwiftUIMode,
        _ reducer: TopSitesReducer
    ) {
        self.mode = mode
        self.reducer = reducer
    }

    var body: some View {
        WithPerceptionTracking {
            switch mode {
            case .compatible:
                TopSitesLegacyView()
            case .full:
                TopSitesViewV2(store: Store(
                    initialState: .loading,
                    reducer: {
                        reducer
                    })
                )
            }
        }
    }
}
