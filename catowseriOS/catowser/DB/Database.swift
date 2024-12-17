//
//  Database.swift
//  catowser
//
//  Created by Andrei Ermoshin on 9/28/20.
//  Copyright © 2020 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import Atomics
import Foundation
import CoreData

enum DbError: Error {
    case zombieInstance
}

/// A Database class, can't be an actor for now because,
/// private core data managed context must be initialised and used
/// on the same dispatch queue or thread and not clear how to
/// use it if it is created from an actor.
///
/// Also, NSManagedObjectContext class is not sendable for an actor.
final class Database: Sendable {

    /// The default directory for the persistent stores on the current platform.
    ///
    /// - Returns: An `NSURL` for the directory containing the persistent
    ///   store(s). If the persistent store does not exist it will be created
    ///   by default in this location when loaded.

    static private func defaultDirectoryURL() -> URL {
        NSPersistentContainer.defaultDirectoryURL()
    }

    /// A read-only flag indicating if the persistent store is loaded.
    /// Can be nonisolated unsafe, because it is a Scalar bool type.
    let isStoreLoaded = ManagedAtomic(false)

    /// The managed object context associated with the main queue (read-only).
    /// To perform tasks on a private background queue see
    /// `performBackgroundTask:` and `newPrivateContext`.
    ///
    /// The context is configured to be generational and to automatically
    /// consume save notifications from other contexts.
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    /// The `URL` of the persistent store for this Core Data Stack. If there
    /// is more than one store this property returns the first store it finds.
    /// The store may not yet exist. It will be created at this URL by default
    /// when first loaded.
    ///
    /// This is a readonly property to create a persistent store in a different
    /// location use `loadStoreAtURL:withCompletionHandler`. To move an existing
    ///  persistent store use
    /// `replacePersistentStoreAtURL:withPersistentStoreFromURL:`.
    private var storeURL: URL? {
        var url: URL?
        let descriptions = persistentContainer.persistentStoreDescriptions
        if let firstDescription = descriptions.first {
            url = firstDescription.url
        }
        return url
    }

    /// A flag that indicates whether this store is read-only. Set this value
    /// to YES before loading the persistent store if you want a read-only
    /// store (for example if loading from the application bundle).
    /// Default is false.
    ///
    /// Can be nonisolated unsafe, because it is a Scalar bool type.
    private let isReadOnly = ManagedAtomic(false)

    /// A flag that indicates whether the store is added asynchronously.
    /// Set this value before loading the persistent store.
    /// Default is true.
    ///
    /// Can be nonisolated unsafe, because it is a Scalar bool type.
    private let shouldAddStoreAsynchronously = ManagedAtomic(false)

    /// A flag that indicates whether the store should be migrated
    /// automatically if the store model version does not match the
    /// coordinators model version.
    /// Set this value before loading the persistent store.
    /// Default is true.
    ///
    /// Can be nonisolated unsafe, because it is a Scalar bool type.
    private let shouldMigrateStoreAutomatically = ManagedAtomic(true)

    /// A flag that indicates whether a mapping model should be inferred
    /// when migrating a store.
    /// Set this value before loading the persistent store.
    /// Default is true.
    ///
    /// Can be nonisolated unsafe, because it is a Scalar bool type.
    private let shouldInferMappingModelAutomatically = ManagedAtomic(true)

    /// Creates and returns a `CoreDataController` object. This is the designated
    /// initializer for the class. It creates the managed object model,
    /// persistent store coordinator and main managed object context but does
    /// not load the persistent store.
    ///
    /// The managed object model should be in the same bundle as this class.
    ///
    /// - Parameter name: The name of the persistent store.
    ///
    /// - Returns: A `CoreDataController` object or nil if the model
    ///   could not be loaded.
    init?(name: String) {
        let bundle = Bundle(for: Database.self)
        guard let mom = NSManagedObjectModel.mergedModel(from: [bundle]) else {
            return nil
        }

        persistentContainer = NSPersistentContainer(name: name, managedObjectModel: mom)
    }

    /// A flag indicating if the persistent store exists at the specified URL.
    ///
    /// - Parameter storeURL: An `NSURL` object for the location of the
    ///   peristent store.
    ///
    /// - Returns: true if a file exists at the specified URL otherwise false.
    ///
    /// - Warning: This method checks if a file exists at the specified
    ///   location but does not verify if it is a valid persistent store.
    private func persistentStoreExists(at storeURL: URL) -> Bool {
        if storeURL.isFileURL &&
            FileManager.default.fileExists(atPath: storeURL.path) {
            return true
        }
        return false
    }

    /// Destroy a persistent store.
    ///
    /// - Parameter storeURL: An `NSURL` for the persistent store to be
    ///   destroyed.
    /// - Returns: A flag indicating if the operation was successful.
    /// - Throws: If the store cannot be destroyed.
    private func destroyPersistentStore(at storeURL: URL) throws {
        let psc = persistentContainer.persistentStoreCoordinator
        try psc.destroyPersistentStore(at: storeURL, ofType: NSSQLiteStoreType, options: nil)
    }

    /// Replace a persistent store.
    ///
    /// - Parameter destinationURL: An `NSURL` for the persistent store to be
    ///   replaced.
    /// - Parameter sourceURL: An `NSURL` for the source persistent store.
    /// - Returns: A flag indicating if the operation was successful.
    /// - Throws: If the persistent store cannot be replaced.
    private func replacePersistentStore(at url: URL, withPersistentStoreFrom sourceURL: URL) throws {
        let psc = persistentContainer.persistentStoreCoordinator
        try psc.replacePersistentStore(at: url, destinationOptions: nil,
                                       withPersistentStoreFrom: sourceURL, sourceOptions: nil, ofType: NSSQLiteStoreType)
    }

    /// Create and return a new private queue `NSManagedObjectContext`. The
    /// new context is set to consume `NSManagedObjectContextSave` broadcasts
    /// automatically.
    ///
    /// - Returns: A new private managed object context
    func newPrivateContext() -> NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }

    /// Execute a block on a new private queue context.
    ///
    /// - Parameter block: A block to execute on a newly created private
    ///   context. The context is passed to the block as a parameter.

    private func performBackgroundTask(block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask(block)
    }

    /// Return an object ID for the specified URI representation if a matching
    /// store is available.
    ///
    /// - Parameter storeURL: An `NSURL` containing a URI of a managed object.
    /// - Returns: An optional `NSManagedObjectID`.
    private func managedObjectID(forURIRepresentation storeURL: URL) -> NSManagedObjectID? {
        let psc = persistentContainer.persistentStoreCoordinator
        return psc.managedObjectID(forURIRepresentation: storeURL)
    }

    private let persistentContainer: NSPersistentContainer

    private func storeDescription(with url: URL) -> NSPersistentStoreDescription {
        let description = NSPersistentStoreDescription(url: url)
        description.shouldMigrateStoreAutomatically = shouldMigrateStoreAutomatically.load(ordering: .relaxed)
        description.shouldInferMappingModelAutomatically = shouldInferMappingModelAutomatically.load(ordering: .relaxed)
        description.shouldAddStoreAsynchronously = shouldAddStoreAsynchronously.load(ordering: .relaxed)
        description.isReadOnly = isReadOnly.load(ordering: .relaxed)
        return description
    }

    /// Load the persistent store from the default location.
    func loadStore() async throws {
        if let storeURL {
            let description = storeDescription(with: storeURL)
            persistentContainer.persistentStoreDescriptions = [description]
        }

        let result: Void = try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self else {
                continuation.resume(with: .failure(DbError.zombieInstance))
                return
            }
            persistentContainer.loadPersistentStores { [weak self] (_, error) in
                if let error {
                    continuation.resume(with: .failure(error))
                } else {
                    self?.isStoreLoaded.store(true, ordering: .relaxed)
                    continuation.resume(with: .success(()))
                }
            }
        }
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        return result
    }
}
