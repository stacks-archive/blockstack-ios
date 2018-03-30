//
//  Keys.swift
//  Blockstack
//
//  Created by Yukan Liao on 2018-03-27.
//

import Foundation
import secp256k1

open class Keys {
    
    
    static func generateTransitKey() -> String? {
        
        return " "
//        let blockstackJS = BlockstackJS()
//        blockstackJS.generateECPrivateKey()
        
//        let seckey = makeECPrivateKey()
////        let b64Key: String?
//        let data: Data?
//
//        var error:Unmanaged<CFError>?
//        if let cfdata = SecKeyCopyExternalRepresentation(seckey!, &error) {
//            data = cfdata as Data
////            b64Key = data.base64EncodedString()
//        }
//
//        guard let b64Key = data!.base64EncodedString()! else { return nil }
//
//        return b64Key!
    }
    
    /**
     Generate an elliptic curve private key using the secp256r1 curve.
     
     */
    static func makeECPrivateKey() -> SecKey? {
        
//        let privateKey: String? = generateRandomBytes()
        
        var error: Unmanaged<CFError>?

        let attributes: [String: Any] =
            [kSecAttrKeySizeInBits as String:      256,
             kSecAttrKeyType as String: kSecAttrKeyTypeEC]

        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
//            throw error!.takeRetainedValue() as Error
            print(error!.takeRetainedValue())
            return nil
        }

//        let ctx = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN))
//        if ctx != nil {
//            print("Context created")
//        } else {
//            print("Context creation failed")
//        }
        
        
//        let valid = secp256k1_ec_seckey_verify(ctx!, privateKey!)
//        print(valid)
        

        return privateKey
    }
    
    static func generateRandomBytes() -> String? {
        
        var keyData = Data(count: 32)
        let result = keyData.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, keyData.count, $0)
        }
        if result == errSecSuccess {
            return keyData.base64EncodedString()
        } else {
            print("Problem generating random bytes")
            return nil
        }
    }
}
