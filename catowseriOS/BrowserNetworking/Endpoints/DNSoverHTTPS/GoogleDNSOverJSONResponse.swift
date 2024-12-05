//
//  GoogleDNSOverJSONResponse.swift
//  catowser
//
//  Created by Andrey Ermoshin on 03.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

import CottonRestKit
import CottonBase

/// DNS over HTTPS response for Google API
public struct GoogleDNSOverJSONResponse: ResponseType {
    /**
     200 OK
     HTTP parsing and communication with DNS resolver was successful,
     and the response body content is a DNS response in either binary or JSON encoding,
     depending on the query endpoint, Accept header and GET parameters.
     */
    public static var successCodes: [Int] {
        [200]
    }

    fileprivate let answer: [Answer]
    /**
     Note: An HTTP success may still be a DNS failure.
     Check the DNS response code (JSON "Status" field) for the
     DNS errors SERVFAIL, FORMERR, REFUSED, and NOTIMP.
     */
    let status: Int32
    /// NOERROR - Standard DNS response code (32 bit integer).
    let noError: Int32 = 0

    public let ipAddress: String

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        answer = try container.decode([Answer].self, forKey: .answer)
        status = try container.decode(Int32.self, forKey: .status)
        guard status == noError else {
            throw GoogleDNSEndpointError.dnsStatusError(status)
        }
        let ipv4array = answer.filter { $0.recordType.knownCase == .addressRecord }
        guard let firstAddress = ipv4array.first?.ipAddress else {
            throw GoogleDNSEndpointError.emptyAnswers
        }
        ipAddress = firstAddress
    }

    fileprivate enum CodingKeys: String, CodingKey {
        case answer = "Answer"
        case status = "Status"
    }
}

private struct Answer: Decodable {
    /// "apple.com.", Always matches name in the Question section
    let name: String
    /// https://en.wikipedia.org/wiki/List_of_DNS_record_types
    /// Not sure how many bytes for it
    /// 1 - A - Standard DNS RR type
    /// 99 - SPF - Standard DNS RR type
    let recordType: DnsRR
    /// Data for A - IP address as text or some different thing like `z-p42-instagram.c10r.facebook.com.`
    let ipAddress: String

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        ipAddress = try container.decode(String.self, forKey: .ipAddress)
        let rr = try container.decode(UInt32.self, forKey: .type)
        guard let dnsRR = DnsRR(rr) else {
            throw GoogleDNSEndpointError.recordTypeParsing(rr)
        }
        recordType = dnsRR
    }

    fileprivate enum CodingKeys: String, CodingKey {
        case name
        case ipAddress = "data"
        case type
    }
}

private enum DNSRecordType: UInt32 {
    case addressRecord = 1
    case canonicalName = 5
}

extension DnsRR {
    fileprivate var knownCase: DNSRecordType? {
        return DNSRecordType(rawValue: self.numericValue)
    }
}
