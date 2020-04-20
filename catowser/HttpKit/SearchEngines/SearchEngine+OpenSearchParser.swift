//
//  SearchEngine+OpenSearchParser.swift
//  HttpKit
//
//  Created by Andrei Ermoshin on 4/14/20.
//  Copyright © 2020 andreiermoshin. All rights reserved.
//

import Foundation
import SWXMLHash
import Alamofire // for HTTPMethod type

/**
 https://developer.mozilla.org/en-US/docs/Web/OpenSearch
 
 
 */

public enum OpenSearchError: LocalizedError {
    case noAnyURLXml
    case noTemplateParameter
    case templateIsNotURL
    case notValidURL
    case htmlTemplateUrlNotFound
}

enum ImageEncoding: String {
    case xIcon = "image/x-icon"
}

public extension HttpKit.SearchEngine {
    init(xml element: XMLElement, shortName: String, imageData: Data? = nil) throws {
        self.shortName = shortName
        self.imageData = imageData
        
        let httpMethod: HTTPMethod
        if let httpMethodString = element.attribute(by: "method")?.text {
            httpMethod = HTTPMethod(rawValue: httpMethodString) ?? .get
        } else {
            httpMethod = .get
        }
        self.httpMethod = httpMethod
        
        let optionalTemplateString = element.attribute(by: "template")?.text
        guard let templateString = optionalTemplateString else {
            throw OpenSearchError.noTemplateParameter
        }
        guard let url = URL(string: templateString) else {
            throw OpenSearchError.templateIsNotURL
        }
        let optionalComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        guard let components = optionalComponents else {
            throw OpenSearchError.notValidURL
        }
        self.components = components
        
        // TODO: parse Params from xml as well
        self.queryItems = components.queryItems ?? []
    }
    
    private static func parseOpenSearchURLParams() -> [URLQueryItem]? {
        // TODO: implement
        return nil
    }
}

extension Data {
    static func parseOpenSearchImage(_ imageXmlElement: XMLIndexer) -> Data? {
        let imageData: Data?
        
        if let encodedImageString = imageXmlElement.element?.text {
            let imgWidthStr = imageXmlElement.element?.attribute(by: "width")?.text ?? "16"
            let imgHeightStr = imageXmlElement.element?.attribute(by: "height")?.text ?? "16"
            _ = Int(imgWidthStr, radix: 10) ?? 16
            _ = Int(imgHeightStr, radix: 10) ?? 16
            let imgEncodingTypeStr = imageXmlElement.element?.attribute(by: "type")?.text
            if let encodingTypeStr = imgEncodingTypeStr,
                let _ = ImageEncoding(rawValue: encodingTypeStr) {
                // TODO: add handling for x-icon and for other formats
                imageData = Data(base64Encoded: encodedImageString)
            } else {
                // probably base64
                imageData = Data(base64Encoded: encodedImageString)
            }
        } else {
            imageData = nil
        }
        
        return imageData
    }
}

