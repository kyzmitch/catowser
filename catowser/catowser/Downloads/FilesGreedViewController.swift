//
//  FilesGreedViewController.swift
//  catowser
//
//  Created by Andrei Ermoshin on 03/04/2019.
//  Copyright © 2019 andreiermoshin. All rights reserved.
//

import UIKit
import CoreBrowser
import JSPlugins

protocol FilesGreedPresenter: class {
    func reloadWith(source: TagsSiteDataSource, completion: (() -> Void)?)
}

protocol FileDownloadViewDelegate: class {
    func didRequestOpen(local url: URL, from view: UIView)
    func didPressDownload(callback: @escaping (URL?) -> Void)
}

final class FilesGreedViewController: UITableViewController, CollectionViewInterface {
    static func newFromStoryboard() -> FilesGreedViewController {
        let name = String(describing: self)
        return FilesGreedViewController.instantiateFromStoryboard(name, identifier: name)
    }

    private var backLayer: CAGradientLayer?

    fileprivate var filesDataSource: TagsSiteDataSource?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.rowHeight = Sizes.rowHeight
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        backLayer?.removeFromSuperlayer()
        backLayer = .lightBackgroundGradientLayer(bounds: view.bounds, lightTop: false)
        tableView.layer.insertSublayer(backLayer!, at: 0)
    }
}

fileprivate extension FilesGreedViewController {
    struct Sizes {
        static let margin = CGFloat(8)
        static let rowHeight = CGFloat(120)
    }
}

// MARK: UITableViewDataSource
extension FilesGreedViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filesDataSource?.itemsCount ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(for: indexPath, type: DownloadButtonCellView.self)

        let tableW = tableView.bounds.width - Sizes.margin * 2

        let desiredLabelW = tableW - cell.previewImageView.center.x - cell.previewImageView.bounds.width / 2 - cell.downloadButton.bounds.width
        cell.titleLabel.preferredMaxLayoutWidth = desiredLabelW

        cell.delegate = self

        switch filesDataSource {
        case .instagram(let nodes)?:
            let node = nodes[indexPath.item]
            cell.viewModel = FileDownloadViewModel(with: node)
            cell.titleLabel.text = node.fileName
            cell.previewURL = node.thumbnailUrl
        case .t4?:
            cell.previewURL = nil
            // for this type we can only load preview and title
            // download URL should be chosen e.g. by using action sheet
            break
        default:
            break
        }

        return cell
    }
}

extension FilesGreedViewController: AnyViewController {}

// MARK: Files Greed Presenter
extension FilesGreedViewController: FilesGreedPresenter {
    func reloadWith(source: TagsSiteDataSource, completion: (() -> Void)? = nil) {
        guard filesDataSource != source else {
            completion?()
            return
        }

        filesDataSource = source

        if let afterReloadClosure = completion {
            tableView.reloadData(afterReloadClosure)
        } else {
            tableView.reloadData()
        }
    }
}

// MARK: File Download View Delegate
extension FilesGreedViewController: FileDownloadViewDelegate {
    func didRequestOpen(local url: URL, from view: UIView) {
        let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activity.title = NSLocalizedString("ttl_video_share", comment: "Share video")

        if let popoverPresenter = activity.popoverPresentationController {
            let btnBounds = view.bounds
            let btnOrigin = view.frame.origin
            let rect = CGRect(x: btnOrigin.x,
                              y: btnOrigin.y,
                              width: btnBounds.width,
                              height: btnBounds.height)
            popoverPresenter.sourceView = view
            popoverPresenter.sourceRect = rect
        }
        present(activity, animated: true)
    }

    func didPressDownload(callback: @escaping (URL?) -> Void) {
        let title = NSLocalizedString("ttl_video_quality_selection", comment: "Text to ask about video quality")
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        guard case let .t4(videoContainer)? = filesDataSource else {
            callback(nil)
            return
        }
        for (quality, url) in videoContainer.variants {
            let action = UIAlertAction(title: quality.rawValue, style: .default) { (_) in
                callback(url)
            }
            alert.addAction(action)
        }

        let cancelTtl = NSLocalizedString("ttl_common_cancel", comment: "Button title when need dismiss alert")
        let cancel = UIAlertAction(title: cancelTtl, style: .cancel) { (_) in
            callback(nil)
        }
        alert.addAction(cancel)
        present(alert, animated: true)
    }
}

/// Declaring following properties here, because type and protocol are from different frameworks.
/// So, this place is neutral.
extension InstagramVideoNode: Downloadable {
    public var url: URL {
        return videoUrl
    }
}
