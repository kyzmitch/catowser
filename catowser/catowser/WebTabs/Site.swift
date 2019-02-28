//
//  Site.swift
//  catowser
//
//  Created by Andrei Ermoshin on 01/02/2019.
//  Copyright © 2019 andreiermoshin. All rights reserved.
//

import Foundation

public struct Site {
    /// Initial url
    public let url: URL

    public var host: String {
        // For http://www.opennet.ru/opennews/art.shtml?num=50072
        // it should be "www.opennet.ru"
        // Add parsing of host https://tools.ietf.org/html/rfc1738#section-3.1
        // in case if iOS sdk returns nil
        return url.host ?? "site"
    }

    /// String associated with site if site was created from search engine.
    /// This convinient property to transfer/save search query to use it for search view.
    /// Different approach could be to store it in tab content type `.site` state as 2nd associated value.
    public let searchSuggestion: String?

    public init(url: URL, searchSuggestion: String? = nil) {
        self.url = url
        self.searchSuggestion = searchSuggestion
    }

    public init?(urlString: String) {
        guard let decodedUrl = URL(string: urlString) else {
            return nil
        }
        url = decodedUrl
        searchSuggestion = nil
    }
}

extension Site: Equatable {}
