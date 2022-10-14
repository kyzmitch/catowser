//
//  FeatureManager+SpecificEnums.swift
//  catowser
//
//  Created by Andrei Ermoshin on 2/28/22.
//  Copyright © 2022 andreiermoshin. All rights reserved.
//

import CoreBrowser
import FeaturesFlagsKit

// MARK: - generic GETTER method

extension FeatureManager {
    static func enumValue<F: FullEnumTypeConstraints>(_ enumCase: F) -> F?
    where F.RawValue == Int {
        let keyStr: String
        switch enumCase.defaultValue {
        case is WebAutoCompletionSource:
            keyStr = .autoCompletionKey
        case is AddedTabPosition:
            keyStr = .tabAddPositionKey
        case is TabContentDefaultState:
            keyStr = .tabDefaultContentKey
        case is AsyncApiType:
            keyStr = .browserAsyncApiKey
        default:
            assertionFailure("Attempt to search for not supported enum feature type")
            return nil
        }
        return enumValue(enumCase, keyStr)
    }
}

// MARK: - GETTER methods specific to Enum features

extension FeatureManager {
    static func tabAddPositionValue() -> AddedTabPosition {
        let feature: ApplicationEnumFeature = .tabAddPosition
        guard let source = source(for: feature) else {
            return feature.defaultEnumValue
        }
        return source.currentEnumValue(of: feature)
    }
    
    static func tabDefaultContentValue() -> TabContentDefaultState {
        let feature: ApplicationEnumFeature = .tabDefaultContent
        guard let source = source(for: feature) else {
            return feature.defaultEnumValue
        }
        return source.currentEnumValue(of: feature)
    }
    
    static func appAsyncApiTypeValue() -> AsyncApiType {
        let feature: ApplicationEnumFeature = .appDefaultAsyncApi
#if DEBUG
        guard let source = source(for: feature) else {
            return feature.defaultEnumValue
        }
        return source.currentEnumValue(of: feature)
#else
        // We don't need to change this in Release builds
        return feature.defaultEnumValue
#endif
    }
    
    static func webSearchAutoCompleteValue() -> WebAutoCompletionSource {
        let feature: ApplicationEnumFeature = .webAutoCompletionSource
        guard let source = source(for: feature) else {
            return feature.defaultEnumValue
        }
        return source.currentEnumValue(of: feature)
    }
}
