//
//  EllipticJS.swift
//  Blockstack
//
//  Created by Shreyas Thiagaraj on 7/18/18.
//

import Foundation
import JavaScriptCore

open class EllipticJS {
    
    lazy var context: JSContext? = {
        let context = JSContext()
        
        let frameworkBundle = Bundle(for: type(of: self))
        let bundleURL = frameworkBundle.resourceURL?.appendingPathComponent("Blockstack.bundle")
        let resourceBundle = Bundle(url: bundleURL!)
        
        guard let
            JSPath = resourceBundle?.path(forResource: "elliptic", ofType: "js") else {
                print("Unable to read resource files.")
                return nil
        }

        do {
            let ellipticJS = try String(contentsOfFile: JSPath, encoding: String.Encoding.utf8)
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
    
    public func computeSecret(privateKey: String, publicKey: String) -> String? {
        guard let context = context else {
            print("JSContext not found.")
            return nil
        }
        context.evaluateScript("""
            function getHexFromBN(bnInput) {
              var hexOut = bnInput.toString('hex');

              if (hexOut.length === 64) {
                return hexOut;
              } else if (hexOut.length < 64) {
                // pad with leading zeros
                // the padStart function would require node 9
                var padding = '0'.repeat(64 - hexOut.length);
                return '' + padding + hexOut;
              } else {
                throw new Error('Generated a > 32-byte BN for encryption. Failing.');
              }
            }
        """)
        context.evaluateScript("""
            const curve = new ec('secp256k1');
            const ephemeralSK = curve.keyFromPrivate('\(privateKey)', 'hex');
            const ecPK = curve.keyFromPublic('\(publicKey)', 'hex').getPublic();
            const sharedSecretBN = ephemeralSK.derive(ecPK);
            """)
        let sharedSecretHex = context.evaluateScript("getHexFromBN(sharedSecretBN)")
        return sharedSecretHex?.toString()
    }
    
    public func getPublicKeyFromPrivate(_ privateKey: String, compressed: Bool) -> String? {
        guard let context = context else {
            print("JSContext not found.")
            return nil
        }
        context.evaluateScript("""
            const curve = new ec('secp256k1');
            const publicKey = curve.keyFromPrivate('\(privateKey)', 'hex').getPublic();
            """)
        let publicKeyJS = compressed ?
            context.evaluateScript("publicKey.encodeCompressed('hex')") :
            context.evaluateScript("publicKey.encode('hex')")
        return publicKeyJS?.toString()
    }

}

