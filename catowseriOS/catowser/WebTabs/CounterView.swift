//
//  CounterView.swift
//  catowser
//
//  Created by Andrei Ermoshin on 28/01/2019.
//  Copyright © 2019 Cotton (former Catowser). All rights reserved.
//

import UIKit
import CoreBrowser
import CottonDataServices

final class CounterView: UIView {
    private let digitLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textAlignment = .center
        label.shadowOffset = CGSize(width: 0, height: 1)
        label.shadowColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        // Value will be set in `TabsObserver` below
        label.text = ""
        return label
    }()

    var digit: Int {
        didSet {
            DispatchQueue.main.async {
                self.digitLabel.text = "\(self.digit)"
            }
        }
    }

    override init(frame: CGRect) {
        digit = 0
        super.init(frame: frame)
        contentMode = .redraw

        addSubview(digitLabel)

        digitLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0).isActive = true
        digitLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0).isActive = true
        digitLabel.topAnchor.constraint(equalTo: topAnchor, constant: 0).isActive = true
        digitLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).isActive = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let expandedBounds = self.bounds.inset(by: UIEdgeInsets(equalInset: -6))
        return expandedBounds.contains(point)
    }
}

extension CounterView: TabsObserver {
    func updateTabsCount(with tabsCount: Int) async {
        self.digit = tabsCount
    }
}
