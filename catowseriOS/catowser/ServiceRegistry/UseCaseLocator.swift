//
//  UseCaseLocator.swift
//  catowser
//
//  Created by Andrey Ermoshin on 04.01.2024.
//  Copyright © 2024 Cotton (former Catowser). All rights reserved.
//

import DataServiceKit

/// Service locator for the use cases
public final class UseCaseLocator: LazyServiceLocator {
    /// Init
    public override init() {}
    
    /// Register a closure which could create an instance of a use case
    /// - Parameter instance: an instance (without generic parameters) which is stored by the specific metatype id
    public func register<T: BaseUseCase>(_ recipe: @escaping () -> T) {
        super.register(recipe)
    }
    
    /// Register an instance of a use case
    /// - Parameter instance: an instance (without generic parameters) which is stored by the specific metatype id
    public func register<T: BaseUseCase>(_ instance: T) {
        super.register(instance)
    }

    /// Register an instance using a string constant
    /// it is for the types with the generic parameters which are not
    /// convinient to store by specific metatype
    ///
    /// - Parameter instance: an object instance stored in a service locator
    /// - Parameter key: a string key to store an object instance
    public func registerNamed<T: BaseUseCase>(_ instance: T, _ key: String) {
        super.registerNamed(instance, key)
    }
    
    /// Register an instance using a concrete type metadata which can't be determined automatically
    ///
    /// - Parameter instance: an object instance stored in a service locator
    /// - Parameter type: a metatype to use as a unique key
    public func registerTyped<T: BaseUseCase>(_ instance: T, of type: Any.Type) {
        super.registerTyped(instance, of: type)
    }
}
