//
//  GaiaSession.swift
//  Blockstack
//
//  Created by Yukan Liao on 2018-04-19.
//

import Foundation
import CryptoSwift
import Promises
import Regex

fileprivate let signatureFileSuffix = ".sig"

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
    
    func getFile(at path: String, decrypt: Bool, verify: Bool, multiplayerOptions: MultiplayerOptions? = nil, completion: @escaping (Any?, GaiaError?) -> Void) {
        // In the case of signature verification, but no decryption, we need to fetch two files.
        // First, fetch the unencrypted file. Then fetch the signature file and validate it.
        if verify && !decrypt {
            all(
                self.getFileContents(at: path, multiplayerOptions: multiplayerOptions),
                self.getFileContents(at: "\(path)\(signatureFileSuffix)", multiplayerOptions: multiplayerOptions),
                self.getGaiaAddress(multiplayerOptions: multiplayerOptions)
                ).then({ fileContents, sigContents, gaiaAddress in
                    guard let signatureObject =
                        try? JSONDecoder().decode(SignatureObject.self, from: sigContents.0),
                        let signerAddress = Keys.getAddressFromPublicKey(signatureObject.publicKey),
                        signerAddress == gaiaAddress,
                        let isSignatureValid = EllipticJS().verifyECDSA(
                            content: fileContents.0.bytes,
                            publicKey: signatureObject.publicKey,
                            signature: signatureObject.signature),
                        isSignatureValid else {
                            completion(nil, GaiaError.signatureVerificationError)
                            return
                    }
                    let content: Any? =
                        fileContents.1 == "application/octet-stream" ?
                            fileContents.0.bytes :
                            String(data: fileContents.0, encoding: .utf8)
                    completion(content, nil)
                }).catch { error in
                    completion(nil, error as? GaiaError ?? GaiaError.signatureVerificationError)
            }
            return
        }
        
        self.getFileContents(at: path, multiplayerOptions: multiplayerOptions).then({ (data, contentType) in
            if !verify && !decrypt {
                // Simply fetch data if there is no verify or decrypt
                let content: Any? =
                    contentType == "application/octet-stream" ?
                        data.bytes :
                        String(data: data, encoding: .utf8)
                completion(content, nil)
                return
            } else if decrypt {
                // Handle decrypt scenarios
                guard let privateKey = ProfileHelper.retrieveProfile()?.privateKey else {
                    completion(nil, nil)
                    return
                }
                let verifyAndGetCipherText = Promise<String>() { resolve, reject in
                    if !verify {
                        // Decrypt, but not verify
                        guard let encryptedText = String(data: data, encoding: .utf8) else {
                            reject(GaiaError.invalidResponse)
                            return
                        }
                        resolve(encryptedText)
                    } else {
                        // Decrypt && verify
                        guard let signatureObject = try? JSONDecoder().decode(SignatureObject.self, from: data),
                            let encryptedText = signatureObject.cipherText else {
                                reject(GaiaError.invalidResponse)
                                return
                        }
                        let getUserAddress = Promise<String> { resolveAddress, rejectAddress in
                            if multiplayerOptions == nil {
                                guard let userPublicKey = Keys.getPublicKeyFromPrivate(privateKey, compressed: true),
                                    let address = Keys.getAddressFromPublicKey(userPublicKey) else {
                                        reject(GaiaError.signatureVerificationError)
                                        return
                                }
                                resolveAddress(address)
                            } else {
                                self.getGaiaAddress(multiplayerOptions: multiplayerOptions!).then({
                                    resolve($0)
                                }).catch(rejectAddress)
                            }
                        }
                        getUserAddress.then({ userAddress in
                            let signerAddress = Keys.getAddressFromPublicKey(signatureObject.publicKey)
                            guard signerAddress == userAddress,
                                let isSignatureValid = EllipticJS().verifyECDSA(
                                    content: encryptedText.bytes,
                                    publicKey: signatureObject.publicKey,
                                    signature: signatureObject.signature),
                                isSignatureValid else {
                                    completion(nil, GaiaError.signatureVerificationError)
                                    return
                            }
                            resolve(encryptedText)
                        }).catch(reject)
                    }
                }
                verifyAndGetCipherText.then({ cipherText in
                    let decryptedValue = Encryption.decryptECIES(cipherObjectJSONString: cipherText, privateKey: privateKey)
                    completion(decryptedValue, nil)
                }).catch { error in
                    completion(nil, error as? GaiaError ?? GaiaError.signatureVerificationError)
                }
                return
            } else {
                // We should not be here.
                completion(nil, GaiaError.requestError)
                return
            }
        }).catch { error in
            completion(nil, error as? GaiaError ?? GaiaError.requestError)
        }
    }

    func putFile(to path: String, content: Bytes, encrypt: Bool, encryptionKey: String?, sign: Bool, signingKey: String?, completion: @escaping (String?, GaiaError?) -> ()) {
        guard let data = encrypt ?
            self.encrypt(content: .bytes(content), with: encryptionKey) :
            Data(bytes: content) else {
                // TODO: Throw error
                completion(nil, nil)
                return
        }
        self.signAndPutData(to: path, content: data, originalContentType: "application/octet-stream", encrypted: encrypt, sign: sign, signingKey: signingKey, completion: completion)
    }
    
    func putFile(to path: String, content: String, encrypt: Bool, encryptionKey: String?, sign: Bool, signingKey: String?, completion: @escaping (String?, GaiaError?) -> ()) {
        guard let data = encrypt ?
            self.encrypt(content: .text(content), with: encryptionKey) :
            content.data(using: .utf8) else {
                // TODO: Throw error
                completion(nil, nil)
                return
        }
        self.signAndPutData(to: path, content: data, originalContentType: "text/plain", encrypted: encrypt, sign: sign, signingKey: signingKey, completion: completion)
    }
    
    func deleteFile(at path: String, wasSigned: Bool, completion: @escaping ((Error?) -> Void)) {
        var promises = [Promise<Void>]()
        promises.append(self.deleteItem(at: path))
        if wasSigned {
            promises.append(self.deleteItem(at: "\(path)\(signatureFileSuffix)"))
        }
        all(promises).then({ _ in
            completion(nil)
        }).catch { error in
            completion(error)
        }
    }
    
    // MARK: - Private
    
    private enum Content {
        case text(String)
        case bytes(Bytes)
    }
    
    private func encrypt(content: Content, with key: String? = nil) -> Data? {
        var publicKey = key
        if publicKey == nil {
            // Encrypt to Gaia using the app public key
            guard let privateKey = ProfileHelper.retrieveProfile()?.privateKey else {
                    return nil
            }
            publicKey = Keys.getPublicKeyFromPrivate(privateKey)
        }
        
        guard let recipientPublicKey = publicKey else {
            return nil
        }

        // Encrypt and serialize to JSON
        var cipherObjectJSON: String?
        switch content {
        case let .bytes(bytes):
            cipherObjectJSON = Encryption.encryptECIES(content: bytes, recipientPublicKey: recipientPublicKey, isString: false)
        case let .text(text):
            cipherObjectJSON = Encryption.encryptECIES(content: text, recipientPublicKey: recipientPublicKey)
        }
        
        guard let cipher = cipherObjectJSON else {
            return nil
        }
        return cipher.data(using: .utf8)
    }
    
    private func getFileContents(at path: String, multiplayerOptions: MultiplayerOptions?) -> Promise<(Data, String)> {
        let getReadURL = Promise<URL> { resolve, reject in
            if let options = multiplayerOptions {
                Blockstack.shared.getUserAppFileURL(at: path, username: options.username, appOrigin: options.app, zoneFileLookupURL: options.zoneFileLookupURL) {
                    guard let fetchURL = $0?.appendingPathComponent(path) else {
                        reject(GaiaError.requestError)
                        return
                    }
                    resolve(fetchURL)
                }
            } else {
                resolve(URL(string: "\(self.config.URLPrefix!)\(self.config.address!)/\(path)")!)
            }
        }
        return Promise<(Data, String)>() { resolve, reject in
            getReadURL.then({ url in
                let task = URLSession.shared.dataTask(with: url) { data, response, error in
                    guard error == nil,
                        let httpResponse = response as? HTTPURLResponse,
                        let data = data else {
                            print("Gaia hub store request error")
                            reject(GaiaError.requestError)
                            return
                    }
                    switch httpResponse.statusCode {
                    case 200:
                        let contentType = httpResponse.allHeaderFields["Content-Type"] as? String ?? "application/json"
                        resolve((data, contentType))
                    case 404:
                        reject(GaiaError.fileNotFoundError)
                    default:
                        reject(GaiaError.serverError)
                    }
                }
                task.resume()
            }).catch { error in
                reject(error)
            }
        }
    }

    private func getGaiaAddress(multiplayerOptions: MultiplayerOptions? = nil) -> Promise<String> {
        let parseUrl: (String) -> (String?) = { urlString in
            let pattern = Regex("([13][a-km-zA-HJ-NP-Z0-9]{26,35})")
            let matches = pattern.allMatches(in: urlString)
            return matches.last?.matchedString
        }
        return Promise<String>() { resolve, reject in
            guard let options = multiplayerOptions else {
                guard let prefix = self.config.URLPrefix,
                    let hubAddress = self.config.address,
                    let gaiaAddress = parseUrl("\(prefix)\(hubAddress)/") else {
                        reject(GaiaError.requestError)
                        return
                }
                resolve(gaiaAddress)
                return
            }
            Blockstack.shared.getUserAppFileURL(at: "/", username: options.username, appOrigin: options.app, zoneFileLookupURL: options.zoneFileLookupURL) {
                guard let readUrl = $0, let gaiaAddress = parseUrl(readUrl.absoluteString) else {
                    reject(GaiaError.requestError)
                    return
                }
                resolve(gaiaAddress)
            }
        }
    }
    
    private func deleteItem(at path: String) -> Promise<Void> {
        return Promise<Void>() { resolve, reject in
            guard let url = URL(string:"\(self.config.server!)/delete/\(self.config.address!)/\(path)") else {
                reject(GaiaError.configurationError)
                return
            }
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.addValue("bearer \(self.config.token!)", forHTTPHeaderField: "Authorization")
            let task = URLSession.shared.dataTask(with: request) { _, response, error in
                guard error == nil else {
                    print("Gaia hub store request error")
                    reject(GaiaError.requestError)
                    return
                }
                if let code = (response as? HTTPURLResponse)?.statusCode {
                    if code == 404 {
                        reject(GaiaError.fileNotFoundError)
                        return
                    } else if code < 200 || code > 299 {
                        reject(GaiaError.requestError)
                        return
                    }
                }
                resolve(())
            }
            task.resume()
        }
    }
    
    private func signAndPutData(to path: String, content: Data, originalContentType: String, encrypted: Bool, sign: Bool, signingKey: String?, completion: @escaping (String?, GaiaError?) -> ()) {
        if encrypted && !sign {
            self.upload(path: path, contentType: "application/json", data: content, completion: completion)
        } else if encrypted && sign {
            guard let privateKey = signingKey ?? Blockstack.shared.loadUserData()?.privateKey,
                let signatureObject = EllipticJS().signECDSA(privateKey: privateKey, content: content.bytes) else {
                    // Handle error
                    completion(nil, nil)
                    return
            }
            let signedCipherObject = SignatureObject(
                signature: signatureObject.signature,
                publicKey: signatureObject.publicKey,
                cipherText: String(data: content, encoding: .utf8))
            guard let jsonData = try?  JSONEncoder().encode(signedCipherObject) else {
                // Handle error
                completion(nil, nil)
                return
            }
            self.upload(path: path, contentType: "application/json", data: jsonData, completion: completion)
        }  else if !encrypted && sign {
            // If signing but not encryption, 2 uploads are needed
            guard let privateKey = signingKey ?? Blockstack.shared.loadUserData()?.privateKey,
                let signatureObject = EllipticJS().signECDSA(privateKey: privateKey, content: content.bytes),
                let jsonData = try?  JSONEncoder().encode(signatureObject) else {
                    // Handle error
                    completion(nil, nil)
                    return
            }
            self.upload(path: path, contentType: originalContentType, data: content) { fileURL, error in
                guard let url = fileURL, error == nil else {
                    completion(nil, error)
                    return
                }
                self.upload(path: "\(path)\(signatureFileSuffix)", contentType: "application/json", data: jsonData) { _, error in
                    guard error == nil else {
                        completion(nil, error)
                        return
                    }
                    completion(url, nil)
                }
            }
        } else {
            // Not encrypting or signing
            self.upload(path: path, contentType: originalContentType, data: content, completion: completion)
        }
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
                if let url = putfileResponse.publicURL {
                    completion(url, nil)
                } else {
                    completion(nil, GaiaError.invalidResponse)
                }
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
