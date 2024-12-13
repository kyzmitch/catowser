//
//  SiteCollectionViewCell.swift
//  catowser
//
//  Created by Andrei Ermoshin on 06/05/2019.
//  Copyright © 2019 Cotton (former Catowser). All rights reserved.
//

import UIKit
import CoreBrowser
import Combine
import CottonNetworking
import CottonBase
import FeatureFlagsKit

enum ImageViewSizes {
    static let imageHeight: CGFloat = 87
    static let titleHeight: CGFloat = 21
    static let spacing: CGFloat = 20
    static let titleFontSize: CGFloat = 10
}

final class SiteCollectionViewCell: UICollectionViewCell, FaviconImageViewable {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.isUserInteractionEnabled = false
        label.numberOfLines = 2
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 8)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - FaviconImageViewable

    let faviconImageView: UIImageView = {
        let favicon = UIImageView()
        favicon.layer.masksToBounds = true
        favicon.layer.cornerRadius = 3
        favicon.translatesAutoresizingMaskIntoConstraints = false
        return favicon
    }()

    // MARK: - init

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(faviconImageView)
        addSubview(titleLabel)

        faviconImageView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        faviconImageView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        faviconImageView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        faviconImageView.bottomAnchor.constraint(equalTo: titleLabel.topAnchor).isActive = true

        titleLabel.heightAnchor.constraint(equalToConstant: ImageViewSizes.titleHeight).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - utility methods

    static func size(for traitCollection: UITraitCollection) -> CGSize {
        let imageViewHeight: CGFloat
        if traitCollection.verticalSizeClass == .compact {
            imageViewHeight = ImageViewSizes.imageHeight
        } else if traitCollection.horizontalSizeClass == .compact {
            imageViewHeight = ImageViewSizes.imageHeight
        } else {
            imageViewHeight = ImageViewSizes.imageHeight
        }

        return CGSize(width: imageViewHeight, height: imageViewHeight + ImageViewSizes.titleHeight)
    }
}

extension SiteCollectionViewCell: ReusableItem {}

extension SiteCollectionViewCell {
    func reloadSiteCell(with site: Site) {
        // `TabViewModel` can be used instead, but cell view init doesn't allow to inject it normally
        titleLabel.text = site.title
        if let hqImage = site.favicon() {
            faviconImageView.image = hqImage
            return
        }
        faviconImageView.image = nil

        Task {
            let useDoH = await FeatureManager.shared.boolValue(of: .dnsOverHTTPSAvailable)
            await reloadImageWith(site, useDoH)
        }
    }
}
