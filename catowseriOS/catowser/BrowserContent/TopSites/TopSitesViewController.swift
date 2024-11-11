//
//  TopSitesViewController.swift
//  catowser
//
//  Created by Andrei Ermoshin on 22/04/2019.
//  Copyright © 2019 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import UIKit
import CottonBase

final class TopSitesViewController<C: Navigating>: BaseViewController,
                                                   UICollectionViewDataSource,
                                                   UICollectionViewDelegateFlowLayout
where C.R == TopSitesRoute {

    @IBOutlet fileprivate weak var collectionView: UICollectionView!
    weak var coordinator: C?
    private let vm: TopSitesViewModel
    
    init(
        nibName nibNameOrNil: String?,
        bundle nibBundleOrNil: Bundle?,
        vm: TopSitesViewModel
    ) {
        self.vm = vm
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // this isn't called for Nib associated with single view controller
        // as a File's owner. called only for archives from nib
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.backgroundColor = #colorLiteral(red: 0.9647058824, green: 0.9647058824, blue: 0.9647058824, alpha: 1)
        collectionView.register(SiteCollectionViewCell.self)
        collectionView.dataSource = self
        collectionView.delegate = self
    }

    // MARK: - UICollectionViewDataSource

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        return vm.topSites.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueCell(at: indexPath, type: SiteCollectionViewCell.self)
        guard let site = vm.topSites[safe: indexPath.row] else {
            return cell
        }
        cell.reloadSiteCell(with: site)
        return cell
    }

    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        return SiteCollectionViewCell.size(for: traitCollection)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        return UIEdgeInsets(equalInset: ImageViewSizes.spacing)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard let site = vm.topSites[safe: indexPath.row] else {
            return
        }
        vm.replaceSelected(tabContent: .site(site))
    }
}
