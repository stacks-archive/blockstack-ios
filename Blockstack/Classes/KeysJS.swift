//
//  KeysJS.swift
//  Blockstack
//
//  Created by Yukan Liao on 2018-04-10.
//

import Foundation
import JavaScriptCore

open class KeysJS {
    
    lazy var context: JSContext? = {
        let context = JSContext()
        
        let frameworkBundle = Bundle(for: type(of: self))
        let bundleURL = frameworkBundle.resourceURL?.appendingPathComponent("Blockstack.bundle")
        let resourceBundle = Bundle(url: bundleURL!)
        
        guard let
            JSPath = resourceBundle?.path(forResource: "keys", ofType: "js") else {
                print("Unable to read resource files.")
                return nil
        }
        
        do {
            let keysJS = try String(contentsOfFile: JSPath, encoding: String.Encoding.utf8)
            _ = context?.evaluateScript(keysJS)
            
        } catch (let error) {
            print("Error while processing script file: \(error)")
        }
        
        
        
        guard let
            ellipticJSPath = resourceBundle?.path(forResource: "elliptic", ofType: "js") else {
                print(resourceBundle as Any)
                print("Unable to read resource files.")
                return nil
        }

        do {
            let ellipticJS = try String(contentsOfFile: ellipticJSPath, encoding: String.Encoding.utf8)
            _ = context?.evaluateScript(ellipticJS)

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
    
    public func getPublicKeyFromPrivate(_ privateKey: String) -> String? {
        guard let context = context else {
            print("JSContext not found.")
            return nil
        }
        
        let publicKey = context.evaluateScript("keys.getPublicKeyFromPrivate('\(privateKey)')")
        
        return publicKey!.toString()
    }
    
    public func getAddressFromPublicKey(_ publicKey: String) -> String? {
        guard let context = context else {
            print("JSContext not found.")
            return nil
        }
        
        let address = context.evaluateScript("keys.publicKeyToAddress('\(publicKey)')")
        
        return address!.toString()
    }
    
    public func computeSecret(privateKey: String, publicKey: String) -> String? {
        guard let context = context else {
            print("JSContext not found.")
            return nil
        }
        _ = context.evaluateScript("const curve = new ec('secp256k1')")
        let keyPair = context.evaluateScript("const keypair = curve.keyFromPrivate('931cb15872843dbc6e60f1ec9ac7b540320289a3bb68af85e62127d95129d6b2', 'hex')")
        _ = context.evaluateScript("console.log(keypair)")
//        let keyPair = context.evaluateScript("var sk = new keys.KeyPair({hello:'test'}, { priv:'\(privateKey)', privEnc:'hex'})")
        return nil

    }
}
