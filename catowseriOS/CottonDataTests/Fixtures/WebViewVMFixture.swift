//
//  WebViewVMFixture.swift
//  CoreCatowserTests
//
//  Created by Andrei Ermoshin on 1/11/23.
//  Copyright © 2023 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import XCTest
import CottonRestKit
import CottonBase
import WebKit
import SwiftyMocky

/// A known state against which a test is running for web view vm
@MainActor
class WebViewVMFixture: XCTestCase {
    // MARK: - mocks and objects to be re-created

    var goodServerMock: MockedGoodDnsServer!
    var goodJsonEncodingMock: MockedGoodJSONEncoding!
    var reachabilityMock: NetworkReachabilityAdapterMock<MockedGoodDnsServer>!
    var goodDnsClient: RestInterfaceMock<MockedGoodDnsServer,
                                         NetworkReachabilityAdapterMock<MockedGoodDnsServer>,
                                         MockedGoodJSONEncoding>!
    var rxSubscriber: MockedDNSContext.HttpKitRxSubscriber!
    var subscriber: MockedDNSContext.HttpKitSubscriber!
    var goodDnsContext: MockedDNSContext!
    var exampleIpAddress: String?
    lazy var goodContextMock: MockedDNSContext = .init(goodDnsClient, rxSubscriber, subscriber)
    lazy var strategyMock: DNSResolvingStrategyMock = .init(goodContextMock)
    lazy var resolveDnsUseCaseMock = ResolveDNSUseCaseMock<DNSResolvingStrategyMock<MockedDNSContext>>()
    lazy var selectedTabUseCaseMock = SelectedTabUseCaseMock()
    lazy var writeTabsUseCase = WriteTabsUseCaseMock()
    var jsSubject: MockedWebViewWithError!
    var webViewContext: MockedWebViewContext!
    var settings: Site.Settings!

    // MARK: - constants

    // swiftlint:disable:next force_try
    let exampleDomainName: DomainName = try! .init(input: "www.example.com")
    // swiftlint:disable:next force_try
    let opennetDomainName: DomainName = try! .init(input: "opennet.ru")
    lazy var exampleURLInfo: URLInfo = .init(scheme: .https,
                                             path: "foo/bar",
                                             query: nil,
                                             domainName: exampleDomainName,
                                             ipAddress: nil)
    lazy var opennetURLInfo: URLInfo = .init(scheme: .https,
                                             path: "foo/bar",
                                             query: nil,
                                             domainName: opennetDomainName,
                                             ipAddress: nil)
    lazy var exampleSite: Site = .init(urlInfo: exampleURLInfo,
                                       settings: settings,
                                       faviconData: nil,
                                       searchSuggestion: nil,
                                       userSpecifiedTitle: nil)
    lazy var opennetSite: Site = .init(urlInfo: opennetURLInfo,
                                       settings: settings,
                                       faviconData: nil,
                                       searchSuggestion: nil,
                                       userSpecifiedTitle: nil)

    let urlV1 = URL(string: "https://www.example.com/foo/bar")
    let urlV2 = URL(string: "https://www.example.com/foo/bar_2")
    let urlV3 = URL(string: "https://www.known.com/bar")
    // swiftlint:disable:next force_unwrapping
    let urlV4 = URL(string: "mailto://john@example.com")!
    // swiftlint:disable:next force_unwrapping
    let urlV5 = URL(string: "https://instagram.com/")!
    let wrongUrlV1 = URL(string: "http://www.example.com/foo/bar")
    let wrongUrlV2 = URL(string: "https://www.example.com/foo")
    let wrongUrlV3 = URL(string: "https://www.google.com/foo/bar")
    let opennetUrlV1 = URL(string: "https://opennet.ru/foo/bar")

    override func setUpWithError() throws {
        try super.setUpWithError()

        goodServerMock = .init()
        goodJsonEncodingMock = .init()
        // swiftlint:disable:next force_unwrapping
        reachabilityMock = .init(server: goodServerMock)!
        goodDnsClient = .init(server: goodServerMock,
                              jsonEncoder: goodJsonEncodingMock,
                              reachability: reachabilityMock,
                              httpTimeout: 0)

        rxSubscriber = .init()
        subscriber = .init()
        goodDnsContext = .init(goodDnsClient, rxSubscriber, subscriber)
        jsSubject = .init()
        webViewContext = .init(doh: false,
                               js: false,
                               nativeAppRedirect: true,
                               asyncApiType: .combine,
                               appName: "instagram.com")

        settings = .init(isPrivate: false,
                         blockPopups: true,
                         isJSEnabled: false,
                         canLoadPlugins: false)
    }
}
