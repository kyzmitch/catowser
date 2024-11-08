//
//  TabsPreviewsViewController.swift
//  catowser
//
//  Created by Andrei Ermoshin on 23/01/2019.
//  Copyright © 2019 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import UIKit
import CoreBrowser
import Combine
import FeaturesFlagsKit

final class TabsPreviewsViewController<C: Navigating>: BaseViewController,
                                                       CollectionViewInterface,
                                                       UICollectionViewDelegateFlowLayout,
                                                       UICollectionViewDataSource,
                                                       UICollectionViewDelegate
where C.R == TabsScreenRoute {

    private weak var coordinator: C?

    private let viewModel: TabsPreviewsViewModel
    private let featureManager: FeatureManager.StateHolder

    init(
        _ coordinator: C,
        _ viewModel: TabsPreviewsViewModel,
        _ featureManager: FeatureManager.StateHolder
    ) {
        self.coordinator = coordinator
        self.viewModel = viewModel
        self.featureManager = featureManager
        super.init(nibName: nil, bundle: nil)
        
        Task {
            let observingType = await featureManager.observingApiTypeValue()
            if #available(iOS 17.0, *), observingType.isSystemObservation {
                startTabsObservation()
            } else {
                await TabsDataService.shared.attach(self, notify: false)
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var stateHandlerCancellable: AnyCancellable?

    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: collectionLayout)
        cv.register(TabPreviewCell.self)
        cv.contentInset = UIEdgeInsets(top: 0 /* Sizes.searchBarHeight */, left: 0, bottom: 0, right: 0)
        cv.translatesAutoresizingMaskIntoConstraints = false

        return cv
    }()

    private let collectionLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        return layout
    }()

    private lazy var toolbar: UIToolbar = {
        // iOS 13.x fix for phone layout error
        // similar issue and fix:
        // https://github.com/hackiftekhar/IQKeyboardManager/pull/1598/files#diff-f73f23d86e3154de71cd5bd9abf275f0R146
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 1000, height: 44))
        ThemeProvider.shared.setup(toolbar)

        var barItems = [UIBarButtonItem]()
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        barItems.append(space)
        barItems.append(addTabButton)
        toolbar.setItems(barItems, animated: false)
        toolbar.translatesAutoresizingMaskIntoConstraints = false

        return toolbar
    }()

    private lazy var addTabButton: UIBarButtonItem = {
        let img = UIImage(named: "newTabButton-Normal")
        let addTab: Selector = #selector(TabsPreviewsViewController.addTabPressed)
        let btn = UIBarButtonItem(image: img, style: .plain, target: self, action: addTab)
        return btn
    }()

    private let spinnerView: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .large)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.dataSource = self
        collectionView.delegate = self

        view.addSubview(collectionView)
        view.addSubview(toolbar)

        collectionView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: toolbar.topAnchor).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true

        toolbar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        toolbar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true

        stateHandlerCancellable?.cancel()
        stateHandlerCancellable = viewModel.$uxState.sink { [weak self] nextState in
            self?.render(state: nextState)
        }

        render(state: viewModel.uxState)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.load()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stateHandlerCancellable?.cancel()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return Sizes.margin
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let viewWidth = collectionView.bounds.width
        let columnsNumber = CGFloat(numberOfColumns + 1)
        let width = (viewWidth - Sizes.margin * columnsNumber) / CGFloat(numberOfColumns)
        let cellWidth = floor(width)
        let cellHeight = TabPreviewCell.cellHeightForCurrent(traitCollection)
        return CGSize(width: cellWidth, height: cellHeight)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(equalInset: Sizes.margin)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return Sizes.margin
    }

    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.uxState.itemsNumber
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var tab: CoreBrowser.Tab?
        switch viewModel.uxState {
        case .tabs(let dataSource) where indexPath.item < dataSource.value.count:
            // must use `item` for UICollectionView
            tab = dataSource.value[safe: indexPath.item]
        default: break
        }

        guard let correctTab = tab else {
            print("\(#function) wrong index")
            return UICollectionViewCell(frame: .zero)
        }
        let cell = collectionView.dequeueCell(at: indexPath, type: TabPreviewCell.self)
        cell.configure(with: correctTab, at: indexPath.item, delegate: self)
        return cell
    }

    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var tab: CoreBrowser.Tab?
        switch viewModel.uxState {
        case .tabs(let dataSource) where indexPath.item < dataSource.value.count:
            tab = dataSource.value[safe: indexPath.item]
        default:
            coordinator?.showNext(.error)
        }

        guard let correctTab = tab else {
            assertionFailure("\(#function) selected tab wasn't found")
            return
        }

        coordinator?.showNext(.selectTab(correctTab))
        coordinator?.stop()
    }

    // MARK: - private functions

    @objc func addTabPressed() {
        coordinator?.showNext(.addTab)
        // on previews screen will make new added tab always selected
        // same behaviour has Safari and Firefox
        if DefaultTabProvider.shared.selected {
            coordinator?.stop()
        }
    }
    
    private func render(state: TabsPreviewState) {
        collectionView.reloadData()
    }
    
    @available(iOS 17.0, *)
    @MainActor
    private func startTabsObservation() {
        withObservationTracking {
            _ = UIServiceRegistry.shared().tabsSubject.addedTabIndex
        } onChange: {
            Task { [weak self] in
                await self?.handleAddedTabs()
            }
        }
    }
    
    @available(iOS 17.0, *)
    @MainActor
    private func handleAddedTabs() async {
        let subject = UIServiceRegistry.shared().tabsSubject
        guard let index = subject.addedTabIndex else {
            return
        }
        await tabDidAdd(subject.tabs[index], at: index)
    }
}

private struct Sizes {
    static let margin = CGFloat(15)
}

// MARK: - TabsObserver

extension TabsPreviewsViewController: TabsObserver {
    func tabDidAdd(_ tab: CoreBrowser.Tab, at index: Int) async {
        let state = viewModel.uxState
        guard case let .tabs(box) = state else {
            return
        }

        box.value.insert(tab, at: index)
        render(state: state)
    }
}

// MARK: - TabPreviewCellDelegate

extension TabsPreviewsViewController: TabPreviewCellDelegate {
    func tabCellDidClose(at index: Int) async {
        viewModel.closeTab(at: index)
    }
}
