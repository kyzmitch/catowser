//
//  CoreBrowser.Tab+Extension.swift
//  catowser
//
//  Created by Andrei Ermoshin on 10/18/22.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import CoreBrowser
import UIKit

extension CoreBrowser.Tab {
    /// Preview image of the site if content is .site
    var preview: UIImage? {
        mutating get {
            if let data = previewData {
                return UIImage(data: data)
            } else {
                return nil
            }
        }

        set {
            previewData = newValue?.pngData()
        }
    }
}
