//
//  EncryptionTests.swift
//  Blockstack_Example
//
//  Created by Shreyas Thiagaraj on 7/30/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Quick
import Nimble
import Blockstack

class EncryptionSpec : QuickSpec {
    override func spec() {
        describe("Encryption") {
            // secp256k1 key pair
            let privateKey = "a25629673b468789f8cbf84e24a6b9d97a97c5e12cf3796001dde2927021cdaf"
            let publicKey = "04fdfa9031f9ac7b856bf539c0d315a4847c7e2b0b7dd22b40e8da9ee2beaa228acec7cad39526308bd7ab4af9e738203fdc6547a2108324c28874990e86534dc4"
            
            context("with text") {
                let content = "all work and no play makes jack a dull boy"
                let cipherText = Encryption.encryptECIES(recipientPublicKey: publicKey, content: content)
                it("can encrypt") {
                    expect(cipherText).toNot(beNil())
                }
                it("can decrypt") {
                    guard let cipher = cipherText else {
                        fail("Invalid cipherText")
                        return
                    }
                    guard let plainText = Encryption.decryptECIES(privateKey: privateKey, cipherObjectJSONString: cipher)?.plainText else {
                        fail()
                        return
                    }
                    expect(plainText) == content
                }
            }
            
            context("with bytes") {
                let data = Data(bytes: [0x01, 0x02, 0x03])
                let cipherText = Encryption.encryptECIES(recipientPublicKey: publicKey, content: data.bytes, isString: false)
                
                it("can encrypt") {
                    expect(cipherText).toNot(beNil())
                }
                
                it("can decrypt") {
                    guard let cipher = cipherText else {
                        fail("Invalid cipherText")
                        return
                    }
                    guard let bytes = Encryption.decryptECIES(privateKey: privateKey, cipherObjectJSONString: cipher)?.bytes else {
                        fail()
                        return
                    }
                    expect(Data(bytes: bytes)) == data
                }
            }
            
            context("with bad HMAC") {
                let goodContent = "all work and no play makes jack a dull boy"
                let badContent = "some work and no play makes jack a dull boy"
                
                guard let goodCipher = Encryption.encryptECIES(recipientPublicKey: publicKey, content: goodContent),
                    let badCipher = Encryption.encryptECIES(recipientPublicKey: publicKey, content: badContent) else {
                        fail("Encryption failed")
                        return
                }
                
                guard let goodData = goodCipher.data(using: .utf8),
                    let goodCipherJSON = try? JSONSerialization.jsonObject(with: goodData, options: []),
                    var goodCipherObject = goodCipherJSON as? [String: Any],
                    let badData = badCipher.data(using: .utf8),
                    let badCipherJSON = try? JSONSerialization.jsonObject(with: badData, options: []),
                    let badCipherObject = badCipherJSON as? [String: Any] else {
                        fail("Could not deserialize JSON cipher text")
                        return
                }

                let badCipherText = badCipherObject["cipherText"] as? String
                goodCipherObject["cipherText"] = badCipherText
                guard let jsonData = try? JSONSerialization.data(withJSONObject: goodCipherObject, options: []),
                    let corruptedCipherContent = String(data: jsonData, encoding: String.Encoding.utf8) else {
                    fail("Could not serialize cipher text to JSON")
                    return
                }
                
                it("will fail") {
                    let decryptedContent = Encryption.decryptECIES(privateKey: privateKey, cipherObjectJSONString: corruptedCipherContent)
                    expect(decryptedContent).to(beNil())
                }
            }
            
            // TODO: Test signIn
            // TODO: Test loadUserData
            // TODO: Test signOut
            // TODO: Test putFile
            // TODO: Test getFile
        }
    }
}
