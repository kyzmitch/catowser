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
import FeatureFlagsKit
import CottonDataServices
import CottonViewModels
import ViewModelKit

final class TabsPreviewsViewController<
    C: Navigating
>: BaseViewController,
   CollectionViewInterface,
   ViewModelConsumer,
   UICollectionViewDelegateFlowLayout,
   UICollectionViewDataSource,
   UICollectionViewDelegate where C.R == TabsScreenRoute {

    private weak var coordinator: C?

    let viewModel: TabsPreviewsViewModel
    private let tabsObserverHolder: TabsObserverHolder
    private let featureManager: FeatureManager.StateHolder
    private let uiServiceRegistry: UIServiceRegistry
    private var dataSource: [CoreBrowser.Tab]
    private var selectedId: CoreBrowser.Tab.ID?
    
    // MARK: - init

    init(
        _ coordinator: C,
        _ viewModel: TabsPreviewsViewModel,
        _ featureManager: FeatureManager.StateHolder,
        _ uiServiceRegistry: UIServiceRegistry,
        _ tabsObserverHolder: TabsObserverHolder
    ) {
        self.coordinator = coordinator
        self.viewModel = viewModel
        self.tabsObserverHolder = tabsObserverHolder
        self.featureManager = featureManager
        self.uiServiceRegistry = uiServiceRegistry
        dataSource = []
        super.init(nibName: nil, bundle: nil)
        
        Task {
            let observingType = await featureManager.observingApiTypeValue()
            if #available(iOS 17.0, *), observingType.isSystemObservation {
                startTabsObservation()
            } else {
                await ServiceRegistry.shared.tabsService.attach(
                    tabsObserverHolder.observer,
                    notify: false
                )
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
        stateHandlerCancellable = startStateObserving()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.sendAction(.load, onComplete: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stateHandlerCancellable?.cancel()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: - ViewModelConsumer
    
    func onStateChange(_ nextState: ViewModel.State) {
        switch nextState {
        case .loading:
            view.addSubview(spinnerView)
        case let .tabs(tabs, selectedTabId):
            dataSource = tabs
            selectedId = selectedTabId
            collectionView.reloadData()
            spinnerView.removeFromSuperview()
        @unknown default:
            fatalError("Unknown view model state")
        }
    }

    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        return Sizes.margin
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let viewWidth = collectionView.bounds.width
        let columnsNumber = CGFloat(numberOfColumns + 1)
        let width = (viewWidth - Sizes.margin * columnsNumber) / CGFloat(numberOfColumns)
        let cellWidth = floor(width)
        let cellHeight = TabPreviewCell.cellHeightForCurrent(traitCollection)
        return CGSize(width: cellWidth, height: cellHeight)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        return UIEdgeInsets(equalInset: Sizes.margin)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        return Sizes.margin
    }

    // MARK: - UICollectionViewDataSource

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        return dataSource.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        // must use `item` for UICollectionView
        let tab: CoreBrowser.Tab? = dataSource[safe: indexPath.item]
        let shouldHighlightTab = tab?.id == selectedId

        guard let correctTab = tab else {
            print("\(#function) wrong index")
            return UICollectionViewCell(frame: .zero)
        }
        let cell = collectionView.dequeueCell(at: indexPath, type: TabPreviewCell.self)
        cell.configure(
            with: correctTab,
            at: indexPath.item,
            delegate: self,
            shouldHighlight: shouldHighlightTab
        )
        return cell
    }

    // MARK: - UICollectionViewDelegate

    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        guard let correctTab = dataSource[safe: indexPath.item] else {
            assertionFailure("\(#function) selected tab wasn't found")
            return
        }

        viewModel.sendAction(.select(correctTab), onComplete: nil)
        coordinator?.stop()
    }

    // MARK: - private functions

    @objc func addTabPressed() {
        viewModel.sendAction(.addDefaultTab, onComplete: nil)
        // on previews screen will make new added tab always selected
        // same behaviour has Safari and Firefox
        if DefaultTabProvider.shared.selected {
            coordinator?.stop()
        }
    }
    
    @available(iOS 17.0, *)
    @MainActor
    private func startTabsObservation() {
        withObservationTracking {
            _ = uiServiceRegistry.tabsSubject.selectedTabId
        } onChange: {
            Task { [weak self] in
                await self?.handleSelectedTab()
            }
        }
    }
    
    @available(iOS 17.0, *)
    @MainActor
    private func handleSelectedTab() async {
        let subject = uiServiceRegistry.tabsSubject
        viewModel.sendAction(
            .selectTabIdWithoutSaving(subject.selectedTabId),
            onComplete: nil
        )
    }
}

private struct Sizes {
    static let margin = CGFloat(15)
}

// MARK: - TabPreviewCellDelegate

extension TabsPreviewsViewController: TabPreviewCellDelegate {
    func tabCellDidClose(at index: Int) {
        viewModel.sendAction(.closeTab(index: index), onComplete: nil)
    }
}
