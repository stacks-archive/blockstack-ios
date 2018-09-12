//
//  Blockstack+ObjC.swift
//  Blockstack
//
//  Created by Shreyas Thiagaraj on 9/7/18.
//

import Foundation

extension Blockstack {
    @objc(signInWithRedirectURI:appDomain:manifestURI:scopes:completion:)
    public func objc_signIn(redirectURI: String, appDomain: URL, manifestURI: URL? = nil, scopes: Array<String> = ["store_write"], completion: @escaping (ObjCAuthResult) -> ()) {
        self.signIn(redirectURI: redirectURI, appDomain: appDomain, manifestURI: manifestURI, scopes: scopes) {
            completion(ObjCAuthResult($0))
        }
    }
    
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
    
    @objc(loadUserData)
    public func objc_loadUserData() -> ObjCUserData? {
        if let userData = self.loadUserData() {
            return ObjCUserData(userData)
        } else {
            return nil
        }
    }
}
