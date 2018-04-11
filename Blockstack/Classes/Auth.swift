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
        
        let publicKey = Keys.getPublicKeyFromPrivate(transitPrivateKey)
        let address = Keys.getAddressFromPublicKey(publicKey!)
        
        let payload: [String: Any] = [
            "jti": NSUUID().uuidString,
            "iat": Int(Date().timeIntervalSince1970),
            "exp": Int(expiresAt.timeIntervalSince1970),
            "iss": "did:btc-addr:\(address!)",
            "public_keys": [publicKey!],
            "domain_name": appDomain.absoluteString,
            "app_bundle_id": appBundleID,
            "manifest_uri": manifestURI.absoluteString,
            "redirect_uri": redirectURLScheme,
            "version": BlockstackConstants.AuthProtocolVersion,
            "do_not_include_profile": true,
            "supports_hub_url": true,
            "scopes": scopes
        ]
        
        let jsonTokens = JSONTokens(algorithm: "ES256K", privateKey: transitPrivateKey)
        request = jsonTokens.signToken(payload: payload)!
        
        return request
    }
    
    static func handleResponse(_ authResponse: String, transitPrivateKey: String) {
        let jsonTokens = JSONTokens(algorithm: "ES256K", privateKey: transitPrivateKey)
        let decoded = jsonTokens.decodeToken(token: authResponse)
        print(decoded)
    }
}
