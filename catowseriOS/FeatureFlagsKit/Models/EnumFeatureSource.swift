//
//  EnumFeatureSource.swift
//  FeaturesFlagsKit
//
//  Created by Andrey Ermoshin on 26.02.2022.
//  Copyright © 2022 Cotton (former Catowser). All rights reserved.
//

/// Enumeration feature data source which also allows to set/save it.
public protocol EnumFeatureSource: Sendable {
    /// Read current enumeration value for specific feature.
    ///
    /// - Parameter feature: A future value with Integer base raw type.
    /// - Returns enumeration value for that feature.
    func currentEnumValue<F: EnumFeature>(
        of feature: ApplicationEnumFeature<F>
    ) async -> F.EnumValue where F.EnumValue.RawValue == Int

    /// Write current enumeration value for specific feature.
    ///
    /// - Parameter feature: A future value with Integer base raw type.
    /// - Parameter value: An optional enumeration value, if it is nil then erase it.
    func setEnumValue<F: EnumFeature>(
        of feature: ApplicationEnumFeature<F>,
        value: F.EnumValue?
    ) async where F.EnumValue.RawValue == Int
}
