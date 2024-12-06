//
//  AuthChallenge.swift
//  BrowserNetworking
//
//  Created by Andrei Ermoshin on 2/11/20.
//  Copyright © 2020 Cotton/Catowser Andrei Ermoshin. All rights reserved.
//

import Foundation
import Security
import CottonBase
import Alamofire

/**
 https://developer.apple.com/library/archive/technotes/tn2232/_index.html

 The DNS name in the certificate might be a wildcard name, for example, "*.apple.com".
 but `host` parameter could be specific address like "m.apple.com"
 so that, it's required to convert it to wildcard name before check

 If server trust evaluation fails because the server's DNS name does not match the DNS name in the certificate,
 you can work around the failure by overriding the DNS name in the trust object.
 To do this, call SecPolicyCreateSSL to create a new policy object with the correct server name
 and then call SecTrustSetPolicies to apply it to the trust object.

 Typically you would expect to find this DNS name in the subject's Common Name field,
 but it can also be in a Subject Alternative Name extension. If a name is present in
 the Subject Alternative Name extension, it takes priority over the Common Name.

 https://support.apple.com/en-us/HT210176
 TLS server certificates must present the DNS name of the server in the Subject Alternative Name extension
 of the certificate. DNS names in the CommonName of a certificate are no longer trusted.

 https://developer.apple.com/documentation/security/certificate_key_and_trust_services/trust/configuring_a_trust
 */

extension DefaultTrustEvaluator {
    /// Creates server trust evaluator with disabled host validation
    public static func ipHostEvaluator() -> Self {
        return .init(validateHost: false)
    }

    /// Evaluates server trust.
    /// `host` is used only for error messages since it is ip address and should be used for evaluation
    // swiftlint:disable:next cyclomatic_complexity
    public func evaluateWithRecovery(_ trust: SecTrust, forHost host: String) throws {
        guard let kitHost = try? Host(input: host) else {
            try evaluate(trust, forHost: host)
            return
        }

        do {
            try evaluate(trust, forHost: kitHost.rawString)
        } catch AFError.serverTrustEvaluationFailed(let reason) {
            var optionalOutput: AFError.ServerTrustFailureReason.Output?
            switch reason {
            case .defaultEvaluationFailed(output: let output):
                optionalOutput = output
            case .hostValidationFailed(output: let output):
                optionalOutput = output
            case .revocationCheckFailed(output: let output, options: _):
                optionalOutput = output
            default:
                throw AFError.serverTrustEvaluationFailed(reason: reason)
            }

            guard let output = optionalOutput else {
                throw AFError.serverTrustEvaluationFailed(reason: reason)
            }

            switch output.result {
            case .recoverableTrustFailure:
                #if os(iOS)
                guard let cookie = SecTrustCopyExceptions(trust) else {
                    struct OpaqueCookieNil: Error {}
                    throw OpaqueCookieNil()
                }
                #elseif os(macOS)
                let cookie = SecTrustCopyExceptions(trust)
                #endif
                SecTrustSetExceptions(trust, cookie)
                guard SecTrustSetExceptions(trust, cookie) else {
                    throw AFError.serverTrustEvaluationFailed(reason: reason)
                }
                // evaulate one more time
                try evaluate(trust, forHost: kitHost.rawString)
            default:
                throw AFError.serverTrustEvaluationFailed(reason: reason)
            }
        } catch {
            throw error
        }
    }
}
