//
//  ProfileProofsJS.swift
//  Blockstack
//
//  Created by Shreyas Thiagaraj on 10/11/18.
//

import Foundation
import JavaScriptCore

open class ProfileProofsJS {
    
    lazy var context: JSContext? = {
        let context = JSContext()
        
        let frameworkBundle = Bundle(for: type(of: self))
        let bundleURL = frameworkBundle.resourceURL?.appendingPathComponent("Blockstack.bundle")
        let resourceBundle = Bundle(url: bundleURL!)
        
        guard let
            JSPath = resourceBundle?.path(forResource: "profileProofs", ofType: "js") else {
                print("Unable to read resource files.")
                return nil
        }
        
        do {
            let profileProofsJS = try String(contentsOfFile: JSPath, encoding: String.Encoding.utf8)
            let value = context?.evaluateScript(profileProofsJS)
            
        } catch (let error) {
            print("Error while processing script file: \(error)")
        }
        
        context?.exceptionHandler = {(context: JSContext?, exception: JSValue?) -> Void in
            print(exception!.toString())
        }
        
        _ = context?.evaluateScript("var console = { log: function(message) { _consoleLog(message) } }")
        
        let consoleLog: @convention(block) (String) -> Void = { message in
            print("console.log: " + message)
        }
        
        context?.setObject(unsafeBitCast(consoleLog, to: AnyObject.self),
                           forKeyedSubscript: "_consoleLog" as NSCopying & NSObjectProtocol)
        return context
    }()

    public func validateProofs(profile: String, ownerAddress: String?, name: String?, completion: @escaping (([ExternalAccountProof]?) -> ())) {
        guard let context = self.context else {
            print("JSContext not found.")
            return
        }
        
        guard ownerAddress != nil || name != nil else {
            print("Either owner address or name must be specified!")
            return
        }

        let nativeFetch: @convention(block) (JSValue?, JSValue?, JSValue?) -> () = { resolve, reject, jsURL in
            guard let urlString = jsURL?.toString(),
                let url = URL(string: urlString) else {
                    return
            }
            URLSession.shared.dataTask(with: url) { data, response, error in
                guard let data = data, error == nil else {
                    if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                        _ = resolve?.call(withArguments: [
                            ResponseJS(text: nil, status: statusCode)
                            ])
                    } else {
                        _ = reject?.call(withArguments: [
                            JSValue(newErrorFromMessage: "Network request failed", in: context)
                            ])
                    }
                    return
                }
                let text = String(data: data, encoding: .utf8)
                _ = resolve?.call(withArguments: [
                    ResponseJS(text: text, status: 200)
                    ])
                }.resume()
        }
        context.setObject(unsafeBitCast(nativeFetch, to: AnyObject.self), forKeyedSubscript: "nativeFetch" as NSCopying & NSObjectProtocol)
        context.evaluateScript("""
            var fetch = function(input, init) {
                return new Promise(function(resolve, reject) {
                    nativeFetch(resolve, reject, input);
                })
            };
        """)
        
        // Setup callback for
        let callback: @convention(block) (JSValue?) -> () = { proofs in
            guard let proofs = proofs?.toArray(),
                let data = try? JSONSerialization.data(withJSONObject: proofs, options: []),
                let accountProofs = try? JSONDecoder().decode([ExternalAccountProof].self, from: data) else {
                    return
            }
            completion(accountProofs)
        }
        context.setObject(unsafeBitCast(callback, to: AnyObject.self), forKeyedSubscript: "callback" as NSCopying & NSObjectProtocol)
        
        var arguments: String
        if let address = ownerAddress {
            arguments = "JSON.parse('\(profile)'),'\(address)'"
        } else {
            arguments = "JSON.parse('\(profile)'),'\(String(describing: ownerAddress))','\(name!)'"
        }
        // Handle JS promise by calling back to Swift
        context.evaluateScript("""
            var promise = profileProofs.validateProofs(\(arguments));
            promise
                .then(function(proofs) {
                    callback(proofs);
                })
                .catch(function() {
                    _consoleLog('Error: Could not validate proofs.');
                    callback([]);
                });
        """)
    }
}

@objc protocol ResponseJSProtocol: JSExport {
    var status: NSNumber? { get set }
    
    func text() -> String?
}

class ResponseJS: NSObject, ResponseJSProtocol {
    @objc dynamic var status: NSNumber?
    @objc dynamic private var bodyText: String?

    init (text: String?, status: Int?) {
        self.bodyText = text
        self.status = status == nil ? nil : NSNumber(integerLiteral: status!)
    }
    
    func text() -> String? {
        return self.bodyText
    }
}
