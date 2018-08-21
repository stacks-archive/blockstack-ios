//
//  Keys.swift
//  Blockstack
//
//  Created by Yukan Liao on 2018-03-27.
//

import Foundation

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
    
    /**
     Generate the transit private key
     TODO - Use Keychain for secure key storage
     */
    static func generateTransitKey() -> String? {
        let transitKey = makeECPrivateKey()
        
        storeKey(keyData: transitKey!, label: BlockstackConstants.TransitPrivateKeyUserDefaultLabel)
        
        return transitKey
//        print("storing transit key")
//        print(transitKey as Any)
        
//        let key = transitKey
//        let tag = "org.test.keys.appKey".data(using: .utf8)!
//        let addquery: [String: Any] = [kSecClass as String: kSecClassKey,
//                                       kSecAttrApplicationTag as String: tag,
//                                       kSecValueRef as String: key as Any]
//        let status = SecItemAdd(addquery as CFDictionary, nil)
//        guard status == errSecSuccess else {
//            print("ERROR STORING KEY")
//            print(status)
//            return nil
//        }
    }
    
    static func retrieveTransitKey() -> String? {
        return retrieveKey(label: BlockstackConstants.TransitPrivateKeyUserDefaultLabel)
        
//        let tag = "org.test.keys.appKey".data(using: .utf8)!
//        let getquery: [String: Any] = [kSecClass as String: kSecClassKey,
//                                       kSecAttrApplicationTag as String: tag,
//                                       kSecAttrKeyType as String: kSecAttrKeyTypeEC,
//                                       kSecReturnRef as String: true]
//
//        var item: CFTypeRef?
//        let status = SecItemCopyMatching(getquery as CFDictionary, &item)
//        guard status == errSecSuccess else {
//            print("ERROR RETRIEVING KEY")
//            return
//        }
//        let key = item as! SecKey
//        print("printing retrieved key")
//        print(key)
    }
    
    static func clearTransitKey() {
        return clearKeys(label: BlockstackConstants.TransitPrivateKeyUserDefaultLabel)
    }
    
    static func storeKey(keyData: String, label: String) {
        UserDefaults.standard.set(keyData, forKey: label)
    }
    
    static func retrieveKey(label: String) -> String? {
        return UserDefaults.standard.string(forKey: label)
    }
    
    static func clearKeys(label: String) {
        UserDefaults.standard.removeObject(forKey: label)
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
        
        return d?.toString(radix: 16, lowercase: true).paddingLeft(to: keyLength * 2, with: "0")
    }
    
    static func generateRandomBytes(bytes: Int = 32) -> String? {
        var randomData = Data(count: bytes)
        let count = randomData.count
        let result = randomData.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, count, $0)
        }
        if result == errSecSuccess {
            return randomData.hexEncodedString()
        } else {
            print("Problem generating random bytes")
            return nil
        }
    }
    
    open static func getPublicKeyFromPrivate(_ privateKey: String, compressed: Bool = false) -> String? {
        return EllipticJS().getPublicKeyFromPrivate(privateKey, compressed: compressed)
    }
    
    static func getAddressFromPublicKey(_ publicKey: String) -> String? {
        return KeysJS().getAddressFromPublicKey(publicKey)
    }
    
    static func deriveSharedSecret(ephemeralSecretKey: String, recipientPublicKey: String) -> String? {
        return EllipticJS().computeSecret(privateKey: ephemeralSecretKey, publicKey: recipientPublicKey)
    }
}
