//
//  DataServiceLocator.swift
//  catowser
//
//  Created by Andrey Ermoshin on 04.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//


import Foundation

/// Service locator for the use cases
public final class DataServiceLocator: LazyServiceLocator {
    /// Init
    public override init() {}
    
    /// Register a closure which could create an instance of a use case
    /// - Parameter instance: an instance (without generic parameters) which is stored by the specific metatype id
    public func register<T: GenericDataServiceProtocol>(_ recipe: @escaping () -> T) {
        super.register(recipe)
    }
    
    /// Register an instance of a use case
    /// - Parameter instance: an instance (without generic parameters) which is stored by the specific metatype id
    public func register<T: GenericDataServiceProtocol>(_ instance: T) {
        super.register(instance)
    }

    /// Register an instance using a string constant
    /// it is for the types with the generic parameters which are not
    /// convinient to store by specific metatype
    ///
    /// - Parameter instance: an object instance stored in a service locator
    /// - Parameter key: a string key to store an object instance
    public func registerNamed<T: GenericDataServiceProtocol>(_ instance: T, _ key: String) {
        super.registerNamed(instance, key)
    }
    
    /// Register an instance using a concrete type metadata which can't be determined automatically
    ///
    /// - Parameter instance: an object instance stored in a service locator
    /// - Parameter type: a metatype to use as a unique key
    public func registerTyped<T: GenericDataServiceProtocol>(_ instance: T, of type: Any.Type) {
        super.registerTyped(instance, of: type)
    }
}
