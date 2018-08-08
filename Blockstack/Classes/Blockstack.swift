//
//  Blockstack.swift
//  Blockstack
//
//  Created by Yukan Liao on 2018-03-09.
//

import Foundation
import SafariServices
import JavaScriptCore

public typealias Bytes = Array<UInt8>

public enum BlockstackConstants {
    static let DefaultCoreAPIURL = "https://core.blockstack.org"
    static let BrowserWebAppURL = "https://browser.blockstack.org"
    static let BrowserWebAppAuthEndpoint = "https://browser.blockstack.org/auth"
    static let BrowserWebClearAuthEndpoint = "https://browser.blockstack.org/clear-auth"
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
        
        let authRequest = Auth.makeRequest(transitPrivateKey: transitKey,
                                           redirectURLScheme: redirectURI,
                                           manifestURI: _manifestURI!,
                                           appDomain: appDomain,
                                           appBundleID: appBundleID)
        
        var urlComps = URLComponents(string: BlockstackConstants.BrowserWebAppAuthEndpoint)!
        urlComps.queryItems = [URLQueryItem(name: "authRequest", value: authRequest)]
        let url = urlComps.url!
        
        // TODO: Use ASWebAuthenticationSession for iOS 12
        var responded = false
        self.sfAuthSession = SFAuthenticationSession(url: url, callbackURLScheme: redirectURI) { (url, error) in
            guard !responded else {
                return
            }
            responded = true
            
            self.sfAuthSession = nil
            guard error == nil, let queryParams = url?.queryParameters, let authResponse = queryParams["authResponse"] else {
                completion?(AuthResult.failed(error))
                return
            }
            Auth.handleAuthResponse(authResponse: authResponse,
                                    transitPrivateKey: transitKey,
                                    completion: completion)
        }
        self.sfAuthSession?.start()
    }
    
    public func loadUserData() -> UserData? {
        return ProfileHelper.retrieveProfile()
    }
    
    public func isSignedIn() -> Bool {
        return (loadUserData() != nil)
    }
    
    /// The redirectURI should be a custom scheme registered in the app Info.plist, i.e. "myBlockstackApp"
    public func signOut(redirectURI: String, completion: @escaping (Error?) -> ()) {
        Keys.clearTransitKey()
        ProfileHelper.clearProfile()
        
        // TODO: Use ASWebAuthenticationSession for iOS 12
        self.sfAuthSession = SFAuthenticationSession(url: URL(string: "\(BlockstackConstants.BrowserWebClearAuthEndpoint)?redirect_uri=\(redirectURI)")!, callbackURLScheme: nil) { _, error in
            self.sfAuthSession = nil
            completion(error)
        }
        self.sfAuthSession?.start()
    }
    
    public func putFile(to path: String, content: String, encrypt: Bool = false, completion: @escaping (String?, GaiaError?) -> Void) {
        Gaia.ensureHubSession { session, error in
            guard let session = session, error == nil else {
                print("gaia connection error")
                completion(nil, error)
                return
            }
            session.putFile(to: path, content: content, encrypt: encrypt, completion: completion)
        }
    }
    
    public func putFile(to path: String, content: Bytes, encrypt: Bool = false, completion: @escaping (String?, GaiaError?) -> Void) {
        Gaia.ensureHubSession { session, error in
            guard let session = session, error == nil else {
                print("gaia connection error")
                completion(nil, error)
                return
            }
            session.putFile(to: path, content: content, encrypt: encrypt, completion: completion)
        }
    }
    
    public func getFile(at path: String, decrypt: Bool = false, completion: @escaping (Any?, GaiaError?) -> Void) {
        Gaia.ensureHubSession { session, error in
            guard let session = session, error == nil else {
                print("gaia connection error")
                completion(nil, error)
                return
            }
            session.getFile(at: path, decrypt: decrypt, completion: completion)
        }
    }
}
