//
//  BrowserViewController.swift
//  catowser
//
//  Created by admin on 18/06/2017.
//  Copyright © 2017 andreiermoshin. All rights reserved.
//

import UIKit
import CoreGraphics
import SnapKit

class BrowserViewController: BaseViewController {
    
    public var viewModel: BrowserViewModel? {
        willSet {
            if let vm = newValue {
                stackViewScrollableContainer.snp.makeConstraints { (maker) in
                    maker.height.equalTo(vm.tabsContainerHeight)
                    maker.topMargin.equalTo(view).offset(10)
                    maker.leading.equalTo(view).offset(0)
                    maker.trailing.equalTo(view).offset(0)
                }
            }
        }
    }
    
    private let tabsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 10
        stackView.axis = .horizontal
        return stackView
    }()
    
    private let stackViewScrollableContainer: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bounces = false
        return scrollView
    }()
    
    private let webContentBackgroundView: UIView = {
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor(colorLiteralRed: 192/255.0, green: 240/255.0, blue: 144/255.0, alpha: 1.0)
        return backgroundView
    }()
    
    private func addTabView(_ tabView: TabView) {
        tabsStackView.addArrangedSubview(tabView)
        view.layoutIfNeeded()
        // TODO: actually possibly need to just add constant width
        // view with gradient and make scroll view transparrent
        resizeTabsBackLayer()
    }
    
    private func removeTabView(_ tabView: TabView) {
        tabsStackView.removeArrangedSubview(tabView)
        view.layoutIfNeeded()
        resizeTabsBackLayer()
    }
    
    override func viewDidLoad() {
        view.backgroundColor = UIColor.white
        
        view.addSubview(stackViewScrollableContainer)
        stackViewScrollableContainer.snp.makeConstraints { (maker) in
            maker.height.equalTo(40.0)
            maker.topMargin.equalTo(view).offset(10)
            maker.leading.equalTo(view).offset(0)
            maker.trailing.equalTo(view).offset(0)
        }
        
        view.addSubview(webContentBackgroundView)
        webContentBackgroundView.snp.makeConstraints { (maker) in
            maker.top.equalTo(stackViewScrollableContainer.snp.bottom)
            maker.leading.equalTo(view).offset(0)
            maker.trailing.equalTo(view).offset(0)
            maker.bottom.equalTo(view).offset(0)
        }
        
        stackViewScrollableContainer.addSubview(tabsStackView)
        tabsStackView.snp.makeConstraints { (maker) in
            maker.top.equalTo(0)
            maker.bottom.equalTo(0)
            maker.leading.equalTo(0)
            maker.trailing.equalTo(0)
            maker.height.equalToSuperview()
        }
        
        // Code for debug to check tabs look and scrolling
        let tabRect = CGRect(origin: CGPoint.zero, size: CGSize.zero)
        for i in 0..<10 {
            let tabView = TabView(frame: tabRect)
            tabView.delegate = self
            let title = "Home \(i)"
            tabView.modelView = TabViewModel(tabModel: TabModel(tabTitle: title))
            addTabView(tabView)
        }
    }
    
    private var tabsViewBackLayer: CAGradientLayer?
    
    private func resizeTabsBackLayer() -> Void {
        tabsViewBackLayer?.removeFromSuperlayer()
        let size = stackViewScrollableContainer.contentSize
        tabsViewBackLayer = CAGradientLayer.lightBackgroundGradientLayer(size: size)
        stackViewScrollableContainer.layer.insertSublayer(tabsViewBackLayer!, at: 0)
    }
    
    override func viewDidLayoutSubviews() {
        resizeTabsBackLayer()
    }
}

extension BrowserViewController: TabDelegate {
    func tab(_ tab: TabView, didPressCloseButton wasActive: Bool) {
        print("\(#function): closed")
        removeTabView(tab)
    }
}

extension CAGradientLayer {
    class func lightBackgroundGradientLayer(size: CGSize) -> CAGradientLayer {
        let layer = CAGradientLayer()
        layer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        let topColor: CGColor = UIColor.white.cgColor
        let bottomColor: CGColor = UIColor.gray.cgColor
        layer.colors = [topColor, bottomColor]
        layer.locations = [0.0, 1.0]
        return layer
    }
}
