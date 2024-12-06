//
//  EnumFeatureSource.swift
//  FeaturesFlagsKit
//
//  Created by Andrey Ermoshin on 26.02.2022.
//  Copyright © 2022 Cotton (former Catowser). All rights reserved.
//

public protocol EnumFeatureSource: Sendable {
    func currentEnumValue<F: EnumFeature>(
        of feature: ApplicationEnumFeature<F>
    ) async -> F.EnumValue where F.EnumValue.RawValue == Int

    func setEnumValue<F: EnumFeature>(
        of feature: ApplicationEnumFeature<F>,
        value: F.EnumValue?
    ) async where F.EnumValue.RawValue == Int
}
