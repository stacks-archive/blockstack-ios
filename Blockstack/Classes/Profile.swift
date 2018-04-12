//
//  Profile.swift
//  Blockstack
//
//  Created by Yukan Liao on 2018-04-11.
//

import Foundation

open class Profile {
    static func fetchProfile(profileURL: URL, completion: @escaping ([String: Any]?, Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: profileURL) { data, response, error in
            guard let data = data, error == nil else {
                print("error ")
                return
            }
            
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: data, options: [.mutableContainers]) as? [Any]
                if let profile = jsonObject?[0] as? [String: Any] {
                    completion(profile, nil)
                } else {
                    completion(nil, nil)
                }
                
            } catch {
                completion(nil, error)
            }
            
        }
        task.resume()
    }
}
