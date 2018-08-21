//
//  Auth.swift
//  Blockstack
//
//  Created by Yukan Liao on 2018-03-28.
//

import Foundation

public enum AuthResult {
    case success(userData: UserData)
    case cancelled
    case failed(Error?)
}

open class Auth {
    static func makeRequest(transitPrivateKey: String,
                            redirectURLScheme: String,
                            manifestURI: URL,
                            appDomain: URL,
                            appBundleID: String,
                            scopes: Array<String>,
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
    
    static func decodeResponse(_ authResponse: String, transitPrivateKey: String) -> Token? {
        let jsonTokens = JSONTokens(algorithm: "ES256K", privateKey: transitPrivateKey)
        let decodedTokenJsonString = jsonTokens.decodeToken(token: authResponse)
        var token: Token?
        
        do {
            let jsonDecoder = JSONDecoder()
            token = try jsonDecoder.decode(Token.self, from: decodedTokenJsonString!.data(using: .utf8)!)
        } catch {
            print("error")
        }

        return token
    }
    
    static func handleAuthResponse(authResponse: String, transitPrivateKey: String, completion: ((AuthResult) -> Void)?) {
        let response = Auth.decodeResponse(authResponse, transitPrivateKey: transitPrivateKey)
        
        if var userData = response?.payload {
            
            userData.privateKey = Encryption.decryptPrivateKey(privateKey: transitPrivateKey, hexedEncrypted: userData.privateKey!)
            
            if let profileURL = userData.profileURL {
                ProfileHelper.fetch(profileURL: URL(string: profileURL)!) { (profile, error) in
                    guard error == nil else {
                        ProfileHelper.storeProfile(profileData: userData)
                        completion?(AuthResult.success(userData: userData))
                        return
                    }
                    userData.profile = profile
                    ProfileHelper.storeProfile(profileData: userData)
                    completion?(AuthResult.success(userData: userData))
                }
            } else {
                completion?(AuthResult.failed(AuthError.invalidResponse))
            }
        } else {
            completion?(AuthResult.failed(AuthError.invalidResponse))
        }
    }
}
