//
//  TabAddPositionsViewPreview.swift
//  catowser
//
//  Created by Andrei Ermoshin on 5/30/20.
//  Copyright © 2020 Cotton (former Catowser). All rights reserved.
//

import CoreBrowser
#if canImport(SwiftUI)
import SwiftUI
#endif
import CottonDataServices

#if DEBUG
struct TabAddPositionsView_Previews: PreviewProvider {
    static var previews: some View {
        let model: TabAddPositionsModel = .init(nil) { (_) in
            //
        }
        return BaseMenuView<AddedTabPosition>(viewModel: model)
    }
}
#endif
