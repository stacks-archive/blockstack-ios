//
//  BlockstackJS.swift
//  Blockstack
//
//  Created by Yukan Liao on 2018-03-29.
//

import Foundation
import JavaScriptCore

open class BlockstackJS {
    
    lazy var context: JSContext? = {
        let context = JSContext()
        
        let frameworkBundle = Bundle(for: type(of: self))
        let bundleURL = frameworkBundle.resourceURL?.appendingPathComponent("Blockstack.bundle")
        let resourceBundle = Bundle(url: bundleURL!)
        
        guard let
            JSONTokenJSPath = resourceBundle?.path(forResource: "blockstack", ofType: "js") else {
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
        
        context?.evaluateScript("var console = { log: function(message) { _consoleLog(message) } }")
        
        let consoleLog: @convention(block) (String) -> Void = { message in
            print("console.log: " + message)
        }
        
        context?.setObject(unsafeBitCast(consoleLog, to: AnyObject.self),
                           forKeyedSubscript: "_consoleLog" as (NSCopying & NSObjectProtocol)!)
        
//        let cryptoShim: @convention(block) (String) -> Bool = { input in
//        let cryptoShim: @convention(block) () -> [String: Any] = {
//            return [
//                "getRandomBytes": self.randomValuesShim,
//                "getRandomValues": self.randomValuesShim,
//            ]
//        }
//        context?.setObject(cryptoShim, forKeyedSubscript: "crypto" as NSString)

        return context
    }()
    
    init() {
    }
    
    public func randomValuesShim() -> String {
        return Keys.generateRandomBytes()!
    }
    
    public func generateECPrivateKey() {
        guard let context = context else {
            print("JSContext not found.")
            return
        }
        
        let token: JSValue = context.evaluateScript("blockstack.makeECPrivateKey()")
        print(token.toString())
    }
}
