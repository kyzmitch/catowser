//
//  TopSitesViewV2.swift
//  catowser
//
//  Created by Andrei Ermoshin on 4/24/23.
//  Copyright © 2023 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import SwiftUI
import CottonBase
import CoreBrowser
import CottonViewModels
import ComposableArchitecture

struct TopSitesViewV2: View {
    @State private var selected: Site?
    @ComposableArchitecture.Bindable var store: StoreOf<TopSitesReducer>

    /// Number of items which will be displayed in a row
    private let columns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        WithPerceptionTracking {
            Group {
                switch store.state {
                case .loading:
                    ProgressView()
                case .loaded(let topSites):
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: ImageViewSizes.spacing) {
                            ForEach(topSites) { TitledImageView($0, $selected) }
                        }
                    }
                    .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                    .onChange(of: selected) { newValue in
                        guard let newValue else {
                            return
                        }
                        store.send(.selectSite(.site(newValue)))
                    }
                @unknown default:
                    EmptyView()
                }
            }
            .onAppear {
                store.send(.fetchSites)
            }
        }
    }
}
