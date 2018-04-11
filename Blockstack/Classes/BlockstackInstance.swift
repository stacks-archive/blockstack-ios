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
    static let BrowserWebAppAuthEndpoint = "http://localhost:3000/auth"
    static let AuthProtocolVersion = "1.1.0"
}

open class BlockstackInstance {
    open var coreAPIURL = BlockstackConstants.DefaultCoreAPIURL
    var sfAuthSession : SFAuthenticationSession?
    
    open func signIn(redirectURLScheme: String,
                     manifestURI: URL,
                     scopes: Array<String> = ["store_write"],
                     completion: () -> Void) {
        print("signing in")
        print("using core api url: ", coreAPIURL)
        
        guard let transitKey = Keys.generateTransitKey() else {
            print("Failed to generate transit key")
            return
        }
        
        let appDomain = URL(string: "http://localhost:8080/")!
        let appBundleID = "AppBundleID"
        
//        print("transitKey", transitKey)
//        print("redirectURLScheme", redirectURLScheme)
//        print("manifestURI", manifestURI)
//        print("appDomain", appDomain)
//        print("appBundleID", appBundleID)
        
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
            
            if let queryParams = url!.queryParameters {
                let authResponse: String = queryParams["authResponse"]!
                Auth.handleResponse(authResponse, transitPrivateKey: transitKey)
            }

//            print(url!.queryParameters)
        }
    }

    func startSignIn(redirectURLScheme: String,
                     authRequest: String,
                     completion: @escaping SFAuthenticationSession.CompletionHandler) {
        
        var urlComps = URLComponents(string: BlockstackConstants.BrowserWebAppAuthEndpoint)!
        urlComps.queryItems = [URLQueryItem(name: "authRequest", value: authRequest)]
        let url = urlComps.url!
        
        print(url)
        
        sfAuthSession = SFAuthenticationSession(url: url, callbackURLScheme: redirectURLScheme, completionHandler: completion)
        sfAuthSession?.start()
    }
    
}

