//
//  String+CatowserExtensions.swift
//  catowser
//
//  Created by Andrei Ermoshin on 28/01/2019.
//  Copyright © 2019 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import Foundation

public extension String {
    static func mainBundleName() -> String {
        return Bundle.main.bundleIdentifier ?? "com.ae.catowser"
    }

    static func queueNameWith(suffix: String) -> String {
        return .mainBundleName() + ".\(suffix)"
    }

    func looksLikeURL() -> Bool {
        // The assumption here is that if the user is typing in a forward slash and there are no spaces
        // involved, it's going to be a URL. If we type a space, any url would be invalid.
        // See https://bugzilla.mozilla.org/show_bug.cgi?id=1192155 for additional details.
        return self.contains("/") && !self.contains(" ")
    }

    /// Constructs new `String` without leading spaces
    func trimmingLeadingSpaces() -> String {
        return String(drop { $0 == " " })
    }

    func withoutPrefix(_ prefix: String) -> String? {
        guard self.hasPrefix(prefix) else { return nil }
        return String(self.dropFirst(prefix.count))
    }

    static let placeholderText: String = NSLocalizedString(
        "placeholder_searchbar",
        comment: "when search bar is empty"
    )
}
