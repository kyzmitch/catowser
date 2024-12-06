//
//  Downloadable.swift
//  BrowserNetworking
//
//  Created by Andrei Ermoshin on 4/22/20.
//  Copyright © 2020 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import Foundation
import Alamofire
@preconcurrency import ReactiveSwift
#if canImport(CryptoKit)
import CryptoKit
#endif
import CottonBase

/// Represents a remote file which can be downloaded and stored locally
public protocol Downloadable {
    /// Remote address of a file
    var url: URL { get }
    /// Site name or domain name where the remote object is located
    var hostname: String { get }
    /// Kind of name of the remote file which is usually not very filesystem friendly
    var fileDescription: String { get }
    /**
     Local file name, must be the same for same file description and
     hostname to be able to not re-download same resource
     */
    var fileName: String { get }
    /// iOS sandbox specific option which prevents iCloud from backing up the local file
    var excludeFromBackup: Bool { get }
}

extension Downloadable {
    public var excludeFromBackup: Bool {
        return true
    }

    public var fileName: String {
        if #available(iOS 13.0, *) {
            var md5Hasher = Insecure.MD5()
            let dataArray = fileDescription.utf8.map { UInt8($0)}
            md5Hasher.update(data: dataArray)
            let digest = md5Hasher.finalize()
            return "\(hostname)_\(digest.description)"
        } else {
            var hasher: Hasher = .init()
            fileDescription.hash(into: &hasher)
            return "\(hostname)_\(hasher.finalize())"
        }
    }

    public func fileAtDestination() -> URL? {
        do {
            let destination = try sandboxDestination()
            let dummyURL: URL = .init(fileURLWithPath: "")
            let dummyResponse: HTTPURLResponse = .init()
            let fileURL: URL = destination(dummyURL, dummyResponse).destinationURL
            let isExist = FileManager.default.fileExists(atPath: fileURL.path)
            return isExist ? fileURL : nil
        } catch {
            return nil
        }
    }

    /// Path to temporary file to not waste RAM.
    /// You can't participate in the files app (or iTunes File Sharing)
    /// if you don't store your files in the Documents folder.
    func sandboxDestination() throws -> DownloadRequest.Destination {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        assert(urls.count != 0, "Failed to find documents directory")
        guard let documentsURL = urls.first else {
            throw BrowserNetworking.DownloadError.noDocumentsDirectory
        }
        return documentsURL.destination(using: fileName)
    }
}

fileprivate extension URL {
    func destination(using name: String) -> DownloadRequest.Destination {
        let nameWithoutSpaces = name.replacingOccurrences(of: " ", with: "_")
        let fileURL = self.appendingPathComponent(nameWithoutSpaces, isDirectory: true)
        let destination: DownloadRequest.Destination = { _, _ in
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }

        return destination
    }
}

/// Probably temporarily namespace (types defined in it are used to belong to HttpKit namespace)
public enum BrowserNetworking {}

extension BrowserNetworking {
    public enum ProgressResponse<T> {
        case progress(Progress)
        case complete(T)
    }
}

extension BrowserNetworking {
    public enum DownloadError: LocalizedError {
        case zombyInstance
        case noDocumentsDirectory
        case noAppGroupDirectory
        case failedCreateFileProviderFolder
        case noCorrectDownloadDestination
        case failedExcludeFromBackup(Error)
        case networkError(Error)
        case noHttpHeadersInResponse
        case noContentLengthHeader
        case stringToIntFailed
        case urlRequestInit(Error)

        public var description: String {
            switch self {
            case .failedExcludeFromBackup(let error):
                return "failed to exclude download url from backup: \(error)"
            case .networkError(let error):
                return "network error: \(error)"
            case .urlRequestInit(let error):
                return "failed to construct URLRequest: \(error)"
            default:
                return "\(self)"
            }
        }
    }
}

extension BrowserNetworking {
    fileprivate var appGroupIdentifier: String {
        "group.com.ae.cotton-browser"
    }

    public typealias FileDownloadProducer = SignalProducer<ProgressResponse<URL>, DownloadError>
    public typealias RemoteFileInfoProducer = SignalProducer<Int, DownloadError>

    /// Sends download request for remote file
    ///
    /// - Parameter file: All info about remote file and info about how it should be saved
    /// - Returns: Signal Producer with progress
    public static func download(file: Downloadable) -> FileDownloadProducer {
        let producer = FileDownloadProducer { (observer, _) in
            let destination: DownloadRequest.Destination

            do {
                destination = try file.sandboxDestination()
            } catch {
                observer.send(error: .noDocumentsDirectory)
                return
            }

            let request = AF.download(file.url, method: .get, to: destination)
            request.downloadProgress(queue: .main) { (progress) in
                observer.send(value: .progress(progress))
            }.responseData(queue: .main) { (response) in
                switch response.result {
                case .success:
                    guard var destinationURL = response.fileURL else {
                        observer.send(error: .noCorrectDownloadDestination)
                        return
                    }
                    var values = URLResourceValues()
                    values.isExcludedFromBackup = file.excludeFromBackup
                    do {
                        try destinationURL.setResourceValues(values)
                    } catch {
                        observer.send(error: .failedExcludeFromBackup(error))
                        return
                    }

                    observer.send(value: .complete(destinationURL))
                    observer.sendCompleted()
                case .failure(let error):
                    observer.send(error: .networkError(error))
                }
            }
        }

        return producer
    }

    /**
     Fetches info of remote file like file size which expect to be dowloaded.
     https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Length
     The Content-Length entity header indicates the size of the entity-body, in bytes, sent to the recipient.
     https://tools.ietf.org/html/rfc7230#section-3.3.2
     A server MAY send a Content-Length header field in a response to a
     HEAD request.

     */
    public static func fetchRemoteResourceInfo(url: URL) -> RemoteFileInfoProducer {
        let producer = RemoteFileInfoProducer { (observer, _) in
            let request: URLRequest
            do {
                request = try URLRequest(url: url, method: .head)
            } catch {
                observer.send(error: .urlRequestInit(error))
                return
            }
            AF.request(request).response { (afResponse) in
                if let networkError = afResponse.error {
                    observer.send(error: .networkError(networkError))
                    return
                }
                guard let headers = afResponse.response?.headers else {
                    observer.send(error: .noHttpHeadersInResponse)
                    return
                }
                let key = CottonBase.HTTPHeader.ContentLength(length: 0).key
                guard let contentLengthValue = headers.value(for: key) else {
                    observer.send(error: .noContentLengthHeader)
                    return
                }
                guard let contentLength = Int(contentLengthValue, radix: 10) else {
                    observer.send(error: .stringToIntFailed)
                    return
                }
                observer.send(value: contentLength)
                observer.sendCompleted()
            }
        }
        return producer
    }
}
