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

    static func encryptPrivateKey(publicKey: String, privateKey: String) -> String? {
        let encryptionJS = EncryptionJS()
        return encryptionJS.encryptECIES(publicKey: publicKey, content:privateKey)
    }
}

