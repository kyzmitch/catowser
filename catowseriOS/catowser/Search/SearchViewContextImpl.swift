//
//  SearchViewContextImpl.swift
//  catowser
//
//  Created by Andrei Ermoshin on 11/4/22.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import Foundation
import CottonData
import CottonViewModels
import CoreBrowser
import FeatureFlagsKit

struct SearchViewContextImpl: SearchViewContext {
    var knownDomainsStorage: KnownDomainsSource {
        InMemoryDomainSearchProvider.shared
    }

    var appAsyncApiTypeValue: AsyncApiType {
        get async {
            await FeatureManager.shared.appAsyncApiTypeValue()
        }
    }
    
    var webAutocompletionSourceValue: WebAutoCompletionSource {
        get async {
            await FeatureManager.shared.webSearchAutoCompleteValue()
        }
    }
}
