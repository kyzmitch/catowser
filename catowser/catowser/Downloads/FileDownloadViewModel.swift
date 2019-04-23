//
//  FileDownloadViewModel.swift
//  catowser
//
//  Created by Andrei Ermoshin on 23/04/2019.
//  Copyright © 2019 andreiermoshin. All rights reserved.
//

import Foundation
import AHDownloadButton
import ReactiveSwift
import Result
import CoreBrowser

protocol FileDownloadDelegate: class {
    func didPressOpenFile(withLocal url: URL)
}

final class FileDownloadViewModel {
    fileprivate let downloadOutput = MutableProperty<DownloadState>(.initial)

    lazy var stateSignal: Signal<DownloadState, NoError> = {
        return downloadOutput.signal
    }()

    fileprivate let batch: Downloadable

    weak var delegate: FileDownloadDelegate?

    init(with batch: Downloadable) {
        self.batch = batch
    }

    fileprivate func download(_ batch: Downloadable) {
        CoreBrowser.DownloadFacade.shared.download(file: batch)
            .observe(on: QueueScheduler.main)
            .startWithResult { [weak self] (result) in
                guard let self = self else {
                    return
                }
                switch result {
                case .success(let value):
                    switch value {
                    case .progress(let progress):
                        let converted = CGFloat(progress.fractionCompleted)
                        self.downloadOutput.value = .in(progress: converted)
                    case .complete(let localURL):
                        self.downloadOutput.value = .finished(localURL)
                    }
                case .failure(let error):
                    print("download error: \(error)")
                    self.downloadOutput.value = .error(error)
                }
        }
    }

    enum DownloadState {
        case initial
        case started
        case `in`(progress: CGFloat)
        case finished(URL)
        case error(Error)
    }
}

extension FileDownloadViewModel: AHDownloadButtonDelegate {
    func downloadButton(_ downloadButton: AHDownloadButton, tappedWithState state: AHDownloadButton.State) {
        switch state {
        case .startDownload:
            downloadOutput.value = .started
            self.download(batch)
        case .pending, .downloading:
            break
        case .downloaded:
            guard case let .finished(url) = downloadOutput.value else {
                assertionFailure("Unexpected state during opening")
                return
            }
            delegate?.didPressOpenFile(withLocal: url)
            break
        }
    }
}
