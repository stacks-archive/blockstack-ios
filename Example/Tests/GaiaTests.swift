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

class GaiaSpec: QuickSpec {
    
    struct User {
        var userID: String
        var privateKey: String
    }
    
    override func spec() {
        let bob = User(userID: "testing1234.id.blockstack", privateKey: "4c86d2821d7fc08d39035fd54d2a9849e59de826f44b528e6802c119d5c0a3e6")
        let mary = User(userID: "testing5678.id.blockstack", privateKey: "73d79d4833606b173ad44a6634fd07e621cfdd1ce9f30021c7536b13910edc18")

        describe("Gaia") {
            let fileName = "testFiles"
            // Clear file before each test
            beforeEach {
                Blockstack.shared.signOut()
                self.signIn(bob)
                waitUntil(timeout: 10) { done in
                    self.testUpload(fileName: fileName, content: .text(""), encrypt: false) { _ in
                        done()
                    }
                }
            }
            
            context("without encryption") {
                context("for text content") {
                    let textContent = "Testing123"
                    var wasUploaded = false
                    var result: String?
                    // MARK: - Gaia__without_encryption__for_text_content__can_upload_and_retrieve
                    it("can upload and retrieve") {
                        self.testUpload(fileName: fileName, content: .text(textContent), encrypt: false) { _ in
                            wasUploaded = true
                            self.testRetrieve(from: fileName, decrypt: false) { content in
                                result = content as? String
                            }
                        }
                        expect(wasUploaded).toEventually(beTrue(), timeout: 5, pollInterval: 1)
                        expect(result).toEventually(equal(textContent), timeout: 10, pollInterval: 1)
                    }
                }
                context("for bytes content") {
                    let bytesContent = "Testing123".bytes
                    var wasUploaded = false
                    var result: Bytes?
                    // MARK: - Gaia__without_encryption__for_bytes_content__can_upload_and_retrieve
                    it("can upload and retrieve") {
                        self.testUpload(fileName: fileName, content: .bytes(bytesContent), encrypt: false) { _ in
                            wasUploaded = true
                            self.testRetrieve(from: fileName, decrypt: false) { content in
                                result = content as? Bytes
                            }
                        }
                        expect(wasUploaded).toEventually(beTrue(), timeout: 5, pollInterval: 1)
                        expect(result).toEventually(equal(bytesContent), timeout: 10, pollInterval: 1)
                    }
                }
            }
            context("with encryption") {
                // MARK: - Gaia__with_encryption__can_upload_and_retrieve
                it("can upload and retrieve") {
                    let content = "Encrypted Testing Pass"
                    var result: String?
                    self.testUpload(fileName: fileName, content: .text(content), encrypt: true) { _ in
                        self.testRetrieve(from: fileName, decrypt: true) { content in
                            result = (content as? DecryptedValue)?.plainText
                        }
                    }
                    expect(result).toEventually(equal(content), timeout: 10, pollInterval: 1)
                }

                // MARK: - Gaia__with_encryption__fails_retrieve_without_decrypt
                it("fails retrieve without decrypt") {
                    let content = "Encrypted Testing Fail"
                    waitUntil(timeout: 10) { done in
                        self.testUpload(fileName: fileName, content: .text(content), encrypt: true) { url in
                            self.testRetrieve(from: url, decrypt: false) { response in
                                expect(response as? String).toNot(equal(content))
                                done()
                            }
                        }
                    }
                }
            }
            context("multiplayer") {
                // MARK: - Gaia__multiplayer__can_retrieve
                it ("can retrieve") {
                    let content = "Multiplayer Hello World"
                    var result: String?
                    self.testUpload(fileName: fileName, content: .text(content), encrypt: false) { url in
                        print("Uploaded URL: \(url)")
                        Blockstack.shared.signOut()
                        // Switch users
                        self.signIn(mary)
                        // Retrieve Bob's file
                        Blockstack.shared.getFile(at: fileName, username: bob.userID, app: "https://pedantic-mahavira-f15d04.netlify.com", zoneFileLookupURL: nil) {
                            response, error in
                            result = response as? String
                        }
                    }
                    expect(result).toEventually(equal(content), timeout: 10, pollInterval: 1)
                }
            }
        }
    }
    
    //  MARK: - Private
    
    private func signIn(_ user: User) {
        // TODO: Better way of getting an authenticated user context
        guard let jsonData = try? JSONEncoder().encode(["private_key": user.privateKey]),
            let userData = try? JSONDecoder().decode(Payload.self, from: jsonData),
            let propertyEncodedData = try? PropertyListEncoder().encode(userData) else {
                fail("Could not set up user account")
                return
        }
        UserDefaults.standard.set(propertyEncodedData, forKey: BlockstackConstants.ProfileUserDefaultLabel)
        
        // Ensure signed in
        expect(Blockstack.shared.isSignedIn()).to(beTrue())
    }
    
    enum Content {
        case text(String)
        case bytes(Bytes)
    }
    
    /// Convenience funtion to fail when presented with errors for putFile
    private func testUpload(fileName: String, content: Content, encrypt: Bool, completion: @escaping (String) -> ()) {
        let put: (Content, @escaping (String?, GaiaError?) -> ()) -> () = { content, callback in
            switch content {
            case let .text(text):
                Blockstack.shared.putFile(to: fileName, content: text, encrypt: encrypt, completion: callback)
            case let .bytes(bytes):
                Blockstack.shared.putFile(to: fileName, content: bytes, encrypt: encrypt, completion: callback)
            }
        }
        
        put(content) { publicURL, error in
            guard error == nil else {
                fail("putFile Error: \(error!)")
                return
            }
            guard let url = publicURL else {
                fail("Invalid public URL for uploaded file.")
                return
            }
            completion(url)
        }
    }
    
    /// Convenience funtion to fail when presented with errors for getFile
    private func testRetrieve(from url: String, decrypt: Bool, completion: @escaping (Any) -> () ) {
        Blockstack.shared.getFile(at: url, decrypt: decrypt) { response, error in
            guard error == nil else {
                fail("getFile Error: \(error!)")
                return
            }
            guard let content = response else {
                fail("Invalid content in retrieved file.")
                return
            }
            completion(content)
        }
    }
}

