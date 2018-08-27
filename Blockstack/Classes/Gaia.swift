//
//  Gaia.swift
//  Blockstack
//
//  Created by Yukan Liao on 2018-04-15.
//

import Foundation

public class Gaia {

    // TODO: Utilize promise pattern/other way of preventing simultaneous requests
    static func getOrSetLocalHubConnection(callback: @escaping (GaiaHubSession?, GaiaError?) -> Void) {
        if let session = self.session {
            callback(session, nil)
        } else if let config = Gaia.retrieveConfig() {
            self.session = GaiaHubSession(with: config)
            callback(self.session, nil)
        } else {
            let userData = ProfileHelper.retrieveProfile()
            let hubURL = userData?.hubURL ?? BlockstackConstants.DefaultGaiaHubURL
            guard let appPrivateKey = userData?.privateKey else {
                // TODO: Return appropriate error
                callback(nil, nil)
                return
            }
            self.connectToHub(hubURL: hubURL, challengeSignerHex: appPrivateKey) { session, error in
                self.session = session
                callback(session, error)
            }
        }
    }
    
    /**
     Fetch the public read URL of a user file for the specified app.
     - parameter path: The path to the file to read
     - parameter username: The Blockstack ID of the user to look up
     - parameter appOrigin: The app origin
     - parameter zoneFileLookupURL: The URL to use for zonefile lookup. Defaults to 'http://localhost:6270/v1/names/'.
     - parameter completion: Callback with public read URL of the file, if one was found.
     */
    static func getUserAppFileURL(at path: String, username: String, appOrigin: String, zoneFileLookupURL: URL = URL(string: "http://localhost:6270/v1/names/")!, completion: @escaping (URL?) -> ()) {
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

    static func clearSession() {
        self.session = nil
    }
    
    // MARK: - Private

    // TODO: Add support for multiple sessions
    private static var session: GaiaHubSession? {
        didSet {
            guard let session = self.session else {
                self.resetConfig()
                return
            }
            self.saveConfig(session.config)
        }
    }
    
    private static func connectToHub(hubURL: String, challengeSignerHex: String, completion: @escaping (GaiaHubSession?, GaiaError?) -> Void) {
        self.getHubInfo(for: hubURL) { hubInfo, error in
            guard error == nil else {
                completion(nil, GaiaError.connectionError)
                return
            }
            
            let bitcoinJS = BitcoinJS()
            let signature = bitcoinJS.signChallenge(privateKey: challengeSignerHex, challengeText: hubInfo!.challengeText!)
            let publicKey = Keys.getPublicKeyFromPrivate(challengeSignerHex, compressed: true)
            let tokenObject: [String: Any?] = ["publickey": publicKey, "signature": signature]
            let token = tokenObject.toJsonString()?.encodingToBase64()
            let address = Keys.getAddressFromPublicKey(publicKey!)
            let config = GaiaConfig(URLPrefix: hubInfo?.readURLPrefix, address: address, token: token, server: hubURL)
            completion(GaiaHubSession(with: config), nil)
        }
    }

    private static func getHubInfo(for hubURL: String, completion: @escaping (GaiaHubInfo?, Error?) -> Void) {
        guard let hubInfoURL = URL(string: "\(hubURL)/hub_info") else {
            completion(nil, nil)
            return
        }
        let task = URLSession.shared.dataTask(with: hubInfoURL) { data, response, error in
            guard let data = data, error == nil else {
                print("Error connecting to Gaia hub")
                completion(nil, error)
                return
            }
            do {
                let jsonDecoder = JSONDecoder()
                let hubInfo = try jsonDecoder.decode(GaiaHubInfo.self, from: data)
                completion(hubInfo, nil)
            } catch {
                completion(nil, error)
            }
        }
        task.resume()
    }

    private static func saveConfig(_ config: GaiaConfig) {
        self.resetConfig()
        if let config = try? PropertyListEncoder().encode(config) {
            UserDefaults.standard.set(config, forKey: BlockstackConstants.GaiaHubConfigUserDefaultLabel)
        }
    }
    
    static func resetConfig() {
        UserDefaults.standard.removeObject(forKey: BlockstackConstants.GaiaHubConfigUserDefaultLabel)
    }
    
    private static func retrieveConfig() -> GaiaConfig? {
        guard let data = UserDefaults.standard.value(forKey:
            BlockstackConstants.GaiaHubConfigUserDefaultLabel) as? Data,
            let config = try? PropertyListDecoder().decode(GaiaConfig.self, from: data) else {
                return nil
        }
        return config
    }
}

public struct GaiaConfig: Codable {
    let URLPrefix: String?
    let address: String?
    let token: String?
    let server: String?
}

public struct GaiaHubInfo: Codable {
    let challengeText: String?
    let readURLPrefix: String?
    
    enum CodingKeys: String, CodingKey {
        case challengeText = "challenge_text"
        case readURLPrefix = "read_url_prefix"
    }
}
