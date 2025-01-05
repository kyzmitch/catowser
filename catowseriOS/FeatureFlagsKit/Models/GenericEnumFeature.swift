//
//  GenericEnumFeature.swift
//  FeaturesFlagsKit
//
//  Created by Andrey Ermoshin on 26.02.2022.
//  Copyright © 2022 Cotton (former Catowser). All rights reserved.
//

import CoreBrowser
import Foundation

/// Generic enumeration based feature setting with Integer raw value
public struct GenericEnumFeature<E: FullEnumTypeConstraints>: EnumFeature, Sendable where E.RawValue == Int {
    /// Enum raw type which is integer
    public typealias RawValue = E.RawValue
    /// Enum type
    public typealias EnumValue = E

    let wrappedEnumValue: EnumValue

    /// Default enum value
    public var defaultEnumValue: EnumValue {
        return wrappedEnumValue.defaultValue
    }

    /// Default raw value
    public var defaultRawValue: RawValue {
        return defaultEnumValue.rawValue
    }

    /// Key string of enum type for current value
    public let key: String

    /// Init
    /// - Parameter key: key string
    public init(_ key: String) {
        // swiftlint:disable:next force_unwrapping
        wrappedEnumValue = E.allCases.first!
        self.key = key
    }
}
