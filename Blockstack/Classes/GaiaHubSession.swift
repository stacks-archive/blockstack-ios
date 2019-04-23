//
//  GaiaSession.swift
//  Blockstack
//
//  Created by Yukan Liao on 2018-04-19.
//

import Foundation
import CryptoSwift

class GaiaHubSession {
    let config: GaiaConfig

    init(with config: GaiaConfig) {
        self.config = config
    }

    /**
     Loop over the list of files in a Gaia hub, and run a callback on each entry. Not meant to be called by external clients.
     - parameter page: The page ID.
     - parameter callCount: The loop count.
     - parameter fileCount: The number of files listed so far.
     - parameter callback: The callback to invoke on each file. If it returns a falsey value, then the loop stops. If it returns a truthy value, the loop continues.
     - parameter completion: Final callback that contains the number of files listed, or any error encountered.
     */
    func listFilesLoop(page: String?, callCount: Int, fileCount: Int, callback: @escaping (_ filename: String) -> (Bool), completion: @escaping (_ fileCount: Int, _ gaiaError: GaiaError?) -> Void) {
        if callCount > 65536 {
            // This is ridiculously huge, and probably indicates a faulty Gaia hub anyway (e.g. on that serves endless data).
            completion(-1, GaiaError.invalidResponse)
        }

        guard let server = self.config.server,
            let address = self.config.address,
            let token = self.config.token,
            let url = URL(string: "\(server)/list-files/\(address)") else {
                return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("bearer \(token)", forHTTPHeaderField: "Authorization")
        if let jsonData = page?.data(using: .utf8),
            let body = try? JSONSerialization.jsonObject(with: jsonData, options: .allowFragments),
            let pageRequest = body as? [String: Any] {
            request.httpBody = jsonData
            if let pageLength = pageRequest["length"] as? String {
                request.addValue(pageLength, forHTTPHeaderField: "Content-Length")
            }
        } else {
            let pageRequest: [String: Any] = ["page": NSNull()]
            let body = try? JSONSerialization.data(withJSONObject: pageRequest, options: [])
            request.httpBody = body
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil,
                let data = data,
                let jsonObject = try? JSONSerialization.jsonObject(with: data, options: .allowFragments),
                let result = jsonObject as? [String: Any],
                let entries = result["entries"] as? [String],
                result.keys.contains("page") else {
                    completion(-1, GaiaError.invalidResponse)
                    return
            }

            var fileCount = fileCount
            for entry in entries {
                fileCount += 1
                // Run callback on each entry; negative response means we're done.
                if !callback(entry) {
                    completion(fileCount, nil)
                    return
                }
            }
            
            if !entries.isEmpty, let nextPage = result["page"] as? String {
                self.listFilesLoop(page: nextPage, callCount: callCount + 1, fileCount: fileCount, callback: callback, completion: completion)
            } else {
                completion(fileCount, nil)
            }
        }
        task.resume()
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
                        let decryptedValue = Encryption.decryptECIES(cipherObjectJSONString: text, privateKey: privateKey)
                        completion(decryptedValue, nil)
                    } else {
                        completion(text, nil)
                    }
                }
            }
            task.resume()
        }
        if let options = multiplayerOptions {
            Blockstack.shared.getUserAppFileURL(at: path, username: options.username, appOrigin: options.app, zoneFileLookupURL: options.zoneFileLookupURL) { url in
                fetch(url?.appendingPathComponent(path))
            }
        } else {
            fetch(URL(string: "\(self.config.URLPrefix!)\(self.config.address!)/\(path)"))
        }
    }
    
    func putFile(to path: String, content: Bytes, encrypt: Bool = true, completion: @escaping (String?, GaiaError?) -> ()) {
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
    
    func putFile(to path: String, content: String, encrypt: Bool = true, completion: @escaping (String?, GaiaError?) -> ()) {
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
            cipherObjectJSON = Encryption.encryptECIES(content: bytes, recipientPublicKey: publicKey, isString: false)
        case let .text(text):
            cipherObjectJSON = Encryption.encryptECIES(content: text, recipientPublicKey: publicKey)
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

            // Check for specific codes that indicate config error
            if (response as? HTTPURLResponse)?.statusCode == 401 {
                completion(nil, GaiaError.configurationError)
                return
            }
            
            do {
                let jsonDecoder = JSONDecoder()
                let putfileResponse = try jsonDecoder.decode(PutFileResponse.self, from: data)
                completion(putfileResponse.publicURL!, nil)
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
