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
                let cipherText = Blockstack.shared.encryptContent(text: content, publicKey: publicKey)
                it("can encrypt") {
                    expect(cipherText).toNot(beNil())
                }
                it("can decrypt") {
                    guard let cipher = cipherText else {
                        fail("Invalid cipherText")
                        return
                    }
                    guard let plainText = Blockstack.shared.decryptContent(content: cipher, privateKey: privateKey)?.plainText else {
                        fail()
                        return
                    }
                    expect(plainText) == content
                }
            }
            
            context("with bytes") {
                let data = Data(bytes: [0x01, 0x02, 0x03])
                let cipherText = Blockstack.shared.encryptContent(bytes: data.bytes, publicKey: publicKey)
                it("can encrypt") {
                    expect(cipherText).toNot(beNil())
                }
                
                it("can decrypt") {
                    guard let cipher = cipherText else {
                        fail("Invalid cipherText")
                        return
                    }
                    guard let bytes = Blockstack.shared.decryptContent(content: cipher, privateKey: privateKey)?.bytes else {
                        fail()
                        return
                    }
                    expect(Data(bytes: bytes)) == data
                }
            }
            
            context("with bad HMAC") {
                var goodCipherObject: [String: Any] =
                    ["iv": "62ebe31b41a5a79d7d80aec2ea8b5738",
                     "ephemeralPK": "0292b08fad355531ab867632dfa688af47c77a94732869783a749bcd159dd8a7d1",
                     "cipherText": "f5def102dae9d2b97d5230fb7ef77f1702ea69612e899cb238fdfc708a738aa7e4e40538558a859a89b80ba3188665e8",
                     "mac": "c2cf1e8d2765bde5978de5d323f56f7d22dd2ade9528df9f67640bae9dfe62c5",
                     "wasString": true]
                
                var evilCipherObject: [String: Any] =
                    ["iv": "8bc9d481a9c81f9654d3daf5629db205",
                     "ephemeralPK": "03a310890362fc143291a9b46eaa8ff77882441926de7e8ef5459654dd02b8654f",
                     "cipherText": "a6791f244a6120a4ace2b8e5acd8fd75553cace042a2adadfcb3a20a95aae7b308174de017247ccf5eb4ae8e49bcb4e8",
                     "mac": "99462eb405f8cc51886571b718acf5a914ac2832be5ba34569726ab720f8ea62",
                     "wasString": true]

                let canDecrypt: ([String: Any]) -> Bool = { cipherObject in
                    guard let cipherData = try? JSONSerialization.data(withJSONObject: cipherObject, options: []),
                        let cipherJSON = String(data: cipherData, encoding: String.Encoding.utf8),
                        let _ = Blockstack.shared.decryptContent(content: cipherJSON, privateKey: privateKey)?.plainText else {
                            return false
                    }
                    return true
                }
                
                guard canDecrypt(goodCipherObject), canDecrypt(evilCipherObject) else {
                    fail("Bad input cipher object")
                    return
                }

                // Replace cipherText, keep mac the same
                goodCipherObject["cipherText"] = evilCipherObject["cipherText"]

                guard let jsonData = try? JSONSerialization.data(withJSONObject: goodCipherObject, options: []),
                    let corruptedCipherContent = String(data: jsonData, encoding: String.Encoding.utf8) else {
                    fail("Could not serialize manipulated cipher object to JSON")
                    return
                }
                
                it("will fail") {
                    let decryptedContent = Blockstack.shared.decryptContent(content: corruptedCipherContent, privateKey: privateKey)
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
