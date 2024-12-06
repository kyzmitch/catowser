//
//  GoogleJSONDNSoHTTPsEndpoint.swift
//  BrowserNetworking
//
//  Created by Andrei Ermoshin on 10/26/19.
//  Copyright © 2019 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import CottonRestKit
import CottonBase
import CottonReactiveRestKit
@preconcurrency import ReactiveSwift
#if canImport(Combine)
import Combine
#endif
import Alamofire

/// https://tools.ietf.org/id/draft-ietf-doh-dns-over-https-02.txt

public typealias GoogleDnsClient = RestClient<GoogleDnsServer,
                                              AlamofireReachabilityAdaptee<GoogleDnsServer>,
                                              JSONEncoding>

typealias GDNSjsonEndpoint = Endpoint<GoogleDnsServer>
public typealias GDNSjsonRxSignal = Signal<GoogleDNSOverJSONResponse, HttpError>.Observer
public typealias GDNSjsonRxInterface = RxObserverWrapper<GoogleDNSOverJSONResponse,
                                                         GoogleDnsServer,
                                                         GDNSjsonRxSignal>
public typealias GDNSJsonClientRxSubscriber = RxSubscriber<GoogleDNSOverJSONResponse,
                                                           GoogleDnsServer,
                                                           GDNSjsonRxInterface>
public typealias GDNSJsonClientSubscriber = Sub<GoogleDNSOverJSONResponse,
                                                GoogleDnsServer>
public typealias GDNSjsonProducer = SignalProducer<GoogleDNSOverJSONResponse, HttpError>
@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public typealias GDNSjsonPublisher = AnyPublisher<GoogleDNSOverJSONResponse, HttpError>

extension Endpoint where S == GoogleDnsServer {

    static func googleDnsOverHTTPSJson(_ params: GDNSRequestParams) throws -> GDNSjsonEndpoint {
        /**
         To minimize this risk, send only the HTTP headers required for DoH:
         Host, Content-Type (for POST), and if necessary, Accept.
         User-Agent should be included in any development or testing versions.
         */
        let frozenEndpoint = GDNSjsonEndpoint(
            httpMethod: .get,
            path: "resolve",
            headers: nil,
            encodingMethod: .QueryString(items: params.urlQueryItems.kotlinArray))
        return frozenEndpoint
    }

    static func googleDnsOverHTTPSJson(_ domainName: String) throws -> GDNSjsonEndpoint {
        let domainObject = try DomainName(input: domainName)
        guard let params = GDNSRequestParams(domainName: domainObject) else {
            throw HttpError.missingRequestParameters("google dns params")
        }

        return try .googleDnsOverHTTPSJson(params)
    }
}

extension RestClient where Server == GoogleDnsServer {
    func rxGetIPaddress(ofDomain domainName: String, _ subscriber: GDNSJsonClientRxSubscriber) -> GDNSjsonProducer {
        let endpoint: GDNSjsonEndpoint
        do {
            endpoint = try .googleDnsOverHTTPSJson(domainName)
        } catch let error as HttpError {
            return GDNSjsonProducer(error: error)
        } catch let coreError as DomainName.Error {
            return GDNSjsonProducer(error: HttpError.invalidDomainName(error: coreError))
        } catch {
            return GDNSjsonProducer(error: HttpError.failedConstructRequestParameters)
        }

        let adapter: AlamofireHTTPRxAdaptee<GoogleDNSOverJSONResponse,
                                            GoogleDnsServer,
                                            GDNSjsonRxInterface> = .init(.waitsForRxObserver)
        let producer = self.rxMakePublicRequest(for: endpoint, transport: adapter, subscriber: subscriber)
        return producer
    }

    public func rxResolvedDomainName(in url: URL, _ subscriber: GDNSJsonClientRxSubscriber) -> ResolvedURLProducer {
        return url.rxHttpHost
            .flatMapError({ _ -> SignalProducer<String, HttpError> in
                return .init(error: .failedConstructRequestParameters)
            })
            .flatMap(.latest, { (host) -> GDNSjsonProducer in
                return self.rxGetIPaddress(ofDomain: host, subscriber)
            })
            .flatMapError({ (kitErr) -> SignalProducer<GoogleDNSOverJSONResponse, DnsError> in
                return .init(error: .httpError(kitErr))
            })
            .flatMap(.latest, { (response) -> ResolvedURLProducer in
                return url.rxUpdatedHost(with: response.ipAddress)
            })
    }

    @available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func cGetIPaddress(ofDomain domainName: String, _ subscriber: GDNSJsonClientSubscriber) -> GDNSjsonPublisher {
        let endpoint: GDNSjsonEndpoint
        do {
            endpoint = try .googleDnsOverHTTPSJson(domainName)
        } catch let error as HttpError {
            return GDNSjsonPublisher(Future.failure(error))
        } catch let coreError as DomainName.Error {
            let adaptedError: HttpError = .invalidDomainName(error: coreError)
            return GDNSjsonPublisher(Future.failure(adaptedError))
        } catch {
            return GDNSjsonPublisher(Future.failure(HttpError.failedConstructRequestParameters))
        }

        let adapter: AlamofireHTTPAdaptee<GoogleDNSOverJSONResponse,
                                          GoogleDnsServer> = .init(.waitsForCombinePromise)
        let future = self.cMakePublicRequest(for: endpoint, transport: adapter, subscriber: subscriber)
        return future.eraseToAnyPublisher()
    }

    @available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func resolvedDomainName(in url: URL, _ subscriber: GDNSJsonClientSubscriber) -> AnyPublisher<URL, DnsError> {
        return url.cHttpHost
            .mapError { _ -> HttpError in
                return .failedConstructRequestParameters
            }
            .flatMap { self.cGetIPaddress(ofDomain: $0, subscriber) }
            .map { $0.ipAddress}
            .mapError { (kitErr) -> DnsError in
                return .httpError(kitErr)
            }
            .flatMap { url.cUpdatedHost(with: $0) }
            .eraseToAnyPublisher()
    }
}
