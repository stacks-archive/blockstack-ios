//
//  GaiaSession.swift
//  Blockstack
//
//  Created by Yukan Liao on 2018-04-19.
//

import Foundation

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

public struct PutFileResponse: Codable {
    let publicURL: String?
}

public struct PutFileOptions {
    let encrypt: Bool?
}

public struct GetFileOptions {
    let decrypt: Bool?
    let username: String?
    let app: String?
    let zoneFileLookupURL: URL?
}

public class GaiaSession {
    var config: GaiaConfig?
    
    init() {
    }
    
    func getOrSetLocalHubConnection(completion: @escaping (GaiaError?) -> Void) {
        if (self.config != nil) {
            completion(nil)
        } else if retrieveConfig() != nil {
            completion(nil)
        } else {
            setLocalHubConnection(completion: completion)
        }
    }
    
    func setLocalHubConnection(completion: @escaping (GaiaError?) -> Void) {
        let userData = ProfileHelper.retrieveProfile()
        let hubURL = userData?.hubURL ?? BlockstackConstants.DefaultGaiaHubURL
        let appPrivateKey = userData?.privateKey
        
        connectToHub(hubURL: hubURL, challengeSignerHex: appPrivateKey!, completion: completion)
    }
    
    func connectToHub(hubURL: String, challengeSignerHex: String, completion: @escaping (GaiaError?) -> Void) {
        getHubInfo(hubURL: hubURL) { (hubInfo, error) in
            guard error == nil else {
                completion(GaiaError.connectionError)
                return
            }
            
            let bitcoinJS = BitcoinJS()
            let signature = bitcoinJS.signChallenge(privateKey: challengeSignerHex, challengeText: hubInfo!.challengeText!)
            let publicKey = Keys.getPublicKeyFromPrivate(challengeSignerHex)
            let tokenObject = ["publickey": publicKey, "signature": signature]
            let tokenJsonString = self.dictionaryToJsonString(tokenObject: tokenObject)
            let token = tokenJsonString?.toBase64()
            let address = Keys.getAddressFromPublicKey(publicKey!)
            let gaiaConfig = GaiaConfig(URLPrefix: hubInfo?.readURLPrefix, address: address, token: token, server: hubURL)
            self.config = gaiaConfig
            self.storeConfig(gaiaConfig)
            
            completion(nil)
        }
    }
    
    func getHubInfo(hubURL: String, completion: @escaping (GaiaHubInfo?, Error?) -> Void) {
        let hubInfoURL = URL(string: "\(hubURL)/hub_info")
        let task = URLSession.shared.dataTask(with: hubInfoURL!) { data, response, error in
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
    
    func storeConfig(_ config: GaiaConfig) {
        UserDefaults.standard.set(try? PropertyListEncoder().encode(config),
                                  forKey: BlockstackConstants.GaiaHubConfigUserDefaultLabel)
    }
    
    func retrieveConfig() -> GaiaConfig? {
        if let data = UserDefaults.standard.value(forKey:BlockstackConstants.GaiaHubConfigUserDefaultLabel) as? Data {
            let config = try? PropertyListDecoder().decode(GaiaConfig.self, from: data)
            self.config = config
            return config
        } else {
            return nil
        }
    }
    
    func resetConfig() {
        UserDefaults.standard.set(nil,
                                  forKey: BlockstackConstants.GaiaHubConfigUserDefaultLabel)
    }
    
    func putFile(path: String, content: Dictionary<String, String>, completion: @escaping (String?, GaiaError?) -> Void) {
        let contentType = "application/json"
        let stringContent = dictionaryToJsonString(tokenObject: content)!

        print(stringContent as Any)
        
        uploadToGaiaHub(path: path,
                        content: stringContent,
                        config: self.config!,
                        contentType: contentType,
                        completion: completion)
    }
    
    func uploadToGaiaHub(path: String,
                         content: String,
                         config: GaiaConfig,
                         contentType: String,
                         completion: @escaping (String?, GaiaError?) -> Void) {
        let putURL = URL(string:"\(config.server!)/store/\(config.address!)/\(path)")
        var request = URLRequest(url: putURL!)
        request.httpMethod = "POST"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue("bearer \(config.token!)", forHTTPHeaderField: "Authorization")
        request.httpBody = content.data(using: .utf8)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Gaia hub store request error")
                completion(nil, GaiaError.requestError)
                return
            }
            
            do {
                let jsonDecoder = JSONDecoder()
                let putfileResponse = try jsonDecoder.decode(PutFileResponse.self, from: data)
                completion(putfileResponse.publicURL, nil)
            } catch {
                completion(nil, GaiaError.invalidResponse)
            }
        }
        task.resume()
    }
    
    func getFile(path: String, completion: @escaping (Any?, GaiaError?) -> Void) {
        guard let config = self.config else {
            return
        }
        
        let fullReadURLString = "\(config.URLPrefix!)\(config.address!)/\(path)"
        let fullReadURL = URL(string: fullReadURLString)
        
        let task = URLSession.shared.dataTask(with: fullReadURL!) { data, response, error in
            guard let data = data, error == nil else {
                print("Gaia hub store request error")
                completion(nil, GaiaError.requestError)
                return
            }
            
            do {
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    completion(nil, GaiaError.invalidResponse)
                    return
                }
                completion(json, nil)
            } catch {
                completion(nil, GaiaError.invalidResponse)
            }
        }
        task.resume()
    }
    
    func dictionaryToJsonString(tokenObject: [String: String?]) -> String? {
        let jsonData: Data? = try? JSONSerialization.data(withJSONObject: tokenObject, options: [])
        return String(data: jsonData!, encoding: String.Encoding.utf8)
    }
}
