//
//  SearchEngine+OpenSearchParser.swift
//  BrowserNetworking
//
//  Created by Andrei Ermoshin on 4/14/20.
//  Copyright © 2020 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import Foundation
import SWXMLHash
import CottonBase

/**
 https://developer.mozilla.org/en-US/docs/Web/OpenSearch
 */

public enum OpenSearch {}

extension OpenSearch {
    public enum Error: LocalizedError {
        case noAnyURLXml
        case noTemplateParameter
        case templateIsNotURL
        case notValidURL
        case notImplementedHttpMethod
        case htmlTemplateUrlNotFound
    }
}

extension String {
    static let queryTemplate = "{searchTerms}"
}

extension SearchEngine {
    init(xml element: SWXMLHash.XMLElement,
         indexer: XMLIndexer,
         shortName: String,
         imageData: OpenSearch.ImageParseResult) throws {

        self.shortName = shortName
        self.imageData = imageData

        let httpMethod: HTTPMethod
        if let methodString = element.attribute(by: "method")?.text {
            guard let enumValue = HTTPMethod.companion.createFrom(rawString: methodString) else {
                throw OpenSearch.Error.notImplementedHttpMethod
            }
            httpMethod = enumValue
        } else {
            httpMethod = .get
        }
        self.httpMethod = httpMethod

        let optionalTemplateString = element.attribute(by: "template")?.text
        guard var templateString = optionalTemplateString else {
            throw OpenSearch.Error.noTemplateParameter
        }
        if templateString.contains(String.queryTemplate) {
            templateString = templateString.replacingOccurrences(of: String.queryTemplate, with: "")
        }
        guard let url = URL(string: templateString) else {
            throw OpenSearch.Error.templateIsNotURL
        }

        let optionalComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        guard let components = optionalComponents else {
            throw OpenSearch.Error.notValidURL
        }
        self.components = components
        let optionalItems = SearchEngine.parseURLParams(indexer: indexer)
        if let items = optionalItems {
            self.queryItems = items
        } else {
            // filter items to not include 'q' item with template value
            self.queryItems = components.queryItems?.filter {!($0.value?.isEmpty ?? true)} ?? []
        }
    }

    private static func parseURLParams(indexer: XMLIndexer) -> [URLQueryItem]? {
        let paramsObjects = indexer["Param"].all
        guard !paramsObjects.isEmpty else {
            return nil
        }

        var items = [URLQueryItem]()
        for paramXml in paramsObjects {
            guard let element = paramXml.element else {
                continue
            }
            guard let paramName = element.attribute(by: "name")?.text else {
                continue
            }
            guard let paramValue = element.attribute(by: "value")?.text else {
                continue
            }
            guard paramValue != String.queryTemplate else {
                // to not include template value
                continue
            }
            items.append(.init(name: paramName, value: paramValue))
        }
        return items.isEmpty ? nil : items
    }
}

extension OpenSearch {
    enum ImageEncoding: String {
        case xIcon = "image/x-icon"
    }

    public enum ImageParseResult: Sendable {
        case base64(Data)
        case url(URL)
        case none

        init(image xmlIndexer: XMLIndexer) {
            guard let encodedImageString = xmlIndexer.element?.text else {
                self = .none
                return
            }
            let imgWidthStr = xmlIndexer.element?.attribute(by: "width")?.text ?? "16"
            let imgHeightStr = xmlIndexer.element?.attribute(by: "height")?.text ?? "16"
            _ = Int(imgWidthStr, radix: 10) ?? 16
            _ = Int(imgHeightStr, radix: 10) ?? 16
            let imgEncodingTypeStr = xmlIndexer.element?.attribute(by: "type")?.text
            guard let encodingTypeStr = imgEncodingTypeStr else {
                guard let imgData = ImageParseResult.parseImageXmlTag(content: encodedImageString) else {
                    self = .none
                    return
                }
                self = .base64(imgData)
                return
            }
            guard let knownType = OpenSearch.ImageEncoding(rawValue: encodingTypeStr) else {
                self = .none
                return
            }

            var imgURL: URL?
            switch knownType {
            case .xIcon:
                imgURL = URL(string: encodedImageString)
            }

            guard let iconURL = imgURL else {
                self = .none
                return
            }
            self = .url(iconURL)
        }

        private static func parseImageXmlTag(content: String) -> Data? {
            // https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/Data_URIs
            // data:[<mediatype>][;base64],<data>
            // data:image/png;base64, -----
            // no need to use specific initializer like Data(base64Encoded:)
            guard let dataURL = URL(string: content) else {
                return nil
            }
            guard let imageData = try? Data(contentsOf: dataURL) else {
                return nil
            }
            return imageData
        }
    }
}
