//
//  BasicFeature.swift
//  FeaturesFlagsKit
//
//  Created by Andrey Ermoshin on 26.02.2022.
//  Copyright © 2022 Cotton (former Catowser). All rights reserved.
//

import Foundation

public protocol BasicFeature: Feature where Value: RawFeatureValue { }

// Unless specified all Basic Features will be local
extension BasicFeature {
    public static var source: FeatureSource.Type {
        return LocalFeatureSource.self
    }
}
