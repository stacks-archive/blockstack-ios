//
//  Auth.swift
//  Blockstack
//
//  Created by Yukan Liao on 2018-03-28.
//

import Foundation

open class Auth {
    static func makeRequest(transitPrivateKey: String,
                            redirectURLScheme: String,
                            manifestURI: URL,
                            appDomain: URL,
                            appBundleID: String,
                            scopes: Array<String> = ["store_write"],
                            expiresAt: Date = Date().addingTimeInterval(TimeInterval(60.0 * 60.0))) -> String {
        var request: String
        
        let payload: [String: Any] = [
            "jti": NSUUID().uuidString,
            "iat": Int(Date().timeIntervalSince1970),
            "exp": Int(expiresAt.timeIntervalSince1970),
            "iss": "did:btc-addr:1L4T13HMiF9Wy4onSkbVMAbavh28h8f1iw",
            "public_keys": ["03665231ec60f1a99b961b41f2d66e47c729c2818e1a50f2b16c5cfa57ae57e488"],
            "domain_name": appDomain.absoluteString,
            "app_bundle_id": appBundleID,
            "manifest_uri": manifestURI.absoluteString,
            "redirect_uri": redirectURLScheme,
            "version": BlockstackConstants.AuthProtocolVersion,
            "do_not_include_profile": true,
            "supports_hub_url": true,
            "scopes": scopes
        ]
        
        let jsonTokens = JSONTokens(algorithm: "ES256K", privateKey: "0ed2e16734bbc6c06e7556367ae1546090bee0a1398b3aaf6613537c1b5d9710")
        request = jsonTokens.signToken(payload: payload)!
        
        return request
    }
}
