//
//  SearchEngine.swift
//  BrowserNetworking
//
//  Created by Andrei Ermoshin on 15/02/2019.
//  Copyright © 2019 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import CottonBase

/// Alamofire's http method type can't be retroactivly silenced because sendable is a system protocol.
extension CottonBase.HTTPMethod: @unchecked @retroactive Sendable { }

/// The model for OpenSearch format URL
public struct SearchEngine: Sendable {
    /// Name e.g. "DuckDuckGo"
    let shortName: String
    /// Valid components for final URL
    let components: URLComponents
    /// Original query items
    let queryItems: [URLQueryItem]
    /// Data or URL for site image/icon
    let imageData: OpenSearch.ImageParseResult
    /// So far not used parameter,  but it is present in OpenSearch format
    let httpMethod: HTTPMethod

    init(
        shortName: String,
        domainName: String,
        path: String,
        queryItems: [URLQueryItem],
        imageData: OpenSearch.ImageParseResult = .none,
        httpMethod: HTTPMethod = .get
    ) {
        self.shortName = shortName

        var components = URLComponents()
        components.scheme = "https"
        components.host = domainName
        components.path = path
        self.components = components
        self.queryItems = queryItems
        self.imageData = imageData
        self.httpMethod = httpMethod
    }

    /// Returns the search URL for the given query.
    ///
    /// - Parameter query: Text entered by user in search view.
    /// - Returns: URL
    public func searchURLForQuery(_ query: String) -> URL? {
        var mutableComponents = components
        let item = URLQueryItem(name: "q", value: query)
        var items = queryItems
        items.append(item)
        mutableComponents.queryItems = items

        return mutableComponents.url
    }
}
