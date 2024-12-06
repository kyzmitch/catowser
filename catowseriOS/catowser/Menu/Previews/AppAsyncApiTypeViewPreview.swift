//
//  AppAsyncApiTypeViewPreview.swift
//  catowser
//
//  Created by Andrey Ermoshin on 15.02.2022.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import FeatureFlagsKit
import SwiftUI

#if DEBUG
struct AppAsyncApiTypeView_Previews: PreviewProvider {
    static var previews: some View {
        let model: AppAsyncApiTypeModel = .init(nil) { (_) in
            //
        }
        return BaseMenuView<AsyncApiType>(viewModel: model)
    }
}
#endif
