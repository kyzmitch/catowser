//
//  GenericEnumFeature.swift
//  FeaturesFlagsKit
//
//  Created by Andrey Ermoshin on 26.02.2022.
//  Copyright © 2022 Cotton (former Catowser). All rights reserved.
//

import CoreBrowser
import Foundation

public struct GenericEnumFeature<E: FullEnumTypeConstraints>: EnumFeature, Sendable where E.RawValue == Int {
    public typealias RawValue = E.RawValue
    public typealias EnumValue = E

    let wrappedEnumValue: EnumValue

    public var defaultEnumValue: EnumValue {
        return wrappedEnumValue.defaultValue
    }

    public var defaultRawValue: RawValue {
        return defaultEnumValue.rawValue
    }

    public let key: String

    public init(_ key: String) {
        // swiftlint:disable:next force_unwrapping
        wrappedEnumValue = E.allCases.first!
        self.key = key
    }
}
