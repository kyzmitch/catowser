//
//  WebViewAuthChallengeHandler.swift
//  catowser
//
//  Created by Andrei Ermoshin on 5/3/20.
//  Copyright © 2020 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import WebKit
import CottonBase
import Alamofire
import Foundation
import CottonNetworking

/// Web view authentication challenge handler, should be on main actor because it uses web view
@MainActor final class WebViewAuthChallengeHandler: Sendable {
    typealias AuthHandler = @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void

    private let urlInfo: URLInfo
    private let challenge: URLAuthenticationChallenge
    private let completionHandler: AuthHandler
    private let webView: WKWebView
    /// There is an Xcode warning about not calling that on main thread, so, using custom queue
    private let queue: DispatchQueue
    private var logAuthChallenge = false

    init(_ urlInfo: URLInfo,
         _ webView: WKWebView,
         _ challenge: URLAuthenticationChallenge,
         _ completionHandler: @escaping AuthHandler) {
        self.urlInfo = urlInfo
        self.webView = webView
        self.challenge = challenge
        self.completionHandler = completionHandler
        queue = DispatchQueue(label: .queueNameWith(suffix: "webview.auth-challenge"))
    }

    func solve(completion: @MainActor @Sendable @escaping (Bool?) -> Void) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust else {
            queue.async {
                Task { [weak self] in
                    self?.completionHandler(.performDefaultHandling, nil)
                }
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
            return
        }
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            queue.async { [weak self] in
                self?.completionHandler(.performDefaultHandling, nil)
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
            return
        }
        let possibleIPAddress = urlInfo.ipAddressString
        let rawDomainName = urlInfo.domainName.rawString
        let challengeHost = challenge.protectionSpace.host
        if logAuthChallenge {
            let logString = """
handleServerTrust: domainName[\(rawDomainName)],
challengeHost[\(challengeHost)], ip[\(possibleIPAddress ?? "none")]
"""
            print(logString)
        }
        if let ipAddress = possibleIPAddress, ipAddress == challenge.protectionSpace.host {
            handleServerTrust(serverTrust,
                              rawDomainName,
                              completionHandler,
                              completion)
        } else if !urlInfo.host().isSimilar(name: challenge.protectionSpace.host) {
            // Here web site is trying to complete navigation
            // requests for supplementary hosts like analytics.
            // Obviously they're using own certificates to validate SSL
            queue.async { [weak self] in
                self?.completionHandler(.performDefaultHandling, nil)
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        } else {
            let credential = URLCredential(trust: serverTrust)
            queue.async { [weak self] in
                self?.completionHandler(.useCredential, credential)
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
}

private extension WebViewAuthChallengeHandler {
    func handleServerTrust(_ serverTrust: SecTrust,
                           _ host: String,
                           _ completionHandler: @escaping AuthHandler,
                           _ completion: @MainActor @escaping @Sendable (Bool?) -> Void) {

        do {
            let evaluator: DefaultTrustEvaluator = .ipHostEvaluator()
            /**
             Even with disabled host validation for certificate
             the check fails, most likely it's still because
             requested host name is ip address and it is checked anyway
             with certificate host names list.
             So that, possibly by removing specific certificate from chain
             it will be possible to validate only by using root certificates.
             */

            var certificates = serverTrust.af.certificates
            if logAuthChallenge {
                print("handleServerTrust: domain name - \(host) has \(certificates.count) certificates")
                for cert in certificates {
                    let string: String? = SecCertificateCopySubjectSummary(cert) as String?
                    print("handleServerTrust: certificate[\(string ?? "none")]")
                }
            }
            _ = certificates.removeFirst()
            try serverTrust.af.setAnchorCertificates(certificates)
            try evaluator.evaluateWithRecovery(serverTrust, forHost: host)
            let credential = URLCredential(trust: serverTrust)
            queue.async { [weak self] in
                self?.completionHandler(.useCredential, credential)
                DispatchQueue.main.async {
                    completion(true)
                }
            }
        } catch {
            if logAuthChallenge {
                let msg = "handleServerTrust: validation failed.\n\n \(error.localizedDescription)\n\n\(host)"
                print("Error: \(msg)")
            }
            let credential = URLCredential(trust: serverTrust)
            queue.async { [weak self] in
                self?.completionHandler(.useCredential, credential)
                DispatchQueue.main.async {
                    completion(true)
                }
            }
        }
    }
}

extension WebViewAuthChallengeHandler: Hashable {
    nonisolated static func == (lhs: WebViewAuthChallengeHandler, rhs: WebViewAuthChallengeHandler) -> Bool {
        guard lhs.webView === rhs.webView else {
            return false
        }
        guard lhs.challenge == rhs.challenge else {
            return false
        }
        guard lhs.urlInfo == rhs.urlInfo else {
            return false
        }
        return true
    }

    nonisolated public func hash(into hasher: inout Hasher) {
        hasher.combine(challenge)
        hasher.combine(urlInfo)
    }
}
