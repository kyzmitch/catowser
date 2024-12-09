//
//  XmlSearchPluginResource.swift
//  CoreBrowser
//
//  Created by Andrei Ermoshin on 4/15/20.
//  Copyright © 2020 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import Foundation

/// Resource reader parser, doesn't hold any state, so no need to be global actor
public enum XmlSearchPluginResource {
    public static func read(
        with name: WebAutoCompletionSource,
        on bundle: Bundle
    ) -> Data? {
        guard let fileURL = bundle.url(forResource: name.stringKey, withExtension: "xml") else {
            return nil
        }
        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }
        return data
    }
}

extension String {
    static let searchPluginsFolder = "SearchPlugins"
}
