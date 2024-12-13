//
//  WebViewVmDNSoverHTTPSConcurrencyTests.swift
//  CoreCatowserTests
//
//  Created by Andrei Ermoshin on 1/12/23.
//  Copyright © 2023 Cotton (former Catowser). All rights reserved.
//

import XCTest
import CottonRestKit
import CottonBase
import WebKit
import Combine
import SwiftyMocky

@MainActor
final class WebViewVmDNSoverHTTPSConcurrencyTests: WebViewVMFixture {
    override func setUpWithError() throws {
        exampleIpAddress = "100.0.12.7"
        try super.setUpWithError()
        webViewContext = .init(doh: true, js: false, nativeAppRedirect: false, asyncApiType: .asyncAwait)
    }
    func testLoad() async throws {
        let vm: WebViewModelImpl = WebViewModelImpl(
            resolveDnsUseCaseMock,
            webViewContext,
            selectedTabUseCaseMock,
            writeTabsUseCase,
            nil,
            exampleSite)

        // swiftlint:disable:next force_unwrapping force_try
        let resolvedUrlV1 = try! urlV1!.updatedHost(with: exampleIpAddress!)
        // swiftlint:disable:next force_unwrapping
        Given(resolveDnsUseCaseMock, .aaResolveDomainName(.value(urlV1!), willReturn: resolvedUrlV1))
        await vm.load()

        // swiftlint:disable:next force_unwrapping
        let urlInfoV1 = URLInfo(urlV1!)!
        // swiftlint:disable:next force_unwrapping
        let urlInfoV11: URLInfo = urlInfoV1.withIPAddress(ipAddress: exampleIpAddress!)
        let expectedStateV1: WebViewModelState = .creatingRequest(urlInfoV11, settings)
        XCTAssertEqual(vm.state, expectedStateV1)

        let navActionV1 = MockedNavAction(resolvedUrlV1, .other)
        await vm.decidePolicy(navActionV1) { policy in
            XCTAssertEqual(policy, .allow)
        }
    }
}
