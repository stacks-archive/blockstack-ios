//
//  JSONToken.swift
//  Blockstack
//
//  Created by Yukan Liao on 2018-03-28.
//

import Foundation
import JavaScriptCore

open class JSONTokens {
    
    var algorithm: String?
    var privateKey: String?
    
    lazy var context: JSContext? = {
        let context = JSContext()

        let frameworkBundle = Bundle(for: type(of: self))
        let bundleURL = frameworkBundle.resourceURL?.appendingPathComponent("Blockstack.bundle")
        let resourceBundle = Bundle(url: bundleURL!)
        
        guard let
            JSONTokenJSPath = resourceBundle?.path(forResource: "jsontokens", ofType: "js") else {
                print("Unable to read resource files.")
                return nil
        }

        do {
            let testJS = try String(contentsOfFile: JSONTokenJSPath, encoding: String.Encoding.utf8)
            _ = context?.evaluateScript(testJS)

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
    
    init(algorithm: String, privateKey: String) {
        self.algorithm = algorithm
        self.privateKey = privateKey
    }
    
    public func signToken(payload: [String: Any]) -> String? {
        guard let context = context else {
            print("JSContext not found.")
            return nil
        }
        
        context.setObject(payload, forKeyedSubscript: "jsonTokenPayload" as NSCopying & NSObjectProtocol)
        context.evaluateScript("var tokenSigner = new jsontokens.TokenSigner('ES256K', '\(privateKey!)')")
        let token: JSValue = context.evaluateScript("tokenSigner.sign(jsonTokenPayload)")
        return token.toString()
    }
    
    public func decodeToken(token: String) -> String? {
        guard let context = context else {
            print("JSContext not found.")
            return nil
        }
        
        context.evaluateScript("var decodedToken = jsontokens.decodeToken('\(token)')")
        let decodedTokenJsonString: JSValue = context.evaluateScript("JSON.stringify(decodedToken)")
        let jsonData = decodedTokenJsonString.toString()
        
        return jsonData
    }
    
}
