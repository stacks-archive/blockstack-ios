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

fileprivate let filename = "testFile"

class GaiaSpec: QuickSpec {
    
    struct User {
        var userID: String
        var privateKey: String
    }
    
    override func spec() {
        let bob = User(userID: "testing1234.id.blockstack", privateKey: "4c86d2821d7fc08d39035fd54d2a9849e59de826f44b528e6802c119d5c0a3e6")
        let mary = User(userID: "testing5678.id.blockstack", privateKey: "73d79d4833606b173ad44a6634fd07e621cfdd1ce9f30021c7536b13910edc18")

        describe("Gaia") {
            // Clear file before each test
            beforeEach {
                Blockstack.shared.signUserOut()
                self.signIn(bob)
                waitUntil(timeout: 10) { done in
                    self.testUpload(filename: filename, content: .text(""), encrypt: false) { _ in
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
                        self.testUpload(filename: filename, content: .text(textContent), encrypt: false) { _ in
                            wasUploaded = true
                            self.testRetrieve(from: filename, decrypt: false) { content in
                                result = content as? String
                            }
                        }
                        expect(wasUploaded).toEventually(beTrue(), timeout: 10, pollInterval: 1)
                        expect(result).toEventually(equal(textContent), timeout: 20, pollInterval: 1)
                    }
                }
                context("for bytes content") {
                    let bytesContent = "Testing123".bytes
                    var wasUploaded = false
                    var result: Bytes?
                    // MARK: - Gaia__without_encryption__for_bytes_content__can_upload_and_retrieve
                    it("can upload and retrieve") {
                        self.testUpload(filename: filename, content: .bytes(bytesContent), encrypt: false) { _ in
                            wasUploaded = true
                            self.testRetrieve(from: filename, decrypt: false) { content in
                                result = content as? Bytes
                            }
                        }
                        expect(wasUploaded).toEventually(beTrue(), timeout: 10, pollInterval: 1)
                        expect(result).toEventually(equal(bytesContent), timeout: 20, pollInterval: 1)
                    }
                }
            }
            context("with encryption") {
                // MARK: - Gaia__with_encryption__can_upload_and_retrieve
                it("can upload and retrieve") {
                    let content = "Encrypted Testing Pass"
                    var result: String?
                    self.testUpload(filename: filename, content: .text(content), encrypt: true) { _ in
                        self.testRetrieve(from: filename, decrypt: true) { content in
                            result = (content as? DecryptedValue)?.plainText
                        }
                    }
                    expect(result).toEventually(equal(content), timeout: 10, pollInterval: 1)
                }

                // MARK: - Gaia__with_encryption__fails_retrieve_without_decrypt
                it("fails retrieve without decrypt") {
                    let content = "Encrypted Testing Fail"
                    waitUntil(timeout: 10) { done in
                        self.testUpload(filename: filename, content: .text(content), encrypt: true) { _ in
                            self.testRetrieve(from: filename, decrypt: false) { response in
                                expect(response as? String).toNot(equal(content))
                                done()
                            }
                        }
                    }
                }
                
                it ("can delete") {
                    let content = "Testing123"
                    waitUntil(timeout: 20) { done in
                        self.testUpload(filename: filename, content: .text(content), encrypt: true, sign: false) { _ in
                            Blockstack.shared.deleteFile(at: filename) { error in
                                guard error == nil else {
                                    fail()
                                    return
                                }
                                // If it was really deleted, this should fail.
                                self.testRetrieve(from: filename, decrypt: true, verify: false) { response in
                                    expect(response as? String).to(beNil())
                                }
                            }
                        }
                    }
                }
            }
            
            context("signing") {
                it ("can sign and verify without encryption") {
                    let content = "Testing123"
                    waitUntil(timeout: 10) { done in
                        self.testUpload(filename: filename, content: .text(content), encrypt: false, sign: true) { _ in
                            self.testRetrieve(from: filename, decrypt: false, verify: true) { response in
                                expect(response as? String).to(equal(content))
                                done()
                            }
                        }
                    }
                }
                it ("can sign and verify with encryption") {
                    let content = "Testing123"
                    waitUntil(timeout: 10) { done in
                        self.testUpload(filename: filename, content: .text(content), encrypt: true, sign: true) { _ in
                            self.testRetrieve(from: filename, decrypt: true, verify: true) { response in
                                let result = (response as? DecryptedValue)?.plainText
                                expect(result).to(equal(content))
                                done()
                            }
                        }
                    }
                }
                it ("can sign and verify with multiplayer") {
                    let content = "Testing123"
                    var result: String?
                    self.testUpload(filename: filename, content: .text(content), encrypt: false, sign: true) { url in
                        Blockstack.shared.signUserOut()
                        // Switch users
                        self.signIn(mary)
                        // Retrieve Bob's file
                        Blockstack.shared.getFile(at: filename, verify: true, username: bob.userID, app: "https://pedantic-mahavira-f15d04.netlify.com") {
                            response, _ in
                            result = response as? String
                        }
                    }
                    expect(result).toEventually(equal(content), timeout: 20, pollInterval: 1)
                }
                it ("can sign and delete") {
                    let content = "Testing123"
                    waitUntil(timeout: 20) { done in
                        self.testUpload(filename: filename, content: .text(content), encrypt: false, sign: true) { _ in
                            Blockstack.shared.deleteFile(at: filename) { error in
                                guard error == nil else {
                                    fail()
                                    return
                                }
                                // The signature file should be deleted as well.
                                self.testRetrieve(from: "\(filename).sig)", decrypt: false, verify: false) { response in
                                    expect(response as? String).to(beNil())
                                }
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
                    self.testUpload(filename: filename, content: .text(content), encrypt: false) { url in
                        Blockstack.shared.signUserOut()
                        // Switch users
                        self.signIn(mary)
                        // Retrieve Bob's file
                        Blockstack.shared.getFile(at: filename, username: bob.userID, app: "https://pedantic-mahavira-f15d04.netlify.com") {
                            response, _ in
                            result = response as? String
                        }
                    }
                    expect(result).toEventually(equal(content), timeout: 20, pollInterval: 1)
                }
            }
            context("with invalid config") {
                // MARK: - Gaia__with_invalid_config__retries_upload
                it ("retries upload") {
                    // Get previous gaia config
                    guard let data = UserDefaults.standard.value(forKey:
                        BlockstackConstants.GaiaHubConfigUserDefaultLabel) as? Data,
                        let config = try? PropertyListDecoder().decode(GaiaConfig.self, from: data) else {
                            fail()
                            return
                    }

                    // Create invalid config
                    let invalidConfig = GaiaConfig(URLPrefix: config.URLPrefix, address: config.address, token: "v1:invalidated", server: config.server)

                    // Save invalid gaia config
                    Blockstack.shared.clearGaiaSession()
                    if let encodedInvalidConfig = try? PropertyListEncoder().encode(invalidConfig) {
                        UserDefaults.standard.set(encodedInvalidConfig, forKey: BlockstackConstants.GaiaHubConfigUserDefaultLabel)
                    }

                    let content = "Testing upload"
                    var url: String?
                    self.testUpload(filename: filename, content: .text(content), encrypt: false) { result in
                        url = result
                    }
                    expect(url).toEventuallyNot(beNil(), timeout: 10, pollInterval: 1)
                }
            }
            context("hub info") {
                it("can retrieve app storage bucket URL") {
                    var bucketUrl: String? = nil
                    Blockstack.shared.getAppBucketUrl(gaiaHubURL: URL(string: "https://hub.blockstack.org")!, appPrivateKey: bob.privateKey) {
                        bucketUrl = $0
                    }
                    expect(bucketUrl).toEventually(equal("https://gaia.blockstack.org/hub/1Fgr2UhX4rZntKuGALJhR2c51LDMNDsrfq/"), timeout: 10, pollInterval: 1)
                }
            }
            context("list files") {
                it("does encounter specific file") {
                    var fileFound = false
                    Blockstack.shared.listFiles(callback: {
                        if $0 == filename {
                            fileFound = true
                            return false
                        }
                        return true
                    }, completion: { fileCount, error in
                        expect(error).to(beNil())
                    })
                    expect(fileFound).toEventually(beTrue(), timeout: 10, pollInterval: 1)
                }
            }
        }
    }
    
    //  MARK: - Private
    
    private func signIn(_ user: User) {
        // TODO: Better way of getting an authenticated user context
        guard let jsonData = try? JSONEncoder().encode(["private_key": user.privateKey]),
            let userData = try? JSONDecoder().decode(UserData.self, from: jsonData),
            let propertyEncodedData = try? PropertyListEncoder().encode(userData) else {
                fail("Could not set up user account")
                return
        }
        UserDefaults.standard.set(propertyEncodedData, forKey: BlockstackConstants.ProfileUserDefaultLabel)
        
        // Ensure signed in
        expect(Blockstack.shared.isUserSignedIn()).to(beTrue())
    }
    
    enum Content {
        case text(String)
        case bytes(Bytes)
    }
    
    /// Convenience funtion to fail when presented with errors for putFile
    private func testUpload(filename: String, content: Content, encrypt: Bool, sign: Bool = false, completion: @escaping (String) -> ()) {
        let put: (Content, @escaping (String?, Error?) -> ()) -> () = { content, callback in
            switch content {
            case let .text(text):
                Blockstack.shared.putFile(to: filename, text: text, encrypt: encrypt, sign: sign, completion: callback)
            case let .bytes(bytes):
                Blockstack.shared.putFile(to: filename, bytes: bytes, encrypt: encrypt, sign: sign, completion: callback)
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
    private func testRetrieve(from url: String, decrypt: Bool, verify: Bool = false, completion: @escaping (Any) -> () ) {
        Blockstack.shared.getFile(at: url, decrypt: decrypt, verify: verify) { response, error in
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

