//
//  GoogleDnsServer.swift
//  BrowserNetworking
//
//  Created by Andrei Ermoshin on 11/9/19.
//  Copyright © 2019 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import CottonBase

public class GoogleDnsServer: ServerDescription, @unchecked Sendable {
    public convenience init() {
        // swiftlint:disable:next force_try
        let host = try! Host(input: "dns.google")
        self.init(host: host, scheme: .https)
    }
}
