//
//  BlockstackInstance.swift
//  Blockstack
//
//  Created by Yukan Liao on 2018-03-16.
//

import Foundation
import SafariServices
import JavaScriptCore
import secp256k1

public enum BlockstackConstants {
    static let DefaultCoreAPIURL = "https://core.blockstack.org"
    static let BrowserWebAppURL = "https://browser.blockstack.org"
    static let BrowserWebAppAuthEndpoint = "http://browser.blockstack.org/auth"
    static let AuthProtocolVersion = "1.1.0"
    static let ProfileUserDefaultLabel = "BLOCKSTACK_PROFILE_LABEL"
    static let TransitPrivateKeyUserDefaultLabel = "BLOCKSTACK_TRANSIT_PRIVATE_KEY"
}

open class BlockstackInstance {
    open var coreAPIURL = BlockstackConstants.DefaultCoreAPIURL
    var sfAuthSession : SFAuthenticationSession?
    
    open func signIn(redirectURI: String,
                     appDomain: URL,
                     manifestURI: URL? = nil,
                     scopes: Array<String> = ["store_write"],
                     completion: ((AuthResult) -> Void)?) {
        print("signing in")
        print("using core api url: ", coreAPIURL)
        
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
                let response = Auth.decodeResponse(authResponse, transitPrivateKey: transitKey)
                
                if var userData = response?.payload {
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
    }

    func startSignIn(redirectURLScheme: String,
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
        if (loadUserData() != nil) {
            return true
        } else {
            return false
        }
    }
    
    public func signOut() {
        Keys.clearTransitKey()
        ProfileHelper.clearProfile()
    }
}

