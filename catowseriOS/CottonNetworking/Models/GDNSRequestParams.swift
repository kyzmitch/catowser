//
//  GDNSRequestParams.swift
//  BrowserNetworking
//
//  Created by Andrei Ermoshin on 4/29/20.
//  Copyright © 2020 Cotton (former Catowser). All rights reserved.
//

import Foundation
import CottonBase

public struct GDNSRequestParams {
    /**
     string, required

     The only required parameter. RFC 4343 backslash escapes are accepted.
     */
    let name: DomainName
    /**
     string, default: 1
     */
    let type: DnsRR

    /**
     boolean, default: false

     The CD (Checking Disabled) flag. Use cd=1, or cd=true to disable DNSSEC validation;
     use cd=0, cd=false, or no cd parameter to enable DNSSEC validation.
     */
    let cd: Bool

    /**
     string, default: empty

     Desired content type option. Use ct=application/dns-message to receive a binary DNS message
     in the response HTTP body instead of JSON text. Use ct=application/x-javascript to explicitly
     request JSON text. Other content type values are ignored and default JSON content is returned.
     */
    let ct: String

    /**
     boolean, default: false

     The DO (DNSSEC OK) flag. Use do=1, or do=true to include DNSSEC records
     (RRSIG, NSEC, NSEC3); use do=0, do=false, or no do parameter to omit DNSSEC records.

     Applications should always handle (and ignore, if necessary) any DNSSEC records in JSON responses
     as other implementations may always include them, and we may change the default behavior for JSON
     responses in the future. (Binary DNS message responses always respect the value of the DO flag.)
     */
    let `do`: Bool

    /**
     string, default: empty

     The edns0-client-subnet option. Format is an IP address with a subnet mask.
     Examples: 1.2.3.4/24, 2001:700:300::/48.

     If you are using DNS-over-HTTPS because of privacy concerns, and do not want any part of your IP
     address to be sent to authoritative name servers for geographic location accuracy, use
     edns_client_subnet=0.0.0.0/0. Google Public DNS normally sends approximate network
     information (usually zeroing out the last part of your IPv4 address).
     */
    let ednsClientSubnet: String // IPv4Address

    /**
     string, ignored

     The value of this parameter is ignored. Example: XmkMw~o_mgP2pf.gpw-Oi5dK.

     API clients concerned about possible side-channel privacy attacks using the packet sizes of
     HTTPS GET requests can use this to make all requests exactly the same size by padding requests
     with random data. To prevent misinterpretation of the URL, restrict the padding characters to the
     unreserved URL characters: upper- and lower-case letters, digits, hyphen, period, underscore and tilde.
     */
    let randomPadding: String

    public init?(domainName: DomainName) {
        name = domainName
        guard let rrType = DnsRR() else {
            return nil
        }
        type = rrType
        cd = false
        ct = ""
        self.do = false
        ednsClientSubnet = "0.0.0.0/0"
        randomPadding = ""
    }

    var urlQueryItems: [URLQueryItem] {

        let items: [URLQueryItem] = [
            URLQueryItem(name: "name", value: name.rawString),
            URLQueryItem(name: "type", value: type.rawValue),
            URLQueryItem(name: "cd", value: "\(cd)"),
            URLQueryItem(name: "ct", value: ct),
            URLQueryItem(name: "do", value: "\(self.do)"),
            URLQueryItem(name: "edns_client_subnet", value: ednsClientSubnet),
            URLQueryItem(name: "random_padding", value: randomPadding)
        ]
        return items
    }
}
