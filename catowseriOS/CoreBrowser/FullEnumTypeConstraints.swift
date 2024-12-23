//
//  FullEnumTypeConstraints.swift
//  catowser
//
//  Created by Andrey Ermoshin on 23.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

public protocol EnumDefaultValueSupportable where Self: CaseIterable {
    var defaultValue: Self { get }
}

public typealias FullEnumTypeConstraints = CaseIterable & RawRepresentable & EnumDefaultValueSupportable & Sendable
