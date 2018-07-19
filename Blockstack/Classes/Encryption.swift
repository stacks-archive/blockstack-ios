//
//  Encryption.swift
//  Blockstack
//
//  Created by Yukan Liao on 2018-04-15.
//

import Foundation
import CryptoSwift

public class Encryption {
    
    static func decryptPrivateKey(privateKey: String, hexedEncrypted: String) -> String? {
        let encryptedData = Data(fromHexEncodedString: hexedEncrypted)
        let cipherObjectJSONString = String(data: encryptedData!, encoding: .utf8)
        let encryptionJS = EncryptionJS()
        return encryptionJS.decryptECIES(privateKey: privateKey, cipherObjectJSONString: cipherObjectJSONString!)
    }
    
    // TODO: Support content type Any
    public static func encryptECIES(content: String, recipientPublicKey: String) -> String? {
        guard let ephemeralSK = Keys.makeECPrivateKey(),
            let sharedSecret = Keys.deriveSharedSecret(ephemeralSecretKey: ephemeralSK, recipientPublicKey: recipientPublicKey) else {
            return nil
        }
        let data = Array<UInt8>(hex: sharedSecret)
        let hashedSecretBytes = data.sha512()
        let encryptionKey = Array(hashedSecretBytes.prefix(32))
        let hmacKey = Array(hashedSecretBytes.suffix(from: 32))
        let initializationVector = AES.randomIV(16)
        do {
            let aes = try AES(key: encryptionKey, blockMode: CBC(iv: initializationVector))
            let cipherText = try aes.encrypt(Array(content.utf8))
            guard let compressedEphemeralPKHex = Keys.getPublicKeyFromPrivate(ephemeralSK, compressed: true) else {
                return nil
            }
            let compressedEphemeralPKBytes = Array<UInt8>(hex: compressedEphemeralPKHex)
            let macData = initializationVector + compressedEphemeralPKBytes + cipherText
            let mac = try HMAC(key: hmacKey, variant: .sha256).authenticate(macData)
            let cipherObject: [String: Any?] = [
                "iv": initializationVector.toHexString(),
                "ephemeralPK": compressedEphemeralPKHex,
                "cipherText": cipherText.toHexString(),
                "mac": mac.toHexString(),
                "wasString": content is String
            ]
            return cipherObject.toJsonString()
        } catch {
            // TODO
        }
        return nil
    }
    
    public static func decryptECIES(privateKey: String, cipherObjectJSONString: String) -> String? {
        return EncryptionJS().decryptECIES(privateKey: privateKey, cipherObjectJSONString: cipherObjectJSONString)
    }
}
