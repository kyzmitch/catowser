//
//  ServiceLocator.swift
//  catowser
//
//  Created by Andrey Ermoshin on 04.01.2024.
//  Copyright © 2024 Cotton (former Catowser). All rights reserved.
//

import Foundation

protocol ServiceLocator: AnyObject {
    /// Searches for the service instance based on the object identifier which can be
    /// computed automatically and if it is not possible to compute it,
    /// (e.g. complex protocol types with primary associated type)
    /// any consumer can try to register or find the instance using simple string key
    ///
    /// @param type of the service which instance need to find
    /// @param key A string key if the service instance was registered not using type object id
    /// @return a reference to already stored object instance found by the key or type or nil if it wasn't registered
    func findService<T>(_ type: T.Type, _ key: String?) -> T?
}
