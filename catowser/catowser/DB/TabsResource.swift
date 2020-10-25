//
//  TabsResource.swift
//  catowser
//
//  Created by Andrei Ermoshin on 9/28/20.
//  Copyright © 2020 andreiermoshin. All rights reserved.
//

import Foundation
import ReactiveSwift
import CoreBrowser
import CoreData

enum TabResourceError: Error {
    case zombieSelf
    case storeNotInitializedYet
    case dummyError
    case insertError(Error)
    case deleteError(Error)
    case fetchAllError(Error)
}

fileprivate extension String {
    static let threadName = "tabsStore"
}

final class TabsResource {
    private var store: TabsStore
    
    /// Needs to be checked on every access to `store` to not use wrong context
    /// functions can return empty data if it's not initialized state
    private var isStoreInitialized = false
    
    private let queue: DispatchQueue = .init(label: .queueNameWith(suffix: .threadName))
    
    private lazy var scheduler = QueueScheduler(targeting: queue)
    
    /// Creates an instance of TabsResource which is a wrapper around CoreData Store class
    ///
    /// - Parameters:
    ///   - temporaryContext: Temporary core data context to be able to compile init.
    ///   For valid instance we must create Core Data context on
    ///   specific thread to keep using it only with this thread.
    ///   - privateContextCreator: We have to call this closure on specific thread and use same thread for any other usages of this context.
    init(temporaryContext: NSManagedObjectContext, privateContextCreator: @escaping () -> NSManagedObjectContext?) {
        // Creating temporary instance to be able to use background thread
        // to properly create private CoreData context
        let dummyStore: TabsStore = .init(temporaryContext)
        store = dummyStore
        queue.async { [weak self] in
            guard let self = self else {
                fatalError("Tabs Resource is nil in init")
            }
            guard let correctContext = privateContextCreator() else {
                fatalError("Tabs Resource closure returns no private CoreData context")
            }
            self.store = .init(correctContext)
            self.isStoreInitialized = true
        }
    }
    
    func remember(tab: Tab) -> SignalProducer<Void, TabResourceError> {
        let producer: SignalProducer<Void, TabResourceError> = .init { [weak self] (observer, lifetime) in
            guard let self = self else {
                observer.send(error: .zombieSelf)
                return
            }
            guard self.isStoreInitialized else {
                observer.send(error: .storeNotInitializedYet)
                return
            }
            
            do {
                try self.store.insert(tab: tab)
                observer.send(value: ())
                observer.sendCompleted()
            } catch {
                observer.send(error: .insertError(error))
            }
            
        }
        
        return producer.observe(on: scheduler)
    }
    
    func forget(tab: Tab) -> SignalProducer<Void, TabResourceError> {
        let producer: SignalProducer<Void, TabResourceError> = .init { [weak self] (observer, lifetime) in
            guard let self = self else {
                observer.send(error: .zombieSelf)
                return
            }
            guard self.isStoreInitialized else {
                observer.send(error: .storeNotInitializedYet)
                return
            }
            
            do {
                try self.store.remove(tab: tab)
                observer.send(value: ())
                observer.sendCompleted()
            } catch {
                observer.send(error: .deleteError(error))
            }
            
        }
        return producer.observe(on: scheduler)
    }
    
    func tabsFromLastSession() -> SignalProducer<[Tab], TabResourceError> {
        let producer: SignalProducer<[Tab], TabResourceError> = .init { [weak self] (observer, lifetime) in
            guard let self = self else {
                observer.send(error: .zombieSelf)
                return
            }
            guard self.isStoreInitialized else {
                observer.send(error: .storeNotInitializedYet)
                return
            }
            
            do {
                let tabs = try self.store.fetchAllTabs()
                observer.send(value: tabs)
                observer.sendCompleted()
            } catch {
                observer.send(error: .fetchAllError(error))
            }
            
        }
        return producer.observe(on: scheduler)
    }
}
