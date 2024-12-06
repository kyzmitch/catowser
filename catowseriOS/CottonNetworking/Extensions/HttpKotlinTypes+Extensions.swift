//
//  HttpKotlinTypes+Extensions.swift
//  BrowserNetworking
//
//  Created by Andrei Ermoshin on 4/18/22.
//  Copyright © 2022 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import CottonBase

extension Array where Element == URLQueryItem {
    var kotlinArray: KotlinArray<URLQueryPair> {
        let pairsArray: [URLQueryPair] = self.compactMap({ item in
            guard let value = item.value else {
                return nil
            }
            return .init(name: item.name, value: value)
        })
        let kotlinValue: KotlinArray<URLQueryPair> = .init(size: Int32(pairsArray.count)) { index in
            let ix: Int = index.intValue
            guard ix >= 0 && ix < pairsArray.count else {
                return nil
            }
            return pairsArray[ix]
        }
        return kotlinValue
    }
}
