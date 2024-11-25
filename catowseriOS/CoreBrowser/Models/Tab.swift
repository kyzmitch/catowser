//
//  CoreBrowser.Tab.swift
//  catowser
//
//  Created by admin on 12/06/2017.
//  Copyright © 2017 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import CottonBase

/// Site is an obj-c model type.
///Ccan mark with retroactive because Site type is from own CottonBase library
extension Site: @unchecked @retroactive Sendable {}

public extension Tab {
    enum ContentType: Sendable, RawRepresentable {
        public init?(rawValue: Int) {
            switch rawValue {
            case 0:
                self = .blank
            case 1:
                return nil
            case 2:
                self = .homepage
            case 3:
                self = .favorites
            case 4:
                self = .topSites
            default:
                return nil
            }
        }
        
        case blank
        case site(Site)
        case homepage
        case favorites
        case topSites

        /// Needed for database representation
        public var rawValue: Int {
            switch self {
            case .blank:
                return 0
            case .site:
                return 1
            case .homepage:
                return 2
            case .favorites:
                return 3
            case .topSites:
                return 4
            }
        }

        /// Returns .blank for wrong parameters
        public static func create(rawValue: Int16, site: Site? = nil) -> ContentType? {
            switch rawValue {
            case 0:
                return .blank
            case 1:
                guard let actualSite = site else {
                    print("No site instance for CoreBrowser.Tab.ContentType site \(rawValue)")
                    return nil
                }
                return .site(actualSite)
            case 2:
                return .homepage
            case 3:
                return .favorites
            case 4:
                return .topSites
            default:
                print("Unexpected CoreBrowser.Tab.ContentType \(rawValue)")
                return nil
            }
        }

        public var title: String {
            switch self {
            case .blank:
                return .defaultTitle
            case .site(let someSite):
                return someSite.title
            case .topSites:
                return .topSitesTitle
            default:
                return "Not implemented"
            }
        }

        var searchBarContent: String {
            switch self {
            case .site(let someSite):
                return someSite.searchBarContent
            default:
                return ""
            }
        }

        public var site: Site? {
            guard case let .site(site) = self else {
                return nil
            }

            return site
        }

        /// Shows if content type static or has dynamic dependecy like `Site`
        public var isStatic: Bool {
            if case .site = self {
                return false
            } else {
                return true
            }
        }
    }
}

extension Tab.ContentType: CaseIterable {
    public static var allCases: [CoreBrowser.Tab.ContentType] {
        [.blank, .homepage, .topSites, .favorites]
    }
}

extension Tab.ContentType: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .blank:
            return ".blank"
        case .site(let site):
            let string = """
.site(url[\(site.urlInfo.platformURL.absoluteString)],ip[\(site.urlInfo.ipAddressString ?? "none")])
"""
            return string
        case .homepage:
            return ".homepage"
        case .favorites:
            return ".favorites"
        case .topSites:
            return ".topSites"
        }
    }
}

extension Tab.ContentType: Equatable {
    public static func == (lhs: CoreBrowser.Tab.ContentType, rhs: CoreBrowser.Tab.ContentType) -> Bool {
        switch (lhs, rhs) {
        case (.site(let lSite), .site(let rSite)):
            return lSite.compareWith(rSite)
        case (.blank, .blank):
            return true
        case (.homepage, .homepage):
            return true
        case (.favorites, .favorites):
            return true
        case (.topSites, .topSites):
            return true
        default:
            return false
        }
    }
}

private extension Site {
    func compareWith(_ rSite: Site) -> Bool {
        // For some reason Kotlin comparison doesn't work right for the identical objects
        // `return lSite == rSite`
        let lSite = self
        // For some reason Kotlin comparison doesn't work right for the identical objects
        // `return lSite == rSite`
        if lSite.urlInfo.platformURL != rSite.urlInfo.platformURL {
            return false
        }
        if lSite.searchSuggestion != rSite.searchSuggestion {
            return false
        }
        if lSite.userSpecifiedTitle != rSite.userSpecifiedTitle {
            return false
        }
        if lSite.settings != rSite.settings {
            return false
        }
        return true
    }
}

public extension Tab {
    /// Replacement for `Bool` type to provide more clarity during usage on `view` layer.
    enum VisualState: Int16 {
        case selected, deselected
    }
}

/// View model for tab view which is a website representation for specific case
public struct Tab: Sendable, Identifiable {
    // The id to be able to compare e.g. blank tabs and avoid switch to ref. type
    public let id: UUID
    // Actual website info stored only for one case
    public var contentType: ContentType
    /// Time when tab was added to provide sorting (including CoreData sorting)
    /// Do not support moving tabs on UI, because it won't work now with timestamps
    /// It will require to store indexes in a separate data structure
    public let addedTimestamp: Date

    public var title: String {
        return contentType.title
    }

    /// Not using `UIImage` to not depend on UIKit
    public var previewData: Data?

    public var searchBarContent: String {
        return contentType.searchBarContent
    }

    public var site: Site? {
        return contentType.site
    }

    public func isSelected(_ selectedId: UUID) -> Bool {
        return selectedId == id
    }

    public func getVisualState(_ selectedId: UUID) -> VisualState {
        return isSelected(selectedId) ? .selected : .deselected
    }

    /**
     Initializes an instance of `CoreBrowser.Tab` type.
     */
    public init(contentType: ContentType,
                idenifier: UUID = .init(),
                created: Date = .init()) {
        self.contentType = contentType
        addedTimestamp = created
        id = idenifier
    }

    public static let blank: CoreBrowser.Tab = CoreBrowser.Tab(contentType: .blank)
}

extension Tab: Equatable {
    public static func == (lhs: CoreBrowser.Tab, rhs: CoreBrowser.Tab) -> Bool {
        return lhs.id == rhs.id
    }
}

fileprivate extension String {
    static let defaultTitle = NSLocalizedString("ttl_tab_short_blank",
                                                comment: "Title for tab without any URL or search string")
    static let topSitesTitle = NSLocalizedString("ttl_tab_short_top_sites",
                                                 comment: "Title for tab with list of favorite sites")
}

extension Tab.ContentType: Identifiable {
    public var id: RawValue {
        return self.rawValue
    }

    public typealias ID = RawValue
}

extension Tab.ContentType: CustomStringConvertible {
    public var description: String {
        let key: String

        switch self {
        case .blank:
            key = "txt_tab_content_blank"
        case .homepage:
            key = "txt_tab_content_homepage"
        case .favorites:
            key = "txt_tab_content_favorites"
        case .topSites:
            key = "txt_tab_content_top_sites"
        case .site:
            // site can't be used as a default content for now
            key = ""
        }
        return NSLocalizedString(key, comment: "")
    }
}

extension Tab.ContentType: Hashable { }
extension Tab: Hashable { }
