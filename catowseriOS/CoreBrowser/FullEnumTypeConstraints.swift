//
//  FullEnumTypeConstraints.swift
//  catowser
//
//  Created by Andrey Ermoshin on 23.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

/// An enumeration type which support default value
public protocol EnumDefaultValueSupportable where Self: CaseIterable {
    /// Default enum value
    var defaultValue: Self { get }
}

/// Combination of all needed enumeration related interfaces
public typealias FullEnumTypeConstraints = CaseIterable & RawRepresentable & EnumDefaultValueSupportable & Sendable
