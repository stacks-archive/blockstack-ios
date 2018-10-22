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
    public static let GaiaHubConfigUserDefaultLabel = "GAIA_HUB_CONFIG"
    public static let AppOriginUserDefaultLabel = "BLOCKSTACK_APP_ORIGIN"
}

@objc open class Blockstack: NSObject {

    public static let shared = Blockstack()
    
    var sfAuthSession : SFAuthenticationSession?

    // - MARK: Authentication
    
    /**
     Generates an authentication request and redirects the user to the Blockstack browser to approve the sign in request.     
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
                     completion: @escaping (AuthResult) -> ()) {
        print("signing in")
        
        guard let transitKey = Keys.makeECPrivateKey() else {
            print("Failed to generate transit key")
            return
        }
        
        let _manifestURI = manifestURI ?? URL(string: "/manifest.json", relativeTo: appDomain)
        let appBundleID = "AppBundleID"
        
        let authRequest = self.makeAuthRequest(
            transitPrivateKey: transitKey,
            redirectURLScheme: redirectURI,
            manifestURI: _manifestURI!,
            appDomain: appDomain,
            appBundleID: appBundleID,
            scopes: scopes)

        var urlComps = URLComponents(string: BlockstackConstants.BrowserWebAppAuthEndpoint)!
        urlComps.queryItems = [URLQueryItem(name: "authRequest", value: authRequest), URLQueryItem(name: "client", value: "ios_secure")]
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
                completion(AuthResult.failed(error))
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
    
    /**
     Generates an authentication request that can be sent to the Blockstack
     browser for the user to approve sign in. This authentication request can
     then be used for sign in by passing it to the `redirectToSignInWithAuthRequest`
     method.
     
     Note: This method should only be used if you want to roll your own authentication
     flow. Typically you'd use `redirectToSignIn` which takes care of this
     under the hood.*
     
     - parameter transitPrivateKey - hex encoded transit private key
     - parameter redirectURI: Location to redirect user to after sign in approval
     - parameter manifestURI: Location of this app's manifest file
     - parameter scopes: The permissions this app is requesting
     - parameter appDomain: The origin of this app
     - parameter expiresAt: The time at which this request is no longer valid
     - returns: The authentication request
     */
    public func makeAuthRequest(transitPrivateKey: String,
                    redirectURLScheme: String,
                    manifestURI: URL,
                    appDomain: URL,
                    appBundleID: String,
                    scopes: Array<String>,
                    expiresAt: Date = Date().addingTimeInterval(TimeInterval(60.0 * 60.0))) -> String? {
        return Auth.makeRequest(transitPrivateKey: transitPrivateKey,
                                redirectURLScheme: redirectURLScheme,
                                manifestURI: manifestURI,
                                appDomain: appDomain,
                                appBundleID: appBundleID,
                                scopes: scopes, expiresAt: expiresAt)
    }
    
    /**
     Retrieves the user data object. The user's profile is stored in the key `profile`.
     */
    public func loadUserData() -> UserData? {
        return ProfileHelper.retrieveProfile()
    }
    
    /**
     Check if a user is currently signed in.
     */
    @objc public func isUserSignedIn() -> Bool {
        return self.loadUserData() != nil
    }
    
    /**
     Sign the user out.
     */
    @objc public func signUserOut() {
        ProfileHelper.clearProfile()
        Gaia.clearSession()
    }
    
    /**
     Prompt web flow to clear the keychain and all settings for this device.
     WARNING: This will reset the keychain for all apps using Blockstack sign in. Apps that are already signed in will not be affected, but the user will have to reenter their 12 word seed to sign in to any new apps.
     */
    @objc public func promptClearDeviceKeychain() {
        // TODO: Use ASWebAuthenticationSession for iOS 12
        self.sfAuthSession = SFAuthenticationSession(url: URL(string: "\(BlockstackConstants.BrowserWebClearAuthEndpoint)")!, callbackURLScheme: nil) { _, error in
            self.sfAuthSession = nil
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
    public func lookupProfile(username: String, zoneFileLookupURL: URL = URL(string: BlockstackConstants.NameLookupEndpoint)!, completion: @escaping (Profile?, Error?) -> ()) {
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
            ProfileHelper.resolveZoneFileToProfile(zoneFile: nameInfo.zonefile, publicKeyOrAddress: nameInfo.address) {
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
     Fetch the public read URL of a user file for the specified app.
     - parameter path: The path to the file to read
     - parameter username: The Blockstack ID of the user to look up
     - parameter appOrigin: The app origin
     - parameter zoneFileLookupURL: The URL to use for zonefile lookup. Defaults to 'http://localhost:6270/v1/names/'.
     - parameter completion: Callback with public read URL of the file, if one was found.
     */
    @objc public func getUserAppFileURL(at path: String, username: String, appOrigin: String, zoneFileLookupURL: URL = URL(string: "http://localhost:6270/v1/names/")!, completion: @escaping (URL?) -> ()) {
        // TODO: Return errors in completion handler
        Blockstack.shared.lookupProfile(username: username, zoneFileLookupURL: zoneFileLookupURL) { profile, error in
            guard error == nil,
                let profile = profile,
                let bucketUrl = profile.apps?[appOrigin],
                let url = URL(string: bucketUrl) else {
                    completion(nil)
                    return
            }
            completion(url)
        }
    }

    /**
     Stores the data provided in the app's data store to to the file specified.
     - parameter to: The path to store the data in
     - parameter text: The String data to store in the file
     - parameter encrypt: The data with the app private key
     - parameter completion: Callback with the public url and any error
     - parameter publicURL: The publicly accessible url of the file
     - parameter error: Error returned by Gaia
     */
    @objc public func putFile(to path: String, text: String, encrypt: Bool = false, completion: @escaping (_ publicURL: String?, _ error: Error?) -> Void) {
        Gaia.getOrSetLocalHubConnection { session, error in
            guard let session = session, error == nil else {
                print("gaia connection error")
                completion(nil, error)
                return
            }
            session.putFile(to: path, content: text, encrypt: encrypt, completion: completion)
        }
    }
    
    /**
     Stores the data provided in the app's data store to to the file specified.
     - parameter to: The path to store the data in
     - parameter bytes: The Bytes data to store in the file
     - parameter encrypt: The data with the app private key
     - parameter completion: Callback with the public url and any error
     - parameter publicURL: The publicly accessible url of the file
     - parameter error: Error returned by Gaia
     */
    @objc public func putFile(to path: String, bytes: Bytes, encrypt: Bool = false, completion: @escaping (_ publicURL: String?, _ error: Error?) -> Void) {
        Gaia.getOrSetLocalHubConnection { session, error in
            guard let session = session, error == nil else {
                print("gaia connection error")
                completion(nil, error)
                return
            }
            session.putFile(to: path, content: bytes, encrypt: encrypt, completion: completion)
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
    @objc public func getFile(at path: String, decrypt: Bool = false, completion: @escaping (_ content: Any?, _ error: Error?) -> Void) {
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
    @objc public func getFile(at path: String,
                        decrypt: Bool = false,
                        username: String,
                        app: String? = nil,
                        zoneFileLookupURL: URL? = nil,
                        completion: @escaping (_ content: Any?, _ error: Error?) -> Void) {
        
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
    
    /**
     Encrypts the data provided with the app public key.
     - parameter bytes: Bytes (Array<UInt8>) data to encrypt.
     - parameter publicKey: The hex string of the ECDSA public key to use for encryption. If not provided, will use a public key derived from user's appPrivateKey.
     - returns: Stringified JSON ciphertext object
     */
    @objc public func encryptContent(bytes: Bytes, publicKey: String? = nil) -> String? {
        let key: String?
        if publicKey == nil, let privateKey = Blockstack.shared.loadUserData()?.privateKey {
            key = Keys.getPublicKeyFromPrivate(privateKey)
        } else {
            key = publicKey
        }
        guard let recipientKey = key else {
            return nil
        }
        return Encryption.encryptECIES(content: bytes, recipientPublicKey: recipientKey, isString: false)
    }
    
    /**
     Encrypts the data provided with the app public key.
     - parameter text: String data to encrypt
     - parameter publicKey: The hex string of the ECDSA public key to use for encryption. If not provided, will use a public key derived from user's appPrivateKey.
     - returns: Stringified JSON ciphertext object
     */
    @objc public func encryptContent(text: String, publicKey: String? = nil) -> String? {
        let key: String?
        if publicKey == nil, let privateKey = Blockstack.shared.loadUserData()?.privateKey {
            key = Keys.getPublicKeyFromPrivate(privateKey)
        } else {
            key = publicKey
        }
        guard let recipientKey = key else {
            return nil
        }
        return Encryption.encryptECIES(content: text, recipientPublicKey: recipientKey)
    }
    
    /**
     Decrypts data encrypted with `encryptContent` with the transit private key.
     - parameter content: Encrypted, JSON stringified content.
     - parameter privateKey: The hex string of the ECDSA private key to use for decryption. If not provided, will use user's appPrivateKey.
     - returns: DecryptedValue object containing Byte or String content.
     */
    public func decryptContent(content: String, privateKey: String? = nil) -> DecryptedValue? {
        guard let key = privateKey ?? Blockstack.shared.loadUserData()?.privateKey else {
            return nil
        }
        return Encryption.decryptECIES(cipherObjectJSONString: content, privateKey: key)
    }
}
