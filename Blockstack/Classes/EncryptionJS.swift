//
//  EncryptionJS.swift
//  Blockstack
//
//  Created by Yukan Liao on 2018-04-15.
//

import Foundation
import JavaScriptCore

open class EncryptionJS {
    
    lazy var context: JSContext? = {
        let context = JSContext()
        
        let frameworkBundle = Bundle(for: type(of: self))
        let bundleURL = frameworkBundle.resourceURL?.appendingPathComponent("Blockstack.bundle")
        let resourceBundle = Bundle(url: bundleURL!)
        
        guard let
            JSPath = resourceBundle?.path(forResource: "encryption", ofType: "js") else {
                print("Unable to read resource files.")
                return nil
        }
        
        do {
            let encryptionJS = try String(contentsOfFile: JSPath, encoding: String.Encoding.utf8)
            _ = context?.evaluateScript(encryptionJS)
            
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
                           forKeyedSubscript: "_consoleLog" as (NSCopying & NSObjectProtocol)!)
        
        return context
    }()
    
    public func encryptECIES(publicKey: String, content: String) -> [String: String]? {
        guard let context = context else {
            print("JSContext not found.")
            return nil
        }
        
        guard let ephemeralSK = Keys.makeECPrivateKey(), let ephemeralPK = Keys.getPublicKeyFromPrivate(ephemeralSK) else {
            return nil
        }
        Keys.deriveSharedSecret(ephemeralSecretKey: ephemeralSK, recipientPublicKey: ephemeralPK)
//        
//        
//        let getSharedSecretScript = """
//            // Get hex bob public key
//            var ecPK = ecurve.keyFromPublic(publicKey, 'hex').getPublic();
//            // Generate message key
//            var ephemeralSK = ecurve.genKeyPair();
//            // Get public version of message key
//            var ephemeralPK = ephemeralSK.getPublic();
//            // Get shared message secret from messagekey and bob public key
//            var sharedSecret = ephemeralSK.derive(ecPK);
//
//            // HEX the sharedsecret
//            var sharedSecretHex = getHexFromBN(sharedSecret);
//        """
//       
//        context.evaluateScript(getSharedSecretScript)
//        context.evaluateScript("_consoleLog(sharedSecretHex)")

        let encryptedContent = [String: String]()
        // Populate encryptedContent
        return encryptedContent
    }
    
    public func decryptECIES(privateKey: String, cipherObjectJSONString: String) -> String? {
        guard let context = context else {
            print("JSContext not found.")
            return nil
        }
        
        context.evaluateScript("var encryptedObj = JSON.parse('\(cipherObjectJSONString)')")
        let privateKey = context.evaluateScript("encryption.decryptECIES('\(privateKey)', encryptedObj)")
        
        return privateKey!.toString()
    }

}
