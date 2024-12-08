//
//  TabView.swift
//  catowser
//
//  Created by admin on 12/06/2017.
//  Copyright © 2017 Cotton (former Catowser). All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics
import CoreBrowser
import CottonBase
import FeatureFlagsKit
#if canImport(Combine)
import Combine
#endif
import CottonNetworking
import CottonDataServices

@MainActor protocol TabDelegate: AnyObject {
    func tabViewDidClose(_ tabView: TabView) async
}

/// The tab view for tablets
final class TabView: UIView {

    private let viewModel: TabViewModel
    private var stateHandler: AnyCancellable?
    private weak var delegate: TabDelegate?

    private lazy var centerBackground: UIView = {
        let centerBackground = UIView()
        centerBackground.translatesAutoresizingMaskIntoConstraints = false
        return centerBackground
    }()

    private let closeButton: ButtonWithDecreasedTouchArea = {
        let closeButton = ButtonWithDecreasedTouchArea()
        closeButton.setImage(UIImage(named: "tabCloseButton-Normal"), for: UIControl.State())
        closeButton.tintColor = UIColor.lightGray
        if #unavailable(iOS 15) {
            closeButton.imageEdgeInsets = UIEdgeInsets(equalInset: 10.0)
        }
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        return closeButton
    }()

    private let titleText: UILabel = {
        let titleText = UILabel()
        titleText.textAlignment = .left
        titleText.isUserInteractionEnabled = false
        titleText.numberOfLines = 1
        titleText.font = UIFont.boldSystemFont(ofSize: 10.0)
        titleText.translatesAutoresizingMaskIntoConstraints = false
        return titleText
    }()

    private let highlightLine: UIView = {
        let line = UIView()
        line.backgroundColor = UIConstants.webSiteTabHighlitedLineColour
        line.isHidden = true
        line.translatesAutoresizingMaskIntoConstraints = false
        return line
    }()

    let faviconImageView: UIImageView = {
        let favicon = UIImageView()
        favicon.layer.cornerRadius = 2.0
        favicon.layer.masksToBounds = true
        favicon.translatesAutoresizingMaskIntoConstraints = false
        return favicon
    }()

    // MARK: - init

    required init?(coder aDecoder: NSCoder) {
        fatalError("\(#function): has not been implemented")
    }

    init(_ frame: CGRect, _ viewModel: TabViewModel, _ delegate: TabDelegate) {
        self.viewModel = viewModel
        self.delegate = delegate
        super.init(frame: frame)
        layout()
    }

    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)

        Task {
            await TabsDataServiceFactory.shared.attach(viewModel, notify: false)
        }
        stateHandler?.cancel()
        stateHandler = viewModel.$state.sink(receiveValue: onStateChange)
        viewModel.load()
    }

    private func layout() {
        contentMode = .redraw
        addSubview(centerBackground)
        addSubview(faviconImageView)
        addSubview(titleText)
        addSubview(closeButton)
        addSubview(highlightLine)

        closeButton.addTarget(self,
                              action: #selector(handleClosePressed),
                              for: .touchUpInside)

        centerBackground.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        centerBackground.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        centerBackground.topAnchor.constraint(equalTo: topAnchor).isActive = true
        centerBackground.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

        faviconImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        faviconImageView.widthAnchor.constraint(equalToConstant: 18).isActive = true
        faviconImageView.heightAnchor.constraint(equalTo: faviconImageView.widthAnchor).isActive = true
        faviconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10).isActive = true

        titleText.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        titleText.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        titleText.leadingAnchor.constraint(equalTo: faviconImageView.trailingAnchor, constant: 10).isActive = true
        titleText.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: 10).isActive = true

        closeButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        closeButton.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        closeButton.widthAnchor.constraint(equalTo: heightAnchor).isActive = true
        closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5).isActive = true

        highlightLine.topAnchor.constraint(equalTo: topAnchor).isActive = true
        highlightLine.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -2).isActive = true
        highlightLine.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 2).isActive = true
        highlightLine.heightAnchor.constraint(equalToConstant: .highlightLineWidth).isActive = true
    }

    override var intrinsicContentSize: CGSize {
        get {
            if traitCollection.horizontalSizeClass == .compact {
                return CGSize(width: .compactTabWidth, height: .tabHeight)
            } else if traitCollection.horizontalSizeClass == .regular {
                return CGSize(width: .regularTabWidth, height: .tabHeight)
            } else {
                return CGSize(width: .tabWidth, height: .tabHeight)
            }
        }
    }

    override var canBecomeFirstResponder: Bool {
        get {
            // NOTE: experimenting with UIResponder methods, default is NO
            return false
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            // https://github.com/kyzmitch/Cotton/issues/16
            let location = touch.location(in: self.superview)
            if self.frame.contains(location) {
                handleTapGesture()
                break
            }
        }
    }

    private func onStateChange(_ state: TabViewState) {
        centerBackground.backgroundColor = state.backgroundColor
        backgroundColor = state.realBackgroundColour
        highlightLine.isHidden = !state.isSelected
        titleText.textColor = state.titleColor
        titleText.text = state.title

        guard let favicon = state.favicon else {
            return
        }
        faviconImageView.updateImage(from: favicon)
    }
}

private extension TabView {
    @objc func handleClosePressed() {
        viewModel.close()
        Task {
            await delegate?.tabViewDidClose(self)
        }
    }

    func handleTapGesture() {
        // Can mark it as selected on view layer right away
        // with following code `visualState = .selected`
        // but still need to update same state for
        // previously selected tab (deselect it)
        viewModel.activate()
    }
}

extension UIEdgeInsets {
    init(equalInset inset: CGFloat) {
        self.init()
        top = inset
        left = inset
        right = inset
        bottom = inset
    }
}

private class ButtonWithDecreasedTouchArea: UIButton {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        // decrease touch area for control in all directions by 20

        let area = self.bounds.insetBy(dx: 5, dy: 5)
        return area.contains(point)
    }
}
