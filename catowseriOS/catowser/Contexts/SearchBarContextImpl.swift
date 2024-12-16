//
//  SearchBarContextImpl.swift
//  catowser
//
//  Created by Andrey Ermoshin on 16.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import CoreBrowser
import CottonViewModels
import FeatureFlagsKit

final class SearchBarContextImpl: SearchBarContext {
    init() {}

    var blockPopups: Bool {
        DefaultTabProvider.shared.blockPopups
    }
    
    var isJSEnabled: Bool {
        get async {
            await FeatureManager.shared.boolValue(of: .javaScriptEnabled)
        }
    }
    
    var webAutocompletionSourceValue: WebAutoCompletionSource {
        get async {
            await FeatureManager.shared.webSearchAutoCompleteValue()
        }
    }
}
