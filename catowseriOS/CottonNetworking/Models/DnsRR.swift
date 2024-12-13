//
//  DnsRR.swift
//  BrowserNetworking
//
//  Created by Andrei Ermoshin on 4/29/20.
//  Copyright © 2020 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import Foundation

// https://developers.google.com/speed/public-dns/docs/doh/json
// https://github.com/chromium/chromium/commit/786929ad1cfbc97962ff5672e2469460ff535f41

/**

 RR type can be represented as a number in [1, 65535] or a canonical string (case-insensitive, such as A or aaaa).
 You can use 255 for 'ANY' queries but be aware that this is not a replacement for sending queries for both A
 and AAAA or MX records. Authoritative name servers need not return all records for such queries;
 some do not respond, and others (such as cloudflare.com) return only HINFO.

 This is wrapper around `String` type.
 https://twitter.com/nicklockwood/status/1192365612661706752?s=20
 */
public struct DnsRR: RawRepresentable {
    public init?(rawValue: String) {
        return nil
    }

    public let rawValue: String

    let numericValue: UInt32

    public typealias RawValue = String

    public init?(_ number: UInt32 = 1) {
        guard (1...65535).contains(number) else {
            return nil
        }
        numericValue = number
        rawValue = "\(number)"
    }
}
