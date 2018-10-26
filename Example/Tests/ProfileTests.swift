//
//  ProfileTests.swift
//  Blockstack_Example
//
//  Created by Shreyas Thiagaraj on 9/17/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Quick
import Nimble
import Blockstack

class ProfileSpec: QuickSpec {
    override func spec() {
        
        // For user testing1234.id.blockstack
        let profileToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJFUzI1NksifQ.eyJqdGkiOiI2OGExZjZiMy1hNmZlLTQ1ZWEtYTY0OC0xM2JmZDQ1NjMwYjQiLCJpYXQiOiIyMDE4LTEwLTIyVDEyOjM3OjIyLjg5NFoiLCJleHAiOiIyMDE5LTEwLTIyVDEyOjM3OjIyLjg5NFoiLCJzdWJqZWN0Ijp7InB1YmxpY0tleSI6IjAzNjRmYmE0ZDIzZDY0ZTNhMWUxZDJmYjQwZDU4YjMwOWExMTMxYWNiMThiZWNhMjFhNjkzYzliYmQ2YjZjMzE0ZSJ9LCJpc3N1ZXIiOnsicHVibGljS2V5IjoiMDM2NGZiYTRkMjNkNjRlM2ExZTFkMmZiNDBkNThiMzA5YTExMzFhY2IxOGJlY2EyMWE2OTNjOWJiZDZiNmMzMTRlIn0sImNsYWltIjp7IkB0eXBlIjoiUGVyc29uIiwiQGNvbnRleHQiOiJodHRwOi8vc2NoZW1hLm9yZyIsIm5hbWUiOiJUZXN0aW5nMTIzIiwiZGVzY3JpcHRpb24iOiJ0ZXN0ZXIgdGVzdGluZyB0ZXN0cyJ9fQ.BEvMyIU72J8p4xE2Yrcqnq4ZO-DfsPV-jqwCv0-dfYpztr1VtAKrF7MFSS4sMRrSfHdTUEAE1VHe9HLulwBOmA"
    
        // NOTE: The expiration date on the payload is 10/22/2019, which is when some tests may start failing.
        let profileJSON = """
              {
                "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJFUzI1NksifQ.eyJqdGkiOiI2OGExZjZiMy1hNmZlLTQ1ZWEtYTY0OC0xM2JmZDQ1NjMwYjQiLCJpYXQiOiIyMDE4LTEwLTIyVDEyOjM3OjIyLjg5NFoiLCJleHAiOiIyMDE5LTEwLTIyVDEyOjM3OjIyLjg5NFoiLCJzdWJqZWN0Ijp7InB1YmxpY0tleSI6IjAzNjRmYmE0ZDIzZDY0ZTNhMWUxZDJmYjQwZDU4YjMwOWExMTMxYWNiMThiZWNhMjFhNjkzYzliYmQ2YjZjMzE0ZSJ9LCJpc3N1ZXIiOnsicHVibGljS2V5IjoiMDM2NGZiYTRkMjNkNjRlM2ExZTFkMmZiNDBkNThiMzA5YTExMzFhY2IxOGJlY2EyMWE2OTNjOWJiZDZiNmMzMTRlIn0sImNsYWltIjp7IkB0eXBlIjoiUGVyc29uIiwiQGNvbnRleHQiOiJodHRwOi8vc2NoZW1hLm9yZyIsIm5hbWUiOiJUZXN0aW5nMTIzIiwiZGVzY3JpcHRpb24iOiJ0ZXN0ZXIgdGVzdGluZyB0ZXN0cyJ9fQ.BEvMyIU72J8p4xE2Yrcqnq4ZO-DfsPV-jqwCv0-dfYpztr1VtAKrF7MFSS4sMRrSfHdTUEAE1VHe9HLulwBOmA",
                "decodedToken": {
                  "header": {
                    "typ": "JWT",
                    "alg": "ES256K"
                  },
                  "payload": {
                    "jti": "68a1f6b3-a6fe-45ea-a648-13bfd45630b4",
                    "iat": "2018-10-22T12:37:22.894Z",
                    "exp": "2019-10-22T12:37:22.894Z",
                    "subject": {
                      "publicKey": "0364fba4d23d64e3a1e1d2fb40d58b309a1131acb18beca21a693c9bbd6b6c314e"
                    },
                    "issuer": {
                      "publicKey": "0364fba4d23d64e3a1e1d2fb40d58b309a1131acb18beca21a693c9bbd6b6c314e"
                    },
                    "claim": {
                      "@type": "Person",
                      "@context": "http://schema.org",
                      "name": "Testing123",
                      "description": "tester testing tests"
                    }
                  },
                  "signature": "BEvMyIU72J8p4xE2Yrcqnq4ZO-DfsPV-jqwCv0-dfYpztr1VtAKrF7MFSS4sMRrSfHdTUEAE1VHe9HLulwBOmA"
                }
              }
            """

        describe("Profile") {
            guard let data = profileJSON.data(using: .utf8),
                let profileTokenFile = try? JSONDecoder().decode(ProfileTokenFile.self, from: data),
                let profile = profileTokenFile.decodedToken?.payload?.claim else {
                    fail("Failure in decoding profile from JSON.")
                    return
            }
            
            context("extract profile") {
                it("can extract valid from token") {
                    var extractedProfile: Profile?
                    expect { extractedProfile = try Blockstack.shared.extractProfile(token: profileToken) }.toNot(beNil())
                    expect(extractedProfile!.description) == profile.description
                }
                it("crashes with invalid publicKeyOrAddress") {
                    expect { try Blockstack.shared.extractProfile(token: profileToken, publicKeyOrAddress: "asdjklfsdljf") }.to(throwError())
                }
            }
            
            it("can wrap profile token") {
                let tokenFile = Blockstack.shared.wrapProfileToken(token: profileToken)
                expect(tokenFile).toNot(beNil())
                expect(tokenFile!.token).toNot(beNil())
                expect(tokenFile!.decodedToken).toNot(beNil())
            }

            context("sign and verify") {
                // secp256k1 key pair
                let privateKey = "a25629673b468789f8cbf84e24a6b9d97a97c5e12cf3796001dde2927021cdaf"
                let publicKey = "04fdfa9031f9ac7b856bf539c0d315a4847c7e2b0b7dd22b40e8da9ee2beaa228acec7cad39526308bd7ab4af9e738203fdc6547a2108324c28874990e86534dc4"

                var signedToken: String?
                it ("can sign profile token") {
                    signedToken = Blockstack.shared.signProfileToken(profile: profile, privateKey: privateKey)
                    expect(signedToken).toNot(beNil())
                }
                
                it("can verify profile token") {
                    var token: ProfileToken?
                    expect { token = try Blockstack.shared.verifyProfileToken(token: signedToken!, publicKeyOrAddress: publicKey) }.toNot(throwError())
                    expect(token?.payload?.subject?["publicKey"]) == publicKey
                }
            }
            
            it("can lookup profile") {
                var profileResult: Profile?
                Blockstack.shared.lookupProfile(username: "testing123.id.blockstack") { result, error in
                    profileResult = result
                    expect(error).to(beNil())
                }
                expect(profileResult).toEventuallyNot(beNil(), timeout: 10, pollInterval: 1)
            }
        }
    }
}
