//
//  Blockstack+ObjC.swift
//  Blockstack
//
//  Created by Shreyas Thiagaraj on 9/7/18.
//

import Foundation

extension Blockstack {
    /**
     Decrypts data encrypted with `encryptContent` with the given private key.
     - parameter privateKey: The hex string of the ECDSA private key to use for decryption. If not provided, will use user's appPrivateKey.
     - returns: DecryptedValue object containing Byte or String content.
     */
    @objc(decryptContent:privateKey:)
    public func objc_decryptContent(content: String, privateKey: String? = nil) -> ObjCDecryptedValue? {
        guard let decryptedValue = self.decryptContent(content: content, privateKey: privateKey) else {
            return nil
        }
        return ObjCDecryptedValue(decryptedValue)
    }
    
    /**
     Retrieves the user data object. The user's profile is stored in the key `profile`.
     */
    @objc(loadUserData)
    public func objc_loadUserData() -> ObjCUserData? {
        if let userData = self.loadUserData() {
            return ObjCUserData(userData)
        } else {
            return nil
        }
    }
    
    /**
     Look up a user profile by Blockstack ID.
     - parameter zoneFileLookupURL: The URL to use for zonefile lookup
     - parameter completion: Callback containing a Profile object, if one was found.
     */
    @objc(lookupProfileForUsername:zoneFileLookupURL:completion:)
    public func objc_lookupProfile(username: String, zoneFileLookupURL: URL = URL(string: BlockstackConstants.NameLookupEndpoint)!, completion: @escaping (ObjCProfile?, Error?) -> ()) {
        self.lookupProfile(username: username, zoneFileLookupURL: zoneFileLookupURL) {
            if let profile = $0 {
                completion(ObjCProfile(profile), nil)
            } else {
                completion(nil, $1)
            }
        }
    }
    
    /**
     Generates an authentication request and redirects the user to the Blockstack browser to approve the sign in request. redirectURI is the location to which the identity provider will redirect the user after the user approves sign in.
     - parameter appDomain: The app origin.
     - parameter manifestURI: Location of the manifest file; defaults to '[appDomain]/manifest.json'.
     - parameter scopes: An array of strings indicating which permissions this app is requesting; defaults to requesting write access to this app's data store ("store_write")/
     - parameter completion: Callback with an AuthResult object.
     */
    @objc(signInWithRedirectURI:appDomain:manifestURI:scopes:completion:)
    public func objc_signIn(redirectURI: URL, appDomain: URL, manifestURI: URL? = nil, scopes: Array<String> = ["store_write"], completion: @escaping (ObjCAuthResult) -> ()) {
        let enumScopes = scopes.compactMap { AuthScope.fromString($0) }
        self.signIn(redirectURI: redirectURI, appDomain: appDomain, manifestURI: manifestURI, scopes: enumScopes) {
            completion(ObjCAuthResult($0))
        }
    }
}
