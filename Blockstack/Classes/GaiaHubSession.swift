//
//  GaiaSession.swift
//  Blockstack
//
//  Created by Yukan Liao on 2018-04-19.
//

import Foundation

public class GaiaHubSession {
    let config: GaiaConfig

    init(with config: GaiaConfig) {
        self.config = config
    }

    func getFile(path: String, completion: @escaping (Any?, GaiaError?) -> Void) {
        let fullReadURLString = "\(self.config.URLPrefix!)\(self.config.address!)/\(path)"
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

    func putFile(path: String, content: Dictionary<String, Any?>, completion: @escaping (String?, GaiaError?) -> Void) {
        let contentType = "application/json"
        let stringContent = content.toJsonString()!

        print(stringContent as Any)
        
        self.upload(path: path,
                    content: stringContent,
                    contentType: contentType,
                    completion: completion)
    }

    // MARK: - Private

    private func upload(path: String, content: String, contentType: String, completion: @escaping (String?, GaiaError?) -> Void) {
        let putURL = URL(string:"\(self.config.server!)/store/\(self.config.address!)/\(path)")
        var request = URLRequest(url: putURL!)
        request.httpMethod = "POST"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue("bearer \(self.config.token!)", forHTTPHeaderField: "Authorization")
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
}

public struct GetFileOptions {
    let decrypt: Bool?
    let username: String?
    let app: String?
    let zoneFileLookupURL: URL?
}

public struct PutFileResponse: Codable {
    let publicURL: String?
}

public struct PutFileOptions {
    let encrypt: Bool?
}
