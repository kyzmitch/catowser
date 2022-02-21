//
//  HttpEnvironment.swift
//  catowser
//
//  Created by Andrei Ermoshin on 5/1/20.
//  Copyright © 2020 andreiermoshin. All rights reserved.
//

import Foundation
import HttpKit
import BrowserNetworking
import Alamofire // only needed for `JSONEncoding`

final class HttpEnvironment {
    static let shared: HttpEnvironment = .init()
    
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
    
    private init() {
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
}

extension HttpKit.Client where Server == GoogleDnsServer {
    static var shared: GoogleDnsClient {
        return HttpEnvironment.shared.dnsClient
    }
}

extension HttpKit.Client where Server == GoogleServer {
    static var shared: GoogleSuggestionsClient {
        return HttpEnvironment.shared.googleClient
    }
}

extension HttpKit.Client where Server == DuckDuckGoServer {
    static var shared: DDGoSuggestionsClient {
        return HttpEnvironment.shared.duckduckgoClient
    }
}
