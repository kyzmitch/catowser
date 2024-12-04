//
//  OpenSearchParser.swift
//  BrowserNetworking
//
//  Created by Andrei Ermoshin on 4/20/20.
//  Copyright © 2020 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import CottonBase
import SWXMLHash

extension OpenSearch {
    public struct Description {
        public let html: SearchEngine
        public let json: SearchEngine?

        init(html: SearchEngine, json: SearchEngine?) {
            self.html = html
            self.json = json
        }

        // swiftlint:disable:next function_body_length
        public init(data: Data) throws {
            let xml = XMLHash.config { (options) in
                options.detectParsingErrors = true
            }.parse(data)

            let rootXml = try xml.byKey("OpenSearchDescription")
            let shortName = try rootXml.byKey("ShortName").element?.text ?? "Unnamed"

            let imageXmlElement = try rootXml.byKey("Image")
            let imageResult = OpenSearch.ImageParseResult(image: imageXmlElement)

            let urlObjects = rootXml["Url"].all
            guard !urlObjects.isEmpty else {
                throw OpenSearch.Error.noAnyURLXml
            }

            var htmlSearchEngine: SearchEngine?
            var jsonSearchEngine: SearchEngine?

            for urlXml in urlObjects {
                guard let urlElement = urlXml.element else {
                    continue
                }
                guard let typeString = urlElement.attribute(by: "type")?.text else {
                    continue
                }
                let possibleContentType: CottonBase.ContentTypeValue? = .companion.createFrom(rawValue: typeString)
                guard let contentType = possibleContentType else {
                    continue
                }
                switch contentType {
                case .html:
                    htmlSearchEngine = try .init(xml: urlElement,
                                                 indexer: urlXml,
                                                 shortName: shortName,
                                                 imageData: imageResult)
                case .jsonsuggestions:
                    jsonSearchEngine = try .init(xml: urlElement,
                                                 indexer: urlXml,
                                                 shortName: shortName,
                                                 imageData: imageResult)
                default:
                    print("Unhandled url type for OpenSearch format: \(contentType.stringValue)")
                }
            }

            guard let html = htmlSearchEngine else {
                throw OpenSearch.Error.htmlTemplateUrlNotFound
            }
            if let json = jsonSearchEngine {
                // some weird swift bug? only after unwrapping
                // the json object is visible and not nil in debugger
                self.html = html
                self.json = json
            } else {
                self.html = html
                self.json = jsonSearchEngine
            }
        }
    }
}
