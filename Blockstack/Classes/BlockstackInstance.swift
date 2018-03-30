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

struct BlockstackConstants {
    static let DefaultCoreAPIURL = "https://core.blockstack.org"
    static let BrowserWebAppURL = "https://browser.blockstack.org"
    static let BrowserWebAppAuthEndpoint = "https://browser.blockstack.org/auth"
    static let AuthProtocolVersion = "1.1.0"
}

open class BlockstackInstance {
    open var coreAPIURL = BlockstackConstants.DefaultCoreAPIURL
    var sfAuthSession : SFAuthenticationSession?
    
    open func signIn(redirectURLScheme: String, manifestURI: URL, scopes: Array<String> = ["store_write"]) {
        print("signing in")
        print("using core api url: ", coreAPIURL)
        
        guard let transitKey = Keys.generateTransitKey() else {
            print("Failed to generate transit key")
            return
        }
        
        let appDomain = URL(string: "https://blockstack-todos.appartisan.com/")!
        let appBundleID = "AppBundleID"
        
//        print(transitKey)
//        print(redirectURLScheme)
//        print(manifestURI)
//        print(appDomain)
//        print(appBundleID)
        
        let authRequest: String = Auth.makeRequest(transitPrivateKey: transitKey,
                                                   redirectURLScheme: redirectURLScheme,
                                                   manifestURI: manifestURI,
                                                   appDomain: appDomain,
                                                   appBundleID: appBundleID)
        
        startSignIn(redirectURLScheme: redirectURLScheme, authRequest: authRequest) { (url, error) in
            print("in sfauthsession call back")
            guard error == nil else {
                print("error")
                return
            }
            
            print(url!)
        }
    }

    func startSignIn(redirectURLScheme: String,
                     authRequest: String,
                     completion: @escaping SFAuthenticationSession.CompletionHandler) {
        
        var urlComps = URLComponents(string: BlockstackConstants.BrowserWebAppAuthEndpoint)!
        urlComps.queryItems = [URLQueryItem(name: "authRequest", value: authRequest)]
        let url = urlComps.url!
        
        print(url)
        
//        sfAuthSession = SFAuthenticationSession(url: url, callbackURLScheme: redirectURLScheme, completionHandler: completion)
        sfAuthSession = SFAuthenticationSession(url: url, callbackURLScheme: nil, completionHandler: { (url, error) in
            print("in sfauthsession call back")
            guard error == nil else {
                print("error")
                return
            }
            print(url!)
        })
        sfAuthSession?.start()
    }
    
}

