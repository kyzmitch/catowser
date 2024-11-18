//
//  ServiceRegistry.swift
//  catowser
//
//  Created by Andrei Ermoshin on 5/1/20.
//  Copyright © 2020 Cotton (former Catowser). All rights reserved.
//

import Foundation
import CottonRestKit
import CoreBrowser
import BrowserNetworking
import Alamofire // only needed for `JSONEncoding`
import FeaturesFlagsKit

@globalActor
final class ServiceRegistry {
    static let shared = StateHolder()

    actor StateHolder {
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

        init() {
            let googleDNSserver = GoogleDnsServer()
            // swiftlint:disable:next force_unwrapping
            dnsAlReachability = .init(server: googleDNSserver)!
            dnsClient = .init(server: googleDNSserver,
                              jsonEncoder: JSONEncoding.default,
                              reachability: dnsAlReachability,
                              httpTimeout: 2)
            let googleServer = GoogleServer()
            // swiftlint:disable:next force_unwrapping
            googleAlReachability = .init(server: googleServer)!
            googleClient = .init(server: googleServer,
                                 jsonEncoder: JSONEncoding.default,
                                 reachability: googleAlReachability,
                                 httpTimeout: 10)

            let duckduckgoServer = DuckDuckGoServer()
            // swiftlint:disable:next force_unwrapping
            ddGoAlReachability = .init(server: duckduckgoServer)!
            duckduckgoClient = .init(server: duckduckgoServer,
                                     jsonEncoder: JSONEncoding.default,
                                     reachability: ddGoAlReachability,
                                     httpTimeout: 10)
        }

        func searchSuggestClient() async -> SearchEngine {
            let selectedPluginName = await FeatureManager.shared.searchPluginName()
            let optionalXmlData = ResourceReader.readXmlSearchPlugin(with: selectedPluginName, on: .main)
            guard let xmlData = optionalXmlData else {
                return .googleSearchEngine()
            }

            let osDescription: OpenSearch.Description
            do {
                osDescription = try OpenSearch.Description(data: xmlData)
            } catch {
                print("Open search xml parser error: \(error.localizedDescription)")
                return .googleSearchEngine()
            }

            return osDescription.html
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
