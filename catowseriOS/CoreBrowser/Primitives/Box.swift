//
//  Box.swift
//  catowser
//
//  Created by Andrei Ermoshin on 2/21/19.
//  Copyright © 2019 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import Foundation

/// Wrapper type to be able to have mutable associated values for enum cases
/// Source: https://stackoverflow.com/a/36765426
///
/// This can't be sendable (because of mutable value field) which is too bad,
/// so that, now, this smart type is not used anymore,
/// originally it was usefull for the Tabs Previews state.
public final class Box<T>: CustomDebugStringConvertible {
    public var value: T
    public var debugDescription: String { return "\(value)" }
    public init(_ value: T) { self.value = value }
}

extension Box: Equatable where T: Equatable {
    public static func == (lhs: Box<T>, rhs: Box<T>) -> Bool {
        lhs.value == rhs.value
    }
}
