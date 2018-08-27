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
    public static let DefaultCoreAPIURL = "https://core.blockstack.org"
    public static let BrowserWebAppURL = "https://browser.blockstack.org"
    public static let BrowserWebAppAuthEndpoint = "https://browser.blockstack.org/auth"
    public static let BrowserWebClearAuthEndpoint = "https://browser.blockstack.org/clear-auth"
    public static let NameLookupEndpoint = "https://core.blockstack.org/v1/names/"
    public static let AuthProtocolVersion = "1.1.0"
    public static let DefaultGaiaHubURL = "https://hub.blockstack.org"
    public static let ProfileUserDefaultLabel = "BLOCKSTACK_PROFILE_LABEL"
    public static let TransitPrivateKeyUserDefaultLabel = "BLOCKSTACK_TRANSIT_PRIVATE_KEY"
    public static let GaiaHubConfigUserDefaultLabel = "GAIA_HUB_CONFIG"
    public static let AppOriginUserDefaultLabel = "BLOCKSTACK_APP_ORIGIN"
}

open class Blockstack {

    public static let shared = Blockstack()
    
    var sfAuthSession : SFAuthenticationSession?

    // - MARK: Authentication
    
    /**
     Generates an authentication request and redirects the user to the Blockstack
     browser to approve the sign in request.
     
     - parameter redirectURI: The location to which the identity provider will redirect the user after the user approves sign in.
     - parameter appDomain: The app origin.
     - parameter manifestURI: Location of the manifest file; defaults to '[appDomain]/manifest.json'.
     - parameter scopes: An array of strings indicating which permissions this app is requesting; defaults to requesting write access to this app's data store ("store_write")/
     - parameter completion: Callback with an AuthResult object.
     */
    public func signIn(redirectURI: String,
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
        
        let authRequest = Auth.makeRequest(transitPrivateKey: transitKey,
                                           redirectURLScheme: redirectURI,
                                           manifestURI: _manifestURI!,
                                           appDomain: appDomain,
                                           appBundleID: appBundleID,
                                           scopes: scopes)
        
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
            
            // Cache app origin
            UserDefaults.standard.setValue(appDomain.absoluteString, forKey: BlockstackConstants.AppOriginUserDefaultLabel)
            
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
        return self.loadUserData() != nil
    }
    
    public func signOut() {
        Keys.clearTransitKey()
        ProfileHelper.clearProfile()
        Gaia.clearSession()
    }
    
    /**
     Clear the keychain and all settings for this device.
     WARNING: This will reset the keychain for all apps using Blockstack sign in. Apps that are already signed in will not be affected, but the user will have to reenter their 12 word seed to sign in to any new apps.
     - parameter redirectURI: A custom scheme registered in the app Info.plist, i.e. "myBlockstackApp"
     - parameter completion: Callback indicating success or failure.
     */
    public func promptClearDeviceKeychain(redirectUri: String, completion: @escaping (Error?) -> ()) {
        // TODO: Use ASWebAuthenticationSession for iOS 12
        self.sfAuthSession = SFAuthenticationSession(url: URL(string: "\(BlockstackConstants.BrowserWebClearAuthEndpoint)?redirect_uri=\(redirectUri)")!, callbackURLScheme: nil) { _, error in
            self.sfAuthSession = nil
            completion(error)
        }
        self.sfAuthSession?.start()
    }
    
    // - MARK: Profiles

    /**
     Look up a user profile by Blockstack ID.
     - parameter username: The Blockstack ID of the profile to look up
     - parameter zoneFileLookupURL: The URL to use for zonefile lookup
     - parameter completion: Callback containing a Profile object, if one was found.
     */
    public func lookupProfile(username: String, zoneFileLookupURL: URL = URL(string: BlockstackConstants.NameLookupEndpoint)!, completion: @escaping (Profile?, GaiaError?) -> ()) {
        let task = URLSession.shared.dataTask(with: zoneFileLookupURL.appendingPathComponent(username)) {
            data, response, error in
            guard let data = data, error == nil else {
                completion(nil, GaiaError.requestError)
                return
            }
            guard let nameInfo = try? JSONDecoder().decode(NameInfo.self, from: data) else {
                completion(nil, GaiaError.invalidResponse)
                return
            }
            self.resolveZoneFileToProfile(zoneFile: nameInfo.zonefile, publicKeyOrAddress: nameInfo.address) {
                profile in
                // TODO: Return proper errors from resolveZoneFileToProfile
                guard let profile = profile else {
                    completion(nil, GaiaError.invalidResponse)
                    return
                }
                completion(profile, nil)
            }
        }
        task.resume()
    }
    
    // - MARK: Storage
    
    /**
     Stores the data provided in the app's data store to to the file specified.
     - parameter to: The path to store the data in
     - parameter content: The String data to store in the file
     - parameter encrypt: The data with the app private key
     - parameter completion: Callback with the public url and any error
     - parameter publicURL: The publicly accessible url of the file
     - parameter error: Error returned by Gaia
     */
    public func putFile(to path: String, content: String, encrypt: Bool = false, completion: @escaping (_ publicURL: String?, _ error: GaiaError?) -> Void) {
        Gaia.getOrSetLocalHubConnection { session, error in
            guard let session = session, error == nil else {
                print("gaia connection error")
                completion(nil, error)
                return
            }
            session.putFile(to: path, content: content, encrypt: encrypt, completion: completion)
        }
    }
    
    /**
     Stores the data provided in the app's data store to to the file specified.
     - parameter to: The path to store the data in
     - parameter content: The Bytes data to store in the file
     - parameter encrypt: The data with the app private key
     - parameter completion: Callback with the public url and any error
     - parameter publicURL: The publicly accessible url of the file
     - parameter error: Error returned by Gaia
     */
    public func putFile(to path: String, content: Bytes, encrypt: Bool = false, completion: @escaping (_ publicURL: String?, _ error: GaiaError?) -> Void) {
        Gaia.getOrSetLocalHubConnection { session, error in
            guard let session = session, error == nil else {
                print("gaia connection error")
                completion(nil, error)
                return
            }
            session.putFile(to: path, content: content, encrypt: encrypt, completion: completion)
        }
    }
    
    /**
     Retrieves the specified file from the app's data store.
     - parameter path: The path to the file to read
     - parameter decrypt: Try to decrypt the data with the app private key
     - parameter completion: Callback with retrieved content and any error
     - parameter content: The retrieved content as either Bytes, String, or DecryptedContent
     - parameter error: Error returned by Gaia
     */
    public func getFile(at path: String, decrypt: Bool = false, completion: @escaping (_ content: Any?, _ error: GaiaError?) -> Void) {
        Gaia.getOrSetLocalHubConnection { session, error in
            guard let session = session, error == nil else {
                print("gaia connection error")
                completion(nil, error)
                return
            }
            session.getFile(at: path, decrypt: decrypt, completion: completion)
        }
    }
    
    /**
     Retrieves the specified file from the app's data store.
     - parameter path: The path to the file to read
     - parameter decrypt: Try to decrypt the data with the app private key
     - parameter username: The Blockstack ID to lookup for multi-player storage
     - parameter app: The app to lookup for multi-player storage. Defaults to current origin.
     - parameter zoneFileLookupURL: The Blockstack core endpoint URL to use for zonefile lookup, defaults to "https://core.blockstack.org/v1/names/"
     - parameter completion: Callback with retrieved content and any error
     - parameter content: The retrieved content as either Bytes, String, or DecryptedContent
     - parameter error: Error returned by Gaia
     */
    public func getFile(at path: String,
                        decrypt: Bool = false,
                        username: String,
                        app: String? = nil,
                        zoneFileLookupURL: URL? = nil,
                        completion: @escaping (_ content: Any?, _ error: GaiaError?) -> Void) {
        
        guard let appOrigin = app ?? UserDefaults.standard.string(forKey: BlockstackConstants.AppOriginUserDefaultLabel) else {
            completion(nil, GaiaError.configurationError)
            return
        }
        
        let zoneFileLookupURL = zoneFileLookupURL ?? URL(string: BlockstackConstants.NameLookupEndpoint)!
        Gaia.getOrSetLocalHubConnection { session, error in
            guard let session = session, error == nil else {
                print("gaia connection error")
                completion(nil, error)
                return
            }
            session.getFile(
                at: path,
                decrypt: decrypt,
                multiplayerOptions: MultiplayerOptions(
                    username: username,
                    app: appOrigin,
                    zoneFileLookupURL: zoneFileLookupURL),
                completion: completion)
        }
    }

    // MARK: - Private
    
    // TODO: Return errors in completion handler
    private func resolveZoneFileToProfile(zoneFile: String, publicKeyOrAddress: String, completion: @escaping (Profile?) -> ()) {
        // TODO: Support legacy zone files
        guard let zoneFile = BlockstackJS().parseZoneFile(zoneFile: zoneFile),
            var tokenFileUrl = zoneFile.uri.first?["target"] as? String else {
                completion(nil)
                return
        }
        
        // Fix url
        if !tokenFileUrl.starts(with: "http") {
            tokenFileUrl = "https://\(tokenFileUrl)"
        }
        
        guard let url = URL(string: tokenFileUrl) else {
            completion(nil)
            return
        }
        
        ProfileHelper.fetch(profileURL: url) { profile, error in
            guard let profile = profile, error == nil else {
                completion(nil)
                return
            }
            completion(profile)
        }
    }
}
