//
//  Encryption.swift
//  Blockstack
//
//  Created by Yukan Liao on 2018-04-15.
//

import Foundation

public class Encryption {
    
    static func decryptPrivateKey(privateKey: String, hexedEncrypted: String) -> String? {
        let encryptedData = Data(fromHexEncodedString: hexedEncrypted)
        let cipherObjectJSONString = String(data: encryptedData!, encoding: .utf8)
        let encryptionJS = EncryptionJS()
        return encryptionJS.decryptECIES(privateKey: privateKey, cipherObjectJSONString: cipherObjectJSONString!)
    }
    
    public static func encryptECIES(content: String, recipientPublicKey: String) -> [String: String]? {
        
        guard let ephemeralSK = Keys.makeECPrivateKey(),
            let ephemeralPK = Keys.getPublicKeyFromPrivate(ephemeralSK),
            let sharedSecret = Keys.deriveSharedSecret(ephemeralSecretKey: ephemeralSK, recipientPublicKey: ephemeralPK) else {
            return nil
        }
        
        print(sharedSecret)
        
        
        let encryptedContent = [String: String]()
        // Populate encryptedContent
        return encryptedContent
    }
}

