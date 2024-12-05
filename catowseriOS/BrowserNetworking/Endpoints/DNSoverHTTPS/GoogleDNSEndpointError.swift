//
//  GoogleDNSEndpointError.swift
//  catowser
//
//  Created by Andrey Ermoshin on 03.12.2024.
//  Copyright © 2024 Cotton (Catowser). All rights reserved.
//

/// DNS over HTTPS google endpoint error
enum GoogleDNSEndpointError: LocalizedError {
    case emptyAnswers
    case dnsStatusError(Int32)
    case recordTypeParsing(UInt32)

    var errorDescription: String? {
        return "Google DSN over JSON `\(self)`"
    }
}
