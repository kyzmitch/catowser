//
//  UIImageView+Extension.swift
//  catowser
//
//  Created by Andrei Ermoshin on 4/30/20.
//  Copyright © 2020 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import AlamofireImage
import UIKit
import CottonViewModels

extension UIImageView {
    func updateImage(from source: ImageSource, calculateAverageColor: Bool = true) {
        af.cancelImageRequest()
        image = nil

        switch source {
        case .image(let cachedImage):
            image = cachedImage
        case .url(let imageURL):
            loadImageFrom(url: imageURL, calculateAverageColor: calculateAverageColor)
        case .urlWithPlaceholder(let imageURL, let cachedImage):
            loadImageFrom(url: imageURL, cachedImage: cachedImage, calculateAverageColor: calculateAverageColor)
        @unknown default:
            fatalError("Unhandled image source case")
        }
    }

    private func loadImageFrom(url: URL, cachedImage: UIImage? = nil, calculateAverageColor: Bool) {
        // https://github.com/Alamofire/AlamofireImage/issues/134#issuecomment-245177689
        // Can't solve image loading for URLs with invalid SSL certificate
        // because with AlamofireImage it's not possible to update evaluators
        // for ServerTrustManager, because it is required to update Session as well and
        // which can't be done when more than one image downloads are happening at the same time.
        //  As an alternative, it's possible to reimplement image downloading based on Alamofire
        // but it requires too much work.
        //  Firefox for iOS doesn't load favicons for URLs with invalid certificates.
        guard !url.hasIPHost else {
            // we even won't try to load the image because with current impl
            // it will fail 100%
            backgroundColor = .black
            return
        }

        // swiftlint:disable:next line_length
        af.setImage(withURL: url, placeholderImage: cachedImage, progressQueue: .global(qos: .userInteractive), imageTransition: .noTransition, runImageTransitionIfCached: false) { [weak self] (dataResponse) in
            guard calculateAverageColor else {
                return
            }
            switch dataResponse.result {
            case .success(let downloadedFavicon):
                let averageColor = downloadedFavicon.firstPixelColor
                guard let color = averageColor else {
                    return
                }

                self?.backgroundColor = color
            case .failure(let afError):
                print("Failed to download image using url: \(afError.localizedDescription)")
            }

        }
    }
}
