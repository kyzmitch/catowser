//
//  Feature.swift
//  FeaturesFlagsKit
//
//  Created by Andrei Ermoshin on 2/22/20.
//  Copyright © 2020 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import Foundation

/// Represents basic types (no enumeration types, see EnumFeature instead)
public protocol Feature {
    associatedtype Value: Sendable

    static var source: FeatureSource.Type { get }
    static var defaultValue: Value { get }
    static var key: String { get }
    static var name: String { get }
    static var description: String { get }
}

extension Feature {
    public static var name: String {
        return key
    }
    public static var description: String {
        return "\(name) feature"
    }
}

/// A wrapper type for "syntatic sugar"
public struct ApplicationFeature<F: Feature>: Sendable {
    public var defaultValue: F.Value {
        return F.defaultValue
    }

    public init() {}
}
