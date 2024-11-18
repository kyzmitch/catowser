//
//  RawFeatureValue.swift
//  FeaturesFlagsKit
//
//  Created by Andrey Ermoshin on 26.02.2022.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import Foundation

// MARK: - Raw types of features we support

/// Marker protocol for the possible feature value types
public protocol RawFeatureValue {}

extension Bool: RawFeatureValue {}
extension Int: RawFeatureValue {}
extension String: RawFeatureValue {}
