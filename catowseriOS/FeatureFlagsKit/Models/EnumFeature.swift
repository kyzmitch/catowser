//
//  EnumFeature.swift
//  FeaturesFlagsKit
//
//  Created by Andrey Ermoshin on 26.02.2022.
//  Copyright © 2022 Cotton (former Catowser). All rights reserved.
//

import Foundation

/// Should be used for generic enum types, so, no static properties are allowed
/// Can't be a subset of a `BasicFeature` or `Feature` which have static properties
public protocol EnumFeature: Sendable {
    associatedtype EnumValue: CaseIterable & RawRepresentable & Sendable
    associatedtype RawValue where EnumValue.RawValue == RawValue

    var defaultEnumValue: EnumValue { get }
    var defaultRawValue: RawValue { get }
    var source: EnumFeatureSource.Type { get }
    var key: String { get }
    var name: String { get }
    var description: String { get }
}

extension EnumFeature {
    public var source: EnumFeatureSource.Type {
        return LocalFeatureSource.self
    }
    public var name: String {
        return key
    }
    public var description: String {
        return "\(name) feature"
    }
}

public struct ApplicationEnumFeature<F: EnumFeature>: Sendable {
    let feature: F

    public init(feature: F) {
        self.feature = feature
    }

    public var defaultValue: F.RawValue {
        return feature.defaultRawValue
    }

    public var defaultEnumValue: F.EnumValue {
        return feature.defaultEnumValue
    }
}
