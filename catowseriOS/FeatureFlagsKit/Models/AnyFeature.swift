//
//  AnyFeature.swift
//  FeaturesFlagsKit
//
//  Created by Andrey Ermoshin on 26.02.2022.
//  Copyright © 2022 Cotton (former Catowser). All rights reserved.
//

import Foundation

/// Feature description.
/// Wrapper around generic ApplicationFeature to get rid of template
struct AnyFeature: Equatable {
    private let featureType: Any.Type
    private let key: String
    init<F: Feature>(_ featureType: F.Type) {
        self.key = F.key
        self.featureType = featureType
    }

    init<F>(_ feature: ApplicationFeature<F>) {
        self.key = F.key
        self.featureType = F.self
    }

    init<E: EnumFeature>(_ feature: E) {
        key = feature.key
        featureType = E.self
    }

    init<E>(_ enumFeature: ApplicationEnumFeature<E>) {
        key = enumFeature.feature.key
        featureType = type(of: enumFeature.feature)
    }

    static func == (lhs: AnyFeature, rhs: AnyFeature) -> Bool {
        return lhs.featureType == rhs.featureType
    }

    static func == <F>(lhs: AnyFeature, rhs: ApplicationFeature<F>) -> Bool {
        return lhs == AnyFeature(rhs)
    }

    static func == <F>(lhs: ApplicationFeature<F>, rhs: AnyFeature) -> Bool {
        return AnyFeature(lhs) == rhs
    }

    static func == <E>(lhs: AnyFeature, rhs: ApplicationEnumFeature<E>) -> Bool {
        return lhs == AnyFeature(rhs)
    }

    static func == <E>(lhs: ApplicationEnumFeature<E>, rhs: AnyFeature) -> Bool {
        return AnyFeature(lhs) == rhs
    }
}
