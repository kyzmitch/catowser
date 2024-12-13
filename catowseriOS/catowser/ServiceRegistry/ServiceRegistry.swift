//
//  ServiceRegistry.swift
//  catowser
//
//  Created by Andrei Ermoshin on 5/1/20.
//  Copyright © 2020 Cotton (former Catowser). All rights reserved.
//

import DataServiceKit
import Foundation
import CottonRestKit
import CoreData
import CoreBrowser
import CottonNetworking
import Alamofire // only needed for `JSONEncoding`
import FeatureFlagsKit
import CottonDataServices

extension String {
    static let tabsDataServiceKey = "tabs.dataservice"
    static let searchDataServiceKey = "search.dataservice"
}

/// Service registry for the serial data services and other related classes
@globalActor final class ServiceRegistry {
    static let shared = StateHolder()

    actor StateHolder {
        /// locator for the data services
        private let dataServiceLocator: DataServiceLocator
        
        let dnsClient: GoogleDnsClient
        let googleClient: GoogleSuggestionsClient
        let duckduckgoClient: DDGoSuggestionsClient

        let dnsAlReachability: AlamofireReachabilityAdaptee<GoogleDnsServer>
        let googleAlReachability: AlamofireReachabilityAdaptee<GoogleServer>
        let ddGoAlReachability: AlamofireReachabilityAdaptee<DuckDuckGoServer>

        let googleClientRxSubscriber: GSearchClientRxSubscriber = .init()
        let googleClientSubscriber: GSearchClientSubscriber = .init()
        let duckduckgoClientSubscriber: DDGoSuggestionsClientSubscriber = .init()

        let dnsClientRxSubscriber: GDNSJsonClientRxSubscriber = .init()
        let dnsClientSubscriber: GDNSJsonClientSubscriber = .init()
        let duckduckgoClientRxSubscriber: DDGoSuggestionsClientRxSubscriber = .init()
        
        private var database: Database?

        init() {
            dataServiceLocator = DataServiceLocator()
            
            let googleDNSserver = GoogleDnsServer()
            // swiftlint:disable:next force_unwrapping
            dnsAlReachability = .init(server: googleDNSserver)!
            dnsClient = .init(
                server: googleDNSserver,
                jsonEncoder: JSONEncoding.default,
                reachability: dnsAlReachability,
                httpTimeout: 2
            )
            let googleServer = GoogleServer()
            // swiftlint:disable:next force_unwrapping
            googleAlReachability = .init(server: googleServer)!
            googleClient = .init(
                server: googleServer,
                jsonEncoder: JSONEncoding.default,
                reachability: googleAlReachability,
                httpTimeout: 10
            )

            let duckduckgoServer = DuckDuckGoServer()
            // swiftlint:disable:next force_unwrapping
            ddGoAlReachability = .init(server: duckduckgoServer)!
            duckduckgoClient = .init(
                server: duckduckgoServer,
                jsonEncoder: JSONEncoding.default,
                reachability: ddGoAlReachability,
                httpTimeout: 10
            )
        }
        
        func findDataService<T>(_ type: T.Type, _ key: String? = nil) -> T {
            // swiftlint:disable:next force_unwrapping
            dataServiceLocator.findService(type, key)!
        }
        
        func registerDataServices() async {
            let searchDataService = SearchDataServiceFactory.create(
                executionQueue: DispatchQueue.global(),
                responseQueue: DispatchQueue.main,
                stratsFactory: StrategyFactory.shared
            )
            dataServiceLocator.registerNamed(searchDataService, .searchDataServiceKey)

            let tabsSubject: TabsDataSubjectProtocol?
            if #available(iOS 17.0, *) {
                tabsSubject = await UIServiceRegistry.shared().tabsSubject
            } else {
                tabsSubject = nil
            }
            guard let database = Database(name: "CottonDbModel") else {
                fatalError("Failed to initialize CoreData database")
            }
            do {
                try await database.loadStore()
            } catch {
                fatalError("Failed to initialize Database \(error.localizedDescription)")
            }
            self.database = database
            let contextClosure = { @Sendable [weak database] () -> NSManagedObjectContext? in
                guard let dbInterface = database else {
                    fatalError("Cotton db reference is nil")
                }
                return dbInterface.newPrivateContext()
            }
            let cacheProvider = TabsRepositoryImpl(database.viewContext, contextClosure)
            let strategy = NearbySelectionStrategy()
            let tabsDataService = await TabsDataServiceFactory.create(
                cacheProvider,
                DefaultTabProvider.shared,
                strategy,
                tabsSubject,
                FeatureManager.shared.observingApiTypeValue()
            )
            dataServiceLocator.registerNamed(tabsDataService, .tabsDataServiceKey)
        }
    }
}

extension RestClient where Server == GoogleDnsServer {
    static var shared: GoogleDnsClient {
        return ServiceRegistry.shared.dnsClient
    }
}

extension RestClient where Server == GoogleServer {
    static var shared: GoogleSuggestionsClient {
        return ServiceRegistry.shared.googleClient
    }
}

extension RestClient where Server == DuckDuckGoServer {
    static var shared: DDGoSuggestionsClient {
        return ServiceRegistry.shared.duckduckgoClient
    }
}

extension TabsDataServiceFactory {
    static var shared: any TabsDataServiceProtocol {
        get async {
            await ServiceRegistry.shared.findDataService(
                (any TabsDataServiceProtocol).self,
                .tabsDataServiceKey
            )
        }
    }
}
