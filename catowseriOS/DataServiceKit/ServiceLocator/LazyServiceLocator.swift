//
//  LazyServiceLocator.swift
//  catowser
//
//  Created by Andrey Ermoshin on 04.01.2024.
//  Copyright © 2024 Cotton (former Catowser). All rights reserved.
//

import Foundation

/// Registry record
enum ServiceRecord {
    case instance(Any)
    case fromClosure(() -> Any)

    func unwrap() -> Any {
        switch self {
        case .instance(let instance):
            return instance
        case .fromClosure(let recipe):
            return recipe()
        }
    }
}

/// Lazy base service locator
open class LazyServiceLocator {
    private lazy var idByRecord: [ObjectIdentifier: ServiceRecord] = [:]
    private lazy var stringByRecord: [String: ServiceRecord] = [:]
    
    /// Constructor
    public init() { }
    
    /// Register a closure which could create an instance of a certain type
    /// - Parameter instance: an instance (without generic parameters) which is stored by the specific metatype id
    public func register<T>(_ recipe: @escaping () -> T) {
        let key = ObjectIdentifier(type(of: T.self))
        idByRecord[key] = .fromClosure(recipe)
    }
    
    /// Register an instance of a certain type
    /// - Parameter instance: an instance (without generic parameters) which is stored by the specific metatype id
    public func register<T>(_ instance: T) {
        let type = type(of: instance)
        let key = ObjectIdentifier(type)
        idByRecord[key] = .instance(instance)
    }
    
    /// Register an instance using a string constant
    /// it is for the types with the generic parameters which are not
    /// convinient to store by specific metatype
    ///
    /// - Parameter instance: an object instance stored in a service locator
    /// - Parameter key: a string key to store an object instance
    public func registerNamed<T>(_ instance: T, _ key: String) {
        stringByRecord[key] = .instance(instance)
    }
    
    /// Register an instance using a concrete type metadata which can't be determined automatically
    ///
    /// - Parameter instance: an object instance stored in a service locator
    /// - Parameter type: a metatype to use as a unique key
    public func registerTyped<T>(_ instance: T, of type: Any.Type) {
        let key = ObjectIdentifier(type)
        idByRecord[key] = .instance(instance)
    }
}

extension LazyServiceLocator: ServiceLocator {
    /// Searches for the service instance based on the object identifier which can be
    /// computed automatically and if it is not possible to compute it,
    /// (e.g. complex protocol types with primary associated type)
    /// any consumer can try to register or find the instance using simple string key
    ///
    /// @param type of the service which instance need to find
    /// @param key A string key if the service instance was registered not using type object id
    /// @return a reference to already stored object instance found by the key or type or nil if it wasn't registered
    public func findService<T>(_ type: T.Type, _ key: String? = nil) -> T? {
        let id = ObjectIdentifier(type)
        var instance: T?

        /// internal closure
        func handle<B>(_ registryRec: ServiceRecord) -> B? {
            let instance: B? = registryRec.unwrap() as? B
            /// Replace the recipe with the produced instance if this is the case
            switch registryRec {
            case .fromClosure:
                if let instance = instance {
                    register(instance)
                }
            default:
                break
            }
            return instance
        }

        if let registryRec = idByRecord[id] {
            instance = handle(registryRec)
        } else if let recordKey = key, let registryRec = stringByRecord[recordKey] {
            instance = handle(registryRec)
        }
        return instance
    }
}
