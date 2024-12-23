//
//  BaseMenuView.swift
//  catowser
//
//  Created by Andrei Ermoshin on 2/21/22.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import SwiftUI
import CoreBrowser
import CottonViewModels
import FeatureFlagsKit

typealias SwiftUIValueRequirements = Hashable & Identifiable & CustomStringConvertible

struct BaseMenuView<SourceType: FullEnumTypeConstraints & SwiftUIValueRequirements>: View
where SourceType.RawValue == Int, SourceType.AllCases: RandomAccessCollection {

    let viewModel: BaseListViewModelImpl<SourceType>

    var body: some View {
        List(viewModel.dataSource) { selectedCase in
            if selectedCase == self.viewModel.selected {
                Text(selectedCase.description)
                    .font(Font.headline)
                    .onTapGesture {
                        self.viewModel.onPop(selectedCase)
                    }
            } else {
                Text(selectedCase.description)
                    .onTapGesture {
                        self.viewModel.onPop(selectedCase)
                    }
            }
        }
        .navigationBarTitle(Text(verbatim: viewModel.viewTitle))
    }
}
