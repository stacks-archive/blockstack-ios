//
//  Keys.swift
//  Blockstack
//
//  Created by Yukan Liao on 2018-03-27.
//

import Foundation
import secp256k1

enum secp256k1Curve {
    static let p = "fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f"
    static let a = "00"
    static let b = "07"
    static let n = "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141"
    static let h = "01"
    static let Gx = "79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798"
    static let Gy = "483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8"
}

open class Keys {
    
    static func generateTransitKey() -> String? {
        return makeECPrivateKey()
    }
    
    /**
     Generate an elliptic curve private key for secp256k1.
     */
    static func makeECPrivateKey() -> String? {
        let keyLength = 32
        let n = secp256k1Curve.n
        let nBigInt = _BigInt<UInt>(n, radix: 16)
//        print("n")
//        print(nBigInt?.toString() as Any)
        
        var d: _BigInt<UInt>?
        
        repeat {
            let randomBytes = generateRandomBytes()
//            print(randomBytes!)
            d = _BigInt<UInt>(randomBytes!, radix: 16)
//            print("d")
//            print(d?.toString() as Any)
        } while (d!.isNegative
            || d!.isZero
            || d?._compare(to: nBigInt!) == .equal
            || d?._compare(to: nBigInt!) == .greaterThan)
        
        return d?.toString(radix: 16, lowercase: true).leftPadding(toLength: keyLength*2, withPad: "0")
    }
    
    static func generateRandomBytes(bytes: Int = 32) -> String? {
        var randomData = Data(count: bytes)
        let result = randomData.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, randomData.count, $0)
        }
        if result == errSecSuccess {
            return randomData.hexEncodedString()
        } else {
            print("Problem generating random bytes")
            return nil
        }
    }
    
    static func getPublicKeyFromPrivate(_ privateKey: String) -> String? {
        let keysJS = KeysJS()
        return keysJS.getPublicKeyFromPrivate(privateKey)
    }
    
    static func getAddressFromPublicKey(_ publicKey: String) -> String? {
        let keysJS = KeysJS()
        return keysJS.getAddressFromPublicKey(publicKey)
    }

}
