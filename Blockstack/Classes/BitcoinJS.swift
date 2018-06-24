//
//  BitcoinJS.swift
//  Blockstack
//
//  Created by Yukan Liao on 2018-04-18.
//

import Foundation
import JavaScriptCore

open class BitcoinJS {
    
    lazy var context: JSContext? = {
        let context = JSContext()
        
        let frameworkBundle = Bundle(for: type(of: self))
        let bundleURL = frameworkBundle.resourceURL?.appendingPathComponent("Blockstack.bundle")
        let resourceBundle = Bundle(url: bundleURL!)
        
        // bitcoinjs
        guard let
            JSPath = resourceBundle?.path(forResource: "bitcoinjs", ofType: "js") else {
                print("Unable to read resource files.")
                return nil
        }
        
        do {
            let bitcoinJS = try String(contentsOfFile: JSPath, encoding: String.Encoding.utf8)
            _ = context?.evaluateScript(bitcoinJS)
            
        } catch (let error) {
            print("Error while processing script file: \(error)")
        }
        
        // bigi
        guard let
            bigiJSPath = resourceBundle?.path(forResource: "bigi", ofType: "js") else {
                print("Unable to read resource files.")
                return nil
        }
        
        do {
            let bigiJS = try String(contentsOfFile: bigiJSPath, encoding: String.Encoding.utf8)
            _ = context?.evaluateScript(bigiJS)
            
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
    
    init() {
    }
    
    public func signChallenge(privateKey: String, challengeText: String) -> String? {
        guard let context = context else {
            print("JSContext not found.")
            return nil
        }
        
        _ = context.evaluateScript("var d = bigi.fromHex('\(privateKey)')")
        _ = context.evaluateScript("var challengeSigner = new bitcoinjs.ECPair(d)")
        _ = context.evaluateScript("var digest = bitcoinjs.crypto.sha256('\(challengeText)')")
        let signature = context.evaluateScript("challengeSigner.sign(digest).toDER().toString('hex')")
        return signature?.toString()
    }
    
    
}
