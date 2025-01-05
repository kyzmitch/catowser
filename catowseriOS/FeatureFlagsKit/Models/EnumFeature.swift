//
//  EnumFeature.swift
//  FeaturesFlagsKit
//
//  Created by Andrey Ermoshin on 26.02.2022.
//  Copyright © 2022 Cotton (former Catowser). All rights reserved.
//

import CoreBrowser

/// Feature interface specifically for enumeration based values.
///
/// Should be used for generic enum types, so that, no static properties are allowed.
/// Can't be a subset of a `BasicFeature` or `Feature` which have static properties.
public protocol EnumFeature: Sendable {
    /// Type of enumeration
    associatedtype EnumValue: FullEnumTypeConstraints
    /// Raw type of enumeration
    associatedtype RawValue where RawValue == EnumValue.RawValue

    /// Default enumeration value
    var defaultEnumValue: EnumValue { get }
    /// Default raw value of enumeration (for convinience)
    var defaultRawValue: RawValue { get }
    /// Data source for this enumeration feature
    var source: EnumFeatureSource.Type { get }
    /// String key to store enumeration value.
    var key: String { get }
    /// String name of feature, could be the same with a key.
    var name: String { get }
    /// Debug or developer menu description of the feature.
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

/// Application enumeration feature.
public struct ApplicationEnumFeature<F: EnumFeature>: Sendable {
    let feature: F

    /// Initializer
    /// - Parameter feature: A feature.
    public init(feature: F) {
        self.feature = feature
    }

    /// Default raw value
    public var defaultValue: F.RawValue {
        return feature.defaultRawValue
    }

    /// Default enum value
    public var defaultEnumValue: F.EnumValue {
        return feature.defaultEnumValue
    }
}
