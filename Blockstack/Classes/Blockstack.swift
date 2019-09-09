//
//  Blockstack.swift
//  Blockstack
//
//  Created by Yukan Liao on 2018-03-09.
//

import Foundation
import AuthenticationServices
import SafariServices
import JavaScriptCore
import Promises

public typealias Bytes = Array<UInt8>

fileprivate var betaBrowserDefaultsKey = "isBetaBrowserEnabled"

public enum BlockstackConstants {
    public static var BrowserWebAppURL: String {
        return UserDefaults.standard.bool(forKey: betaBrowserDefaultsKey) ?
            "https://beta.browser.blockstack.org" :
        "https://browser.blockstack.org"
    }

    public static let DefaultCoreAPIURL = "https://core.blockstack.org"
    public static let BrowserWebAppAuthEndpoint = "\(BrowserWebAppURL)/auth"
    public static let BrowserWebClearAuthEndpoint = "\(BrowserWebAppURL)/clear-auth"
    public static let NameLookupEndpoint = "https://core.blockstack.org/v1/names/"
    public static let AuthProtocolVersion = "1.1.0"
    public static let DefaultGaiaHubURL = "https://hub.blockstack.org"
    public static let ProfileUserDefaultLabel = "BLOCKSTACK_PROFILE_LABEL"
    public static let GaiaHubConfigUserDefaultLabel = "GAIA_HUB_CONFIG"
    public static let AppOriginUserDefaultLabel = "BLOCKSTACK_APP_ORIGIN"
}

/**
 A class that contains the native swift implementations of Blockstack.js methods and Blockstack network operations.
 */
@objc open class Blockstack: NSObject {

    /**
     A shared instance of Blockstack that exists for the lifetime of your app. Use this instance instead of creating your own.
     */
    @objc public static let shared = Blockstack()
    
    /**
     Use the latest, beta version of the Blockstack browser (https://beta.browser.blockstack.org) for authentication.
    */
    @objc public var isBetaBrowserEnabled = false {
        didSet {
            UserDefaults.standard.set(self.isBetaBrowserEnabled, forKey: betaBrowserDefaultsKey)
        }
    }
    
    // - MARK: Authentication
    
    /**
     Generates an authentication request and redirects the user to the Blockstack browser to approve the sign in request.     
     - parameter redirectURI: The location to which the identity provider will redirect the user after the user approves sign in.
     - parameter appDomain: The app origin.
     - parameter manifestURI: Location of the manifest file; defaults to '[appDomain]/manifest.json'.
     - parameter scopes: An array of strings indicating which permissions this app is requesting; defaults to requesting write access to this app's data store ("store_write")/
     - parameter completion: Callback with an AuthResult object.
     */
    public func signIn(redirectURI: URL,
                       appDomain: URL,
                       manifestURI: URL? = nil,
                       scopes: [AuthScope] = [.storeWrite],
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
            redirectURI: redirectURI,
            manifestURI: _manifestURI!,
            appDomain: appDomain,
            appBundleID: appBundleID,
            scopes: scopes)

        var urlComps = URLComponents(string: BlockstackConstants.BrowserWebAppAuthEndpoint)!
        urlComps.queryItems = [URLQueryItem(name: "authRequest", value: authRequest), URLQueryItem(name: "client", value: "ios_secure")]
        let url = urlComps.url!

        var didRespond = false
        let completion: (URL?, Error?) -> () = { url, error in
            guard !didRespond else {
                return
            }
            didRespond = true

            // Discard auth session
            self.asWebAuthSession = nil
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
        
        if #available(iOS 12.0, *) {
            let authSession = ASWebAuthenticationSession(url: url, callbackURLScheme: redirectURI.absoluteString, completionHandler: completion)
            authSession.start()
            self.asWebAuthSession = authSession
        } else {
            // Fallback on earlier versions
            self.sfAuthSession = SFAuthenticationSession(url: url, callbackURLScheme: redirectURI.absoluteString, completionHandler: completion)
            self.sfAuthSession?.start()
        }
    }
    
    /**
     Generates an authentication request that can be sent to the Blockstack
     browser for the user to approve sign in. This authentication request can
     then be used for sign in by passing it to the `redirectToSignInWithAuthRequest`
     method.
     
     Note: This method should only be used if you want to roll your own authentication
     flow. Typically you'd use `redirectToSignIn` which takes care of this
     under the hood.*
     
     - parameter transitPrivateKey: hex encoded transit private key
     - parameter redirectURI: Location to redirect user to after sign in approval
     - parameter manifestURI: Location of this app's manifest file
     - parameter scopes: The permissions this app is requesting
     - parameter appDomain: The origin of this app
     - parameter expiresAt: The time at which this request is no longer valid
     - returns: The authentication request
     */
    public func makeAuthRequest(transitPrivateKey: String,
                    redirectURI: URL,
                    manifestURI: URL,
                    appDomain: URL,
                    appBundleID: String,
                    scopes: [AuthScope],
                    expiresAt: Date = Date().addingTimeInterval(TimeInterval(60.0 * 60.0))) -> String? {
        return Auth.makeRequest(transitPrivateKey: transitPrivateKey,
                                redirectURI: redirectURI,
                                manifestURI: manifestURI,
                                appDomain: appDomain,
                                appBundleID: appBundleID,
                                scopes: scopes, expiresAt: expiresAt)
    }
    
    /**
     Generates a ECDSA keypair and stores the hex value of the private key in local storage.
     - returns: The hex encoded private key, or nil if key generation failed.
     */
    public func generateTransitKey() -> String? {
        return Keys.makeECPrivateKey()
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
     Clear Gaia session.
    */
    @objc public func clearGaiaSession() {
        Gaia.clearSession()
    }
    
    /**
     Prompt web flow to clear the keychain and all settings for this device.
     WARNING: This will reset the keychain for all apps using Blockstack sign in. Apps that are already signed in will not be affected, but the user will have to reenter their 12 word seed to sign in to any new apps.
     */
    @objc public func promptClearDeviceKeychain() {
        let url = URL(string: "\(BlockstackConstants.BrowserWebClearAuthEndpoint)")!
        if #available(iOS 12.0, *) {
            let authSession = ASWebAuthenticationSession(url: url, callbackURLScheme: nil) { _, _ in
                self.asWebAuthSession = nil
            }
            authSession.start()
            self.asWebAuthSession = authSession
        } else {
            self.sfAuthSession = SFAuthenticationSession(url: url, callbackURLScheme: nil) { _, _ in
                self.sfAuthSession = nil
            }
            self.sfAuthSession?.start()
        }
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
    
    /**
     Extracts a profile from an encoded token and optionally verifies it, if `publicKeyOrAddress` is provided.
     - parameter token: The token to be extracted
     - parameter publicKeyOrAddress: The public key or address of the keypair that is thought to have signed the token
     - returns: The profile extracted from the encoded token
     - throws: If the token isn't signed by the provided `publicKeyOrAddress`
     */
    public func extractProfile(token: String, publicKeyOrAddress: String? = nil) throws -> Profile? {
        let decodedToken: ProfileToken?
        if let key = publicKeyOrAddress {
            do {
                decodedToken = try self.verifyProfileToken(token: token, publicKeyOrAddress: key)
            } catch let error {
                throw error
            }
        } else {
            guard let jsonString = JSONTokensJS().decodeToken(token: token),
                let data = jsonString.data(using: .utf8) else {
                    return nil
            }
            decodedToken = try? JSONDecoder().decode(ProfileToken.self, from: data)
        }
        return decodedToken?.payload?.claim
    }
    
    /**
     Wraps a token for a profile token file
     - parameter token: the token to be wrapped
     - returns: WrappedToken object containing `token` and `decodedToken`
     */
    public func wrapProfileToken(token: String) -> ProfileTokenFile? {
        guard let jsonString = JSONTokensJS().decodeToken(token: token),
            let data = jsonString.data(using: .utf8) else {
                return nil
        }
        
        guard let decoded = try? JSONDecoder().decode(ProfileToken.self, from: data) else {
            return nil
        }
        return ProfileTokenFile(token: token, decodedToken: decoded)
    }
    
    /**
     Signs a profile token. Issued by default today, and expires by default in 1 year (31557600 seconds).
     - parameter profile: The profile to be signed
     - parameter privateKey: The signing private key
     - parameter subject: The entity that the information is about, defaults to ["publicKey": the associated publicKey of the signing privateKey].
     - parameter issuer: The entity that is issuing the token, defaults to ["publicKey": the associated publicKey of the signing privateKey].
     - parameter issuedAt: The time of issuance of the token
     - parameter expiresAt: The time of expiration of the token
     - returns: The signed profile token
     */
    public func signProfileToken(
        profile: Profile,
        privateKey: String,
        subject: [String: String]? = nil,
        issuer: [String: String]? = nil,
        issuedAt: Date = Date(),
        expiresAt: Date = Date().addingTimeInterval(31557600)
        ) -> String? {
        // Other algorithms are not yet supported.
        let signingAlgorithm = "ES256K"

        guard let publicKey = Keys.getPublicKeyFromPrivate(privateKey) else {
                return nil
        }
        
        // Create the payload.
        let payload = ProfileTokenPayload(
            jti: NSUUID().uuidString,
            iat: ISO8601DateFormatter.string(from: issuedAt, timeZone: TimeZone(secondsFromGMT: 0)!, formatOptions: []),
            exp: ISO8601DateFormatter.string(from: expiresAt, timeZone: TimeZone(secondsFromGMT: 0)!, formatOptions: []),
            subject: subject ?? ["publicKey": publicKey],
            issuer: issuer ?? ["publicKey": publicKey],
            claim: profile)
        
        // Convert payload into a JSON object, then into [String: Any] representation.
        guard let payloadData = try? JSONEncoder().encode(payload),
            let payloadJSONObject = try? JSONSerialization.jsonObject(with: payloadData, options: .allowFragments),
            let payloadJSON = payloadJSONObject as? [String: Any] else {
                return nil
        }
        return JSONTokensJS().signToken(payload: payloadJSON, privateKey: privateKey, algorithm: signingAlgorithm)
    }
    
    /**
     Verifies a profile token.
     - parameter token: The token to be verified
     - parameter publicKeyOrAddress: The public key or address of the keypair that is thought to have signed the token
     - returns: The verified, decoded profile token
     - throws: Throws an error if token verification fails
     */
    public func verifyProfileToken(token: String, publicKeyOrAddress: String) throws -> ProfileToken {
        let jsonTokens = JSONTokensJS()
        guard let jsonString = jsonTokens.decodeToken(token: token),
            let data = jsonString.data(using: .utf8),
            let decodedToken = try? JSONDecoder().decode(ProfileToken.self, from: data),
            let payload = decodedToken.payload else {
                throw NSError.create(description: "Cannot decode payload from token.")
        }
        
        // Inspect and verify the subject
        guard let _ = payload.subject?["publicKey"] else {
            throw NSError.create(description: "Token doesn\'t have a subject public key")
        }
        // Inspect and verify the issuer
        guard let issuerPublicKey = payload.issuer?["publicKey"] else {
            throw NSError.create(description: "Token doesn\'t have an issuer public key")
        }
        // Inspect and verify the claim
        guard let _ = payload.claim else {
            throw NSError.create(description: "Token doesn\'t have a claim")
        }
        
        if publicKeyOrAddress == issuerPublicKey {
            // pass
        } else if let uncompressedKey = Keys.getUncompressed(publicKey: issuerPublicKey),
            let uncompressedAddress = Keys.getAddressFromPublicKey(uncompressedKey),
            publicKeyOrAddress == uncompressedAddress {
            // pass
        } else if let compressedKey = Keys.getCompressed(publicKey: issuerPublicKey),
            let compressedAddress = Keys.getAddressFromPublicKey(compressedKey),
            publicKeyOrAddress == compressedAddress {
            // pass
        } else {
            throw NSError.create(description: "Token verification failed")
        }
        
        guard let alg = decodedToken.header.alg else {
            throw NSError.create(description: "Token doesn't have an alg specified.")
        }
        
        guard let verified = jsonTokens.verifyToken(token: token, algorithm: alg, publicKey: issuerPublicKey), verified else {
            throw NSError.create(description: "Token verification failed")
        }
        return decodedToken
    }

    /**
     Validates the social proofs in a user's profile. Currently supports validation of Facebook, Twitter, GitHub, Instagram, LinkedIn and HackerNews accounts.
     - parameter profile: The Profile to be validated.
     - parameter ownerAddress: The owner bitcoin address to be validated.
     - parameter completion: Callback with an array of validated proof objects, or nil if there was an error.
     */
    public func validateProofs(profile: Profile, ownerAddress: String, completion: @escaping ([ExternalAccountProof]?) -> ()) {
        guard let profileData = try? JSONEncoder().encode(profile),
            let profileJSON = String(data: profileData, encoding: .utf8) else {
                return
        }
        ProfileProofsJS().validateProofs(profile: profileJSON, ownerAddress: ownerAddress, name: nil) { proofs in
            completion(proofs)
        }
    }
    
    /**
     Validates the social proofs in a user's profile. Currently supports validation of Facebook, Twitter, GitHub, Instagram, LinkedIn and HackerNews accounts.
     - parameter profile: The Profile to be validated.
     - parameter name: The Blockstack name to be validated
     - parameter completion: Callback with an array of validated proof objects, or nil if there was an error.
     */
    public func validateProofs(profile: Profile, name: String, completion: @escaping ([ExternalAccountProof]?) -> ()) {
        guard let profileData = try? JSONEncoder().encode(profile),
            let profileJSON = String(data: profileData, encoding: .utf8) else {
                return
        }
        ProfileProofsJS().validateProofs(profile: profileJSON, ownerAddress: nil, name: name) { proofs in
            completion(proofs)
        }
    }
    
    // - MARK: Storage
    
    /**
     Get the app storage bucket URL
     - parameter gaiaHubURL: The Gaia hub URL.
     - parameter: appPrivateKey: The app private key used to generate the app address.
     */
    @objc public func getAppBucketUrl(gaiaHubURL: URL, appPrivateKey: String, completion: @escaping (String?) -> ()) {
        guard let privateKey = Blockstack.shared.loadUserData()?.privateKey,
            let publicKey = Keys.getPublicKeyFromPrivate(privateKey),
            let challengeSignerAddress = Keys.getAddressFromPublicKey(publicKey) else {
                return
        }
        let task = URLSession.shared.dataTask(with: gaiaHubURL.appendingPathComponent("hub_info")) { data, response, error in
            guard error == nil,
                let data = data,
                let jsonObject = try? JSONSerialization.jsonObject(with: data, options: .allowFragments),
                let readURLPrefix = (jsonObject as? [String: Any])?["read_url_prefix"] else {
                    completion(nil)
                    return
            }
            completion("\(readURLPrefix)\(challengeSignerAddress)/")
        }
        task.resume()
    }
    
    /**
     Fetch the public read URL of a user file for the specified app.
     - parameter path: The path to the file to read
     - parameter username: The Blockstack ID of the user to look up
     - parameter appOrigin: The app origin
     - parameter zoneFileLookupURL: The URL to use for zonefile lookup. Defaults to 'http://localhost:6270/v1/names/'.
     - parameter completion: Callback with public read URL of the file, if one was found.
     */
    @objc public func getUserAppFileURL(at path: String,
                                        username: String,
                                        appOrigin: String,
                                        zoneFileLookupURL: URL = URL(string: "http://localhost:6270/v1/names/")!,
                                        completion: @escaping (URL?) -> ()) {
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
     List the set of files in this application's Gaia storage bucket.
     - parameter callback: A callback to invoke on each named file that returns `true` to continue the listing operation or `false` to end it.
     - parameter completion: Final callback that contains the number of files listed, or any error encountered.
     */
    @objc public func listFiles(callback: @escaping (_ filename: String) -> (Bool),
                                completion: @escaping (_ fileCount: Int, _ error: Error?) -> Void) {
        Gaia.getOrSetLocalHubConnection() { session, error in
            guard let session = session, error == nil else {
                print("gaia connection error")
                completion(-1, GaiaError.connectionError)
                return
            }
            session.listFilesLoop(page: nil, callCount: 0, fileCount: 0, callback: callback, completion: completion)
        }
    }
    
    /**
     Stores the data provided in the app's data store to to the file specified.
     - parameter to: The path to store the data in
     - parameter text: The String data to store in the file
     - parameter encrypt: The data with the app private key
     - parameter sign: Sign the data using ECDSA on SHA256 hashes with the signingKey.
     - parameter signingKey: The key with which to sign. Defaults to app private key.
     - parameter completion: Callback with the public url and any error
     - parameter publicURL: The publicly accessible url of the file
     - parameter error: Error returned by Gaia
     */
    @objc public func putFile(
        to path: String,
        text: String,
        encrypt: Bool = true,
        sign: Bool = false,
        signingKey: String? = nil,
        completion: @escaping (_ publicURL: String?, _ error: Error?) -> Void) {
        Gaia.getOrSetLocalHubConnection { session, error in
            guard let session = session, error == nil else {
                print("gaia connection error")
                completion(nil, error)
                return
            }
            session.putFile(to: path, content: text, encrypt: encrypt, encryptionKey: nil, sign: sign, signingKey: signingKey) { url, error in
                guard error != .configurationError else {
                    // Retry with a new config
                    Gaia.setLocalGaiaHubConnection() { session, error in
                        guard let session = session, error == nil else {
                            print("gaia connection error upon retry")
                            completion(nil, error)
                            return
                        }
                        session.putFile(to: path, content: text, encrypt: encrypt, encryptionKey: nil, sign: sign, signingKey: signingKey, completion: completion)
                    }
                    return
                }
                completion(url, error)
            }
        }
    }
    
    /**
     Stores the data provided in the app's data store to to the file specified.
     - parameter to: The path to store the data in
     - parameter bytes: The Bytes data to store in the file
     - parameter encrypt: The data with the app private key
     - parameter sign: Sign the data using ECDSA on SHA256 hashes with the signingKey.
     - parameter signingKey: The key with which to sign the data. Defaults to the app private key.
     - parameter completion: Callback with the public url and any error
     - parameter publicURL: The publicly accessible url of the file
     - parameter error: Error returned by Gaia
     */
    @objc public func putFile(
        to path: String,
        bytes: Bytes,
        encrypt: Bool = true,
        sign: Bool = false,
        signingKey: String? = nil,
        completion: @escaping (_ publicURL: String?, _ error: Error?) -> Void) {
        Gaia.getOrSetLocalHubConnection { session, error in
            guard let session = session, error == nil else {
                print("gaia connection error")
                completion(nil, error)
                return
            }
            session.putFile(to: path, content: bytes, encrypt: encrypt, encryptionKey: nil, sign: sign, signingKey: signingKey) { url, error in
                guard error != .configurationError else {
                    // Retry with a new config
                    Gaia.setLocalGaiaHubConnection { session, error in
                        guard let session = session, error == nil else {
                            print("gaia connection error upon retry")
                            completion(nil, error)
                            return
                        }
                        session.putFile(to: path, content: bytes, encrypt: encrypt, encryptionKey: nil, sign: sign, signingKey: signingKey, completion: completion)
                    }
                    return
                }
                completion(url, error)
            }
        }
    }
    
    /**
     Retrieves the specified file from the app's data store.
     - parameter path: The path to the file to read
     - parameter decrypt: Try to decrypt the data with the app private key
     - parameter verify: Whether the content should be verified, only to be used when the content was signed upon `putFile`.
     - parameter completion: Callback with retrieved content and any error
     - parameter content: The retrieved content as either Bytes, String, or DecryptedContent
     - parameter error: Error returned by Gaia
     */
    @objc public func getFile(at path: String, decrypt: Bool = true, verify: Bool = false, completion: @escaping (_ content: Any?, _ error: Error?) -> Void) {
        Gaia.getOrSetLocalHubConnection { session, error in
            guard let session = session, error == nil else {
                print("gaia connection error")
                completion(nil, error)
                return
            }
            session.getFile(at: path, decrypt: decrypt, verify: verify, completion: completion)
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
                        decrypt: Bool = true,
                        verify: Bool = false,
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
                verify: verify,
                multiplayerOptions: MultiplayerOptions(
                    username: username,
                    app: appOrigin,
                    zoneFileLookupURL: zoneFileLookupURL),
                completion: completion)
        }
    }
    
    /**
     Deletes the specified file from the app's data store.
     - parameter path: The path to the file to delete.
     - parameter wasSigned: Set to true if the file was originally signed in order for the corresponding signature file to also be deleted.
     - returns: Resolves when the file has been removed or rejects with an error.
     */
    @objc public func deleteFile(at path: String, wasSigned: Bool, completion: ((Error?) -> Void)? = nil) {
        Gaia.getOrSetLocalHubConnection { session, error in
            guard let session = session, error == nil else {
                print("gaia connection error")
                completion?(error)
                return
            }
            session.deleteFile(at: path, wasSigned: wasSigned) { error in
                guard error == nil else {
                    // Retry with a new config
                    Gaia.getOrSetLocalHubConnection { session, error in
                        guard let session = session, error == nil else {
                            print("gaia connection error")
                            completion?(error)
                            return
                        }
                        session.deleteFile(at: path, wasSigned: wasSigned) { error in
                            completion?(error)
                        }
                    }
                    return
                }
                completion?(nil)
            }
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

    // MARK: - Network
    
    /**
     Get WHOIS-like information for a name, including the address that owns it, the block at which it expires, and the zone file anchored to it (if available).
     - parameter fullyQualifiedName: the name to query.  Can be on-chain of off-chain.
     - parameter completion: a callback that includes a dictionary of the WHOIS-like information
     */
     @objc public func getNameInfo(fullyQualifiedName: String, completion: @escaping ([String: Any]?, Error?) -> ()) {
        let fetchNameInfo = Promise<[String: Any]>() { resolve, reject in
            let task = URLSession.shared.dataTask(with: URL(string: "\(BlockstackConstants.DefaultCoreAPIURL)/v1/names/\(fullyQualifiedName)")!) {data, response, error in
                guard error == nil,
                    let data = data,
                    let httpResponse = response as? HTTPURLResponse else {
                        reject(GaiaError.requestError)
                        return
                }
                switch httpResponse.statusCode {
                case 200:
                    guard let object = try? JSONSerialization.jsonObject(with: data, options: .allowFragments),
                        let json = object  as? [String: Any] else {
                            reject(GaiaError.invalidResponse)
                            return
                    }
                    resolve(json)
                case 404:
                    reject(GaiaError.itemNotFoundError)
                default:
                    reject(GaiaError.serverError)
                }
            }
            task.resume()
        }
        fetchNameInfo.then({ json in
            var info = json
            if let address = json["address"] as? String {
                info["address"] = BitcoinJS().coerceAddress(address: address)
            }
            completion(info, nil)
        }).catch { error in
            completion(nil, error)
        }
    }
    
    /**
     Get the pricing parameters and creation history of a namespace.
     - parameter namespaceID: the namespace to query.
     - parameter completion: a callback containing the namespace information.
     */
    @objc public func getNamespaceInfo(namespaceID: String, completion: @escaping ([String: Any]?, Error?) -> ()) {
        let fetchNamespaceInfo = Promise<[String: Any]>() { resolve, reject in
            let task = URLSession.shared.dataTask(with: URL(string: "\(BlockstackConstants.DefaultCoreAPIURL)/v1/namespaces/\(namespaceID)")!) {data, response, error in
                guard error == nil,
                    let data = data,
                    let httpResponse = response as? HTTPURLResponse else {
                        reject(GaiaError.requestError)
                        return
                }
                switch httpResponse.statusCode {
                case 200:
                    guard let object = try? JSONSerialization.jsonObject(with: data, options: .allowFragments),
                        let json = object  as? [String: Any] else {
                            reject(GaiaError.invalidResponse)
                            return
                    }
                    resolve(json)
                case 404:
                    reject(GaiaError.itemNotFoundError)
                default:
                    reject(GaiaError.serverError)
                }
            }
            task.resume()
        }
        fetchNamespaceInfo.then({ json in
            var info = json
            let bitcoinJS = BitcoinJS()
            if let address = json["address"] as? String {
                info["address"] = bitcoinJS.coerceAddress(address: address)
            }
            if let recipientAddress = json["recipient_address"] as? String {
                info["recipient_address"] = bitcoinJS.coerceAddress(address: recipientAddress)
            }
            completion(info, nil)
        }).catch { error in
            completion(nil, error)
        }
    }
    
    /**
     Get the names -- both on-chain and off-chain -- owned by an address.
     - parameter address: the blockchain address (the hash of the owner public key)
     - parameter completion: a callback that contains a list of names
     */
    public func getNamesOwned(address: String, completion: @escaping ([String]?, Error?) -> ()) {
        guard let networkAddress = BitcoinJS().coerceAddress(address: address) else {
            completion(nil, GaiaError.itemNotFoundError)
            return
        }
        let fetchNamesOwned = Promise<[String]>() { resolve, reject in
            let url = URL(string: "\(BlockstackConstants.DefaultCoreAPIURL)/v1/addresses/bitcoin/\(networkAddress)")!
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                guard error == nil, let data = data else {
                    reject(GaiaError.requestError)
                    return
                }
                guard let object = try? JSONSerialization.jsonObject(with: data, options: .allowFragments),
                    let json = object  as? [String: Any],
                    let names = json["names"] as? [String] else {
                        reject(GaiaError.invalidResponse)
                        return
                }
                resolve(names)
            }
            task.resume()
        }
        fetchNamesOwned.then({ names in
            completion(names, nil)
        }).catch { error in
            completion(nil, error)
        }
    }
    
    /**
     Get the price of a name.
     - parameter fullyQualifiedName: the name to query
     - parameter completion: callback that contains price information as { unit: String, amount: Int }, where .units encodes the cryptocurrency units to pay (e.g. BTC, STACKS), and .amount encodes the number of units, in the smallest denominiated amount (e.g. if .units is BTC, .amount will be satoshis; if .units is STACKS, .amount will be microStacks)
     */
    public func getNamePrice(fullyQualifiedName: String, completion: @escaping ((units: String, amount: Int)?, Error?) -> ()) {
        self.getNamePriceV2(fullyQualifiedName) { (data, error) in
            guard let data = data, error == nil else {
                self.getNamePriceV1(fullyQualifiedName, completion: completion)
                return
            }
            completion((data.0, data.1), nil)
        }
    }
    
    /**
     Get the price of a namespace
     - parameter namespaceId: the namespace to query
     - parameter completion: callback that contains price information as { unit: String, amount: Int }, where .units encodes the cryptocurrency units to pay (e.g. BTC, STACKS), and .amount encodes the number of units, in the smallest denominiated amount (e.g. if .units is BTC, .amount will be satoshis; if .units is STACKS, .amount will be microStacks)
     */
    public func getNamespacePrice(namespaceId: String, completion: @escaping ((units: String, amount: Int)?, Error?) -> ()) {
        self.getNamespacePriceV2(namespaceId) { (data, error) in
            guard let data = data, error == nil else {
                self.getNamespacePriceV1(namespaceId, completion: completion)
                return
            }
            completion((data.0, data.1), nil)
        }
    }

    /**
     How many blocks can pass between a name expiring and the name being able to be re-registered by a different owner?
     - returns: The number of blocks before name expires.
     */
    public func getGracePeriod() -> Int {
        return 5000
    }
    
    /**
     Get the blockchain address to which a name's registration fee must be sent (the address will depend on the namespace in which it is registered)
     - parameter namespace: the namespace ID
     - parameter completion: a callback that contains an address
     */
    public func getNamespaceBurnAddress(namespace: String, completion: @escaping ((String?, Error?) -> ())) {
        let fetchNamespace = Promise<[String: Any]>() { resolve, reject in
            let url = URL(string: "\(BlockstackConstants.DefaultCoreAPIURL)/v1/namespaces/\(namespace)")!
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                guard error == nil, let data = data else {
                    reject(GaiaError.requestError)
                    return
                }
                guard let object = try? JSONSerialization.jsonObject(with: data, options: .allowFragments),
                    let json = object  as? [String: Any] else {
                        reject(GaiaError.invalidResponse)
                        return
                }
                resolve(json)
            }
            task.resume()
        }

        let fetchBlockHeight = Promise<Int>() { resolve, reject in
            let url = URL(string: "https://blockchain.info/latestblock?cors=true")!
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                guard error == nil, let data = data else {
                    reject(GaiaError.requestError)
                    return
                }
                guard let object = try? JSONSerialization.jsonObject(with: data, options: .allowFragments),
                    let json = object  as? [String: Any],
                    let height = json["height"] as? Int else {
                        reject(GaiaError.invalidResponse)
                        return
                }
                resolve(height)
            }
            task.resume()
        }

        all(fetchNamespace, fetchBlockHeight).then({ (json, blockHeight) in
            guard let version = json["version"] as? Int,
                let revealBlock = json["reveal_block"] as? Int,
                let creatorAddress = json["address"] as? String,
                let defaultAddress = self.getDefaultBurnAddress() else {
                    completion(nil, GaiaError.itemNotFoundError)
                    return
            }
            var address: String
            // pay-to-namespace-creator if this namespace is less than 1 year old
            address = (version == 2 && (revealBlock + 52595 >= blockHeight)) ?
                creatorAddress : defaultAddress
            completion(BitcoinJS().coerceAddress(address: address), nil)
        }).catch { error in
            completion(nil, error)
        }
    }

    // MARK: - Private
    
    private var asWebAuthSession: Any? // ASWebAuthenticationSession
    private let dustMinimum = 5500
    private var sfAuthSession : SFAuthenticationSession?

    private func getDefaultBurnAddress() -> String? {
        return BitcoinJS().coerceAddress(address: "1111111111111111111114oLvT2")
    }

    private func getNamePriceV1(_ fullyQualifiedName: String, completion: @escaping ((units: String, amount: Int)?, Error?) -> ()) {
        let fetchNamePrice = Promise<[String: Any]>() { resolve, reject in
            let url = URL(string: "\(BlockstackConstants.DefaultCoreAPIURL)/v1/prices/names/\(fullyQualifiedName)")!
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                guard error == nil, let data = data else {
                    reject(GaiaError.requestError)
                    return
                }
                guard let object = try? JSONSerialization.jsonObject(with: data, options: .allowFragments),
                    let json = object  as? [String: Any] else {
                        reject(GaiaError.invalidResponse)
                        return
                }
                resolve(json)
            }
            task.resume()
        }
        fetchNamePrice.then({ json in
            guard let namePrice = json["name_price"] as? [String: Any],
                let satoshisString = namePrice["satoshis"] as? String,
                var satoshis = Int(satoshisString) else {
                    completion(nil, GaiaError.invalidResponse)
                    return
            }
            if satoshis < self.dustMinimum {
                satoshis = self.dustMinimum
            }
            completion(("BTC", satoshis), nil)
        }).catch { error in
            completion(nil, error)
        }
    }
    
    private func getNamePriceV2(_ fullyQualifiedName: String, completion: @escaping ((units: String, amount: Int)?, Error?) -> ()) {
        let fetchNamePrice = Promise<[String: Any]>() { resolve, reject in
            let url = URL(string: "\(BlockstackConstants.DefaultCoreAPIURL)/v2/prices/names/\(fullyQualifiedName)")!
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                guard error == nil, let data = data else {
                    reject(GaiaError.requestError)
                    return
                }
                guard let object = try? JSONSerialization.jsonObject(with: data, options: .allowFragments),
                    let json = object  as? [String: Any] else {
                        reject(GaiaError.invalidResponse)
                        return
                }
                resolve(json)
            }
            task.resume()
        }
        fetchNamePrice.then({ json in
            guard let namePrice = json["name_price"] as? [String: Any],
                let units = namePrice["units"] as? String,
                let amountString = namePrice["amount"] as? String,
                var amount = Int(amountString) else {
                    completion(nil, GaiaError.invalidResponse)
                    return
            }
            if units == "BTC" && amount < self.dustMinimum {
                amount = self.dustMinimum
            }
            completion((units, amount), nil)
        }).catch { error in
            completion(nil, error)
        }
    }
    
    private func getNamespacePriceV1(_ namespaceId: String, completion: @escaping ((units: String, amount: Int)?, Error?) -> ()) {
        let fetchNamespacePrice = Promise<[String: Any]>() { resolve, reject in
            let url = URL(string: "\(BlockstackConstants.DefaultCoreAPIURL)/v1/prices/namespaces/\(namespaceId)")!
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                guard error == nil, let data = data else {
                    reject(GaiaError.requestError)
                    return
                }
                guard let object = try? JSONSerialization.jsonObject(with: data, options: .allowFragments),
                    let json = object  as? [String: Any] else {
                        reject(GaiaError.invalidResponse)
                        return
                }
                resolve(json)
            }
            task.resume()
        }
        fetchNamespacePrice.then({ json in
            guard let satoshisString = json["satoshis"] as? String,
                var satoshis = Int(satoshisString) else {
                    completion(nil, GaiaError.invalidResponse)
                    return
            }
            if satoshis < self.dustMinimum {
                satoshis = self.dustMinimum
            }
            completion(("BTC", satoshis), nil)
        }).catch { error in
            completion(nil, error)
        }
    }
    
    private func getNamespacePriceV2(_ namespaceId: String, completion: @escaping ((units: String, amount: Int)?, Error?) -> ()) {
        let fetchNamespacePrice = Promise<[String: Any]>() { resolve, reject in
            let url = URL(string: "\(BlockstackConstants.DefaultCoreAPIURL)/v2/prices/namespaces/\(namespaceId)")!
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                guard error == nil, let data = data else {
                    reject(GaiaError.requestError)
                    return
                }
                guard let object = try? JSONSerialization.jsonObject(with: data, options: .allowFragments),
                    let json = object  as? [String: Any] else {
                        reject(GaiaError.invalidResponse)
                        return
                }
                resolve(json)
            }
            task.resume()
        }
        fetchNamespacePrice.then({ json in
            guard let namespacePrice = json["amount"] as? String,
                let units = json["units"] as? String,
                var amount = Int(namespacePrice) else {
                    completion(nil, GaiaError.invalidResponse)
                    return
            }
            if units == "BTC" && amount < self.dustMinimum {
                amount = self.dustMinimum
            }
            completion((units, amount), nil)
        }).catch { error in
            completion(nil, error)
        }
    }
}
