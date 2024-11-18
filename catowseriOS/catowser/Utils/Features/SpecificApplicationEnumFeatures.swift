//
//  SpecificApplicationEnumFeatures.swift
//  catowser
//
//  Created by Andrey Ermoshin on 26.02.2022.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import FeaturesFlagsKit

extension ApplicationEnumFeature {
    static var tabAddPosition: ApplicationEnumFeature<TabAddPositionFeature> {
        return ApplicationEnumFeature<TabAddPositionFeature>(feature: EnumFeaturesHolder.tabAddPosition)
    }
    static var tabDefaultContent: ApplicationEnumFeature<TabContentFeature> {
        return ApplicationEnumFeature<TabContentFeature>(feature: EnumFeaturesHolder.tabDefaultContent)
    }
    static var appDefaultAsyncApi: ApplicationEnumFeature<AppAsyncApiFeature> {
        return ApplicationEnumFeature<AppAsyncApiFeature>(feature: EnumFeaturesHolder.selectedAppAsyncApi)
    }
    static var webAutoCompletionSource: ApplicationEnumFeature<WebAutoCompletionFeature> {
        return ApplicationEnumFeature<WebAutoCompletionFeature>(feature: EnumFeaturesHolder.webAutoCompletionSource)
    }
    static var appDefaultUIFramework: ApplicationEnumFeature<UIFrameworkFeature> {
        return ApplicationEnumFeature<UIFrameworkFeature>(feature: EnumFeaturesHolder.selectedUIFramework)
    }
    static var observingApi: ApplicationEnumFeature<ObservingApiFeature> {
        return ApplicationEnumFeature<ObservingApiFeature>(feature: EnumFeaturesHolder.observingApiKey)
    }
}
