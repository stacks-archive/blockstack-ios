//
//  Blockstack.swift
//  Blockstack
//
//  Created by Yukan Liao on 2018-03-09.
//

import Foundation
import SafariServices
import JavaScriptCore
import secp256k1

public enum BlockstackConstants {
    static let DefaultCoreAPIURL = "https://core.blockstack.org"
    static let BrowserWebAppURL = "https://browser.blockstack.org"
    static let BrowserWebAppAuthEndpoint = "https://browser.blockstack.org/auth"
    static let AuthProtocolVersion = "1.1.0"
    static let DefaultGaiaHubURL = "https://hub.blockstack.org"
    static let ProfileUserDefaultLabel = "BLOCKSTACK_PROFILE_LABEL"
    static let TransitPrivateKeyUserDefaultLabel = "BLOCKSTACK_TRANSIT_PRIVATE_KEY"
    static let GaiaHubConfigUserDefaultLabel = "GAIA_HUB_CONFIG"
}

open class Blockstack {
    
    public static let shared = Blockstack()
    
    var sfAuthSession : SFAuthenticationSession?
    
    open func signIn(redirectURI: String,
                     appDomain: URL,
                     manifestURI: URL? = nil,
                     scopes: Array<String> = ["store_write"],
                     completion: ((AuthResult) -> Void)?) {
        print("signing in")
        
        guard let transitKey = Keys.generateTransitKey() else {
            print("Failed to generate transit key")
            return
        }
        
        let _manifestURI = manifestURI ?? URL(string: "/manifest.json", relativeTo: appDomain)
        let appBundleID = "AppBundleID"
        
        //        print("transitKey", transitKey)
        //        print("redirectURLScheme", redirectURI)
        //        print("manifestURI", _manifestURI!.absoluteString)
        //        print("appDomain", appDomain)
        //        print("appBundleID", appBundleID)
        
        let authRequest: String = Auth.makeRequest(transitPrivateKey: transitKey,
                                                   redirectURLScheme: redirectURI,
                                                   manifestURI: _manifestURI!,
                                                   appDomain: appDomain,
                                                   appBundleID: appBundleID)
        
        startSignIn(redirectURLScheme: redirectURI, authRequest: authRequest) { (url, error) in
            guard error == nil else {
                completion?(AuthResult.failed(error))
                return
            }
            
            if let queryParams = url!.queryParameters {
                let authResponse: String = queryParams["authResponse"]!
                Auth.handleAuthResponse(authResponse: authResponse,
                                        transitPrivateKey: transitKey,
                                        completion: completion)
            }
        }
    }
    
    private func startSignIn(redirectURLScheme: String,
                     authRequest: String,
                     completion: @escaping SFAuthenticationSession.CompletionHandler) {
        
        var urlComps = URLComponents(string: BlockstackConstants.BrowserWebAppAuthEndpoint)!
        urlComps.queryItems = [URLQueryItem(name: "authRequest", value: authRequest)]
        let url = urlComps.url!
        
        var responded = false
        
        sfAuthSession = SFAuthenticationSession(url: url, callbackURLScheme: redirectURLScheme) { (url, error) in
            guard responded == false else {
                return
            }
            
            responded = true
            completion(url, error)
        }
        sfAuthSession?.start()
    }
    
    public func loadUserData() -> UserData? {
        return ProfileHelper.retrieveProfile()
    }
    
    public func isSignedIn() -> Bool {
        return (loadUserData() != nil)
    }
    
    public func signOut() {
        Keys.clearTransitKey()
        ProfileHelper.clearProfile()
    }
    
    public func putFile(path: String, content: Dictionary<String, String>, completion: @escaping (String?, GaiaError?) -> Void) {
        Gaia.ensureHubSession { session, error in
            guard let session = session, error == nil else {
                print("gaia connection error")
                completion(nil, error)
                return
            }
            session.putFile(path: path, content: content, completion: completion)
        }
    }
    
    public func getFile(path: String, completion: @escaping (Any?, GaiaError?) -> Void) {
        Gaia.ensureHubSession { session, error in
            guard let session = session, error == nil else {
                print("gaia connection error")
                completion(nil, error)
                return
            }
            session.getFile(path: path, completion: completion)
        }
    }
}



