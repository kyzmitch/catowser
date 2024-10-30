//
//  WeakWrapper.swift
//  catowser
//
//  Created by Andrey Ermoshin on 30.10.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

/// Allows to avoid using of NSHashTable for storing weak references
final class Weak<T: AnyObject> {
    weak var value: T?
    init(_ value: T) {
        self.value = value
    }
}
