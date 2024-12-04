//
//  GoogleSearchEngine.swift
//  BrowserNetworking
//
//  Created by Andrei Ermoshin on 4/13/20.
//  Copyright © 2020 Cotton (former Catowser). All rights reserved.
//

import Foundation

extension SearchEngine {
    public static func googleSearchEngine() -> SearchEngine {
        let items: [URLQueryItem] = [
            URLQueryItem(name: "ie", value: "utf-8"),
            URLQueryItem(name: "oe", value: "utf-8"),
            URLQueryItem(name: "client", value: "firefox")
        ]

        return SearchEngine(shortName: "Google",
                            domainName: "www.google.com",
                            path: "search",
                            queryItems: items,
                            imageData: .none)
    }
}
