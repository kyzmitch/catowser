//
//  TabViewState.swift
//  CottonViewModels
//
//  Created by Andrei Ermoshin on 7/22/23.
//  Copyright © 2023 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import Foundation
import UIKit

public enum ImageSource {
    case url(URL)
    case image(UIImage)
    case urlWithPlaceholder(URL, UIImage)
}

public struct TabViewState {
    public let backgroundColor: UIColor
    public let realBackgroundColour: UIColor
    public let isSelected: Bool
    public let titleColor: UIColor
    public let title: String
    public let favicon: ImageSource?

    public init(
        _ backgroundColor: UIColor,
        _ realBackgroundColour: UIColor,
        _ isSelected: Bool,
        _ titleColor: UIColor,
        _ title: String,
        _ favicon: ImageSource?
    ) {
        self.backgroundColor = backgroundColor
        self.realBackgroundColour = realBackgroundColour
        self.isSelected = isSelected
        self.titleColor = titleColor
        self.title = title
        self.favicon = favicon
    }

    static func selected(
        _ title: String,
        _ newFavicon: ImageSource?
    ) -> TabViewState {
        TabViewState(
            .superLightGray,
            UIColor.clear,
            true,
            .lightGrayText,
            title,
            newFavicon
        )
    }

    static func deSelected(
        _ title: String,
        _ newFavicon: ImageSource?
    ) -> TabViewState {
        .init(
            .normallyLightGray,
            UIColor.clear,
            false,
            .darkGrayText,
            title,
            newFavicon
        )
    }

    func withNew(
        _ title: String,
        _ newFavicon: ImageSource?
    ) -> TabViewState {
        TabViewState(
            backgroundColor,
            realBackgroundColour,
            isSelected,
            titleColor,
            title,
            newFavicon
        )
    }

    func selected() -> TabViewState {
        TabViewState(
            .superLightGray,
            UIColor.clear,
            true,
            .lightGrayText,
            title,
            favicon
        )
    }

    func deSelected() -> TabViewState {
        TabViewState(
            .normallyLightGray,
            UIColor.clear,
            false,
            .darkGrayText,
            title,
            favicon
        )
    }
}

extension UIColor {
    static let superLightGray = UIColor(
        displayP3Red: 0.96,
        green: 0.96,
        blue: 0.96,
        alpha: 1.0
    )
    static let normallyLightGray = UIColor(
        displayP3Red: 0.71,
        green: 0.71,
        blue: 0.71,
        alpha: 1.0
    )
    static let darkGrayText = UIColor(
        displayP3Red: 0.32,
        green: 0.32,
        blue: 0.32,
        alpha: 1.0
    )
    static let lightGrayText = UIColor(
        displayP3Red: 0.14,
        green: 0.14,
        blue: 0.14,
        alpha: 1.0
    )
}
