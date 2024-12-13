//
//  ResponseType.swift
//  HttpKit
//
//  Created by Andrei Ermoshin on 4/18/22.
//  Copyright © 2022 Cotton (former Catowser). All rights reserved.
//

import Foundation

/// A type of response in REST request
public protocol ResponseType: Decodable {
    /// An array of HTTP codes which describe successfull REST request
    static var successCodes: [Int] { get }
}

extension ResponseType {
    static var successCodes: [Int] {
        return [200, 201]
    }
}
