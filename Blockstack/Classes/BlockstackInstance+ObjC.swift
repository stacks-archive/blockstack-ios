//
//  BlockstackInstance+ObjC.swift
//  Blockstack
//
//  Created by Michal Ciurus on 09/05/2018.
//

import Foundation

@objc public class ProfileObject: NSObject {
    
    public let type: String?
    public let context: String?
    public let name: String?
    public let profileDescription: String?
    
    public init(profile: Profile) {
        type = profile.type
        context = profile.context
        name = profile.name
        profileDescription = profile.description
    }
    
}

@objc public class UserDataObject: NSObject {
    
    public let jti: String?
    public let iat, exp: Int?
    public let iss: String?
    public var privateKey: String?
    public let publicKeys: [String]?
    public let username, email, coreToken, profileURL, hubURL, version: String?
    public let claim: ProfileObject?
    public var profile: ProfileObject?
    
    public init(userData: UserData) {
        jti = userData.jti
        iat = userData.iat
        exp = userData.exp
        iss = userData.iss
        privateKey = userData.privateKey
        publicKeys = userData.publicKeys
        username = userData.username
        email = userData.email
        coreToken = userData.coreToken
        profileURL = userData.profileURL
        hubURL = userData.hubURL
        version = userData.version
        
        if let claimStruct = userData.claim {
            claim = ProfileObject(profile: claimStruct)
        } else {
            claim = nil
        }
        
        if let profileStruct = userData.profile {
            profile = ProfileObject(profile: profileStruct)
        } else {
            profile = nil
        }
    }
    
}

public extension BlockstackInstance {
    
    @objc func signIn(redirectURI: String,
                      appDomain: URL,
                      manifestURI: URL? = nil,
                      scopes: Array<String>,
                      completion: ((UserDataObject?, Error?, Bool) -> Void)?) {
        
        let translatedCompletion: (AuthResult) -> Void = { authResult in
            switch authResult {
            case .success(let userData): completion?(UserDataObject(userData: userData), nil, false)
            case .failed(let error): completion?(nil, error, false)
            case .cancelled: completion?(nil, nil, true)
            }
        }
        signIn(redirectURI: redirectURI, appDomain: appDomain, manifestURI: manifestURI, scopes: scopes, completion: translatedCompletion)
    }
    
    @objc func signIn(redirectURI: String,
                      appDomain: URL,
                      manifestURI: URL? = nil,
                      completion: ((UserDataObject?, Error?, Bool) -> Void)?) {
        signIn(redirectURI: redirectURI, appDomain: appDomain, manifestURI: manifestURI, scopes: ["store_write"], completion: completion)
    }
    
    @objc public func putFile(path: String, content: Dictionary<String, String>, completion: @escaping (String?, Error?) -> Void) {
        let translatedCompletion: (String?, GaiaError?) -> Void = { string, error in
            completion(string, error)
        }
        putFile(path: path, content: content, completion: translatedCompletion)
    }
    
    @objc public func getFile(path: String, completion: @escaping (Any?, Error?) -> Void) {
        let translatedCompletion: (Any?, GaiaError?) -> Void = { value, error in
            completion(value, error)
        }
        getFile(path: path, completion: translatedCompletion)
    }
    
    @objc public func loadUserDataObject() -> UserDataObject? {
        if let userData = ProfileHelper.retrieveProfile() {
            return UserDataObject(userData: userData)
        } else {
            return nil
        }
    }

    @objc public func decryptPrivateKey(privateKey: String,
                                        hexedEncrypted: String,
                                        completion: @escaping (String?, Error?) -> Void) {
        let decryptedString = Encryption.decryptPrivateKey(privateKey: privateKey, hexedEncrypted: hexedEncrypted)
        completion(decryptedString, nil)
    }

    @objc public func encryptPrivateKey(publicKey: String,
                                        privateKey: String,
                                        completion: @escaping (String?, Error?) -> Void) {
        let encryptedCipherText = Encryption.encryptPrivateKey(publicKey: publicKey, privateKey: privateKey)
        completion(encryptedCipherText, nil)
    }
}
