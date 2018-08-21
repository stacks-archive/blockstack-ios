//
//  GaiaSession.swift
//  Blockstack
//
//  Created by Yukan Liao on 2018-04-19.
//

import Foundation
import CryptoSwift

public class GaiaHubSession {
    let config: GaiaConfig

    init(with config: GaiaConfig) {
        self.config = config
    }

    func getFile(at path: String, decrypt: Bool, multiplayerOptions: MultiplayerOptions? = nil, completion: @escaping (Any?, GaiaError?) -> Void) {
        let fetch: (URL?) -> () = { fullReadURL in
            guard let url = fullReadURL else {
                completion(nil, GaiaError.configurationError)
                return
            }
            
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                guard let data = data, error == nil else {
                    print("Gaia hub store request error")
                    completion(nil, GaiaError.requestError)
                    return
                }
                let contentType = (response as? HTTPURLResponse)?.allHeaderFields["Content-Type"] as? String ?? "application/json"
                if contentType == "application/octet-stream" && !decrypt {
                    completion(data.bytes, nil)
                } else {
                    // Handle text/plain and application/json content types
                    guard let text = String(data: data, encoding: .utf8) else {
                        return
                    }
                    if decrypt {
                        guard let privateKey = ProfileHelper.retrieveProfile()?.privateKey else {
                            completion(nil, nil)
                            return
                        }
                        let decryptedValue = Encryption.decryptECIES(privateKey: privateKey, cipherObjectJSONString: text)
                        completion(decryptedValue, nil)
                    } else {
                        completion(text, nil)
                    }
                }
            }
            task.resume()
        }
        if let options = multiplayerOptions {
            Gaia.getUserAppFileURL(at: path, username: options.username, appOrigin: options.app, zoneFileLookupURL: options.zoneFileLookupURL) { url in
                fetch(url?.appendingPathComponent(path))
            }
        } else {
            fetch(URL(string: "\(self.config.URLPrefix!)\(self.config.address!)/\(path)"))
        }
    }
    
    func putFile(to path: String, content: Bytes, encrypt: Bool = false, completion: @escaping (String?, GaiaError?) -> ()) {
        if encrypt {
            guard let data = self.encrypt(content: .bytes(content)) else {
                // TODO: Error for invalid app public key?
                completion(nil, nil)
                return
            }
            self.upload(path: path, contentType: "application/json", data: data, completion: completion)
        } else {
            self.upload(path: path, contentType: "application/octet-stream", data: Data(bytes: content), completion: completion)
        }
    }
    
    func putFile(to path: String, content: String, encrypt: Bool = false, completion: @escaping (String?, GaiaError?) -> ()) {
        if encrypt {
            guard let data = self.encrypt(content: .text(content)) else {
                // TODO: Error for invalid app public key?
                completion(nil, nil)
                return
            }
            self.upload(path: path, contentType: "application/json", data: data, completion: completion)
        } else {
            guard let data = content.data(using: .utf8) else {
                completion(nil, nil)
                return
            }
            self.upload(path: path, contentType: "text/plain", data: data, completion: completion)
        }
    }
    
    // MARK: - Private
    
    private enum Content {
        case text(String)
        case bytes(Bytes)
    }
    
    private func encrypt(content: Content) -> Data? {
        // Encrypt to Gaia using the app public key
        guard let privateKey = ProfileHelper.retrieveProfile()?.privateKey,
            let publicKey = Keys.getPublicKeyFromPrivate(privateKey) else {
                return nil
        }

        // Encrypt and serialize to JSON
        var cipherObjectJSON: String?
        switch content {
        case let .bytes(bytes):
            cipherObjectJSON = Encryption.encryptECIES(recipientPublicKey: publicKey, content: bytes, isString: false)
        case let .text(text):
            cipherObjectJSON = Encryption.encryptECIES(recipientPublicKey: publicKey, content: text)
        }
        
        guard let cipher = cipherObjectJSON else {
            return nil
        }
        return cipher.data(using: .utf8)
    }
    
    private func upload(path: String, contentType: String, data: Data, completion: @escaping (String?, GaiaError?) -> ()) {
        let putURL = URL(string:"\(self.config.server!)/store/\(self.config.address!)/\(path)")
        var request = URLRequest(url: putURL!)
        request.httpMethod = "POST"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue("bearer \(self.config.token!)", forHTTPHeaderField: "Authorization")
        request.httpBody = data
        
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
}

public struct MultiplayerOptions {
    let username: String
    let app: String
    let zoneFileLookupURL: URL
}

public struct PutFileResponse: Codable {
    let publicURL: String?
}

public struct PutFileOptions {
    let encrypt: Bool?
}
