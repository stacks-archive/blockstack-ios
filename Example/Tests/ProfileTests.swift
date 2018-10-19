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
        describe("Profile") {
            context("wrapProfileToken") {
                // For user testing1234.id.blockstack
                let profileToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJFUzI1NksifQ.eyJqdGkiOiJiZjI2NjkzMy1hZjU0LTQ3OWQtYjRiNC00MGZlYmY1NzU1NzQiLCJpYXQiOiIyMDE4LTA4LTIzVDA5OjU4OjI5LjYxNVoiLCJleHAiOiIyMDE5LTA4LTIzVDA5OjU4OjI5LjYxNVoiLCJzdWJqZWN0Ijp7InB1YmxpY0tleSI6IjAyMmFkZTgxZTFkZGFjMGY5OWI3ZWZkNTdhZjg4Zjk0OTY0NjVlODA4MDZlMWE2ZGY5ZTFjNDMzODY1MGY4YjAyOCJ9LCJpc3N1ZXIiOnsicHVibGljS2V5IjoiMDIyYWRlODFlMWRkYWMwZjk5YjdlZmQ1N2FmODhmOTQ5NjQ2NWU4MDgwNmUxYTZkZjllMWM0MzM4NjUwZjhiMDI4In0sImNsYWltIjp7IkB0eXBlIjoiUGVyc29uIiwiQGNvbnRleHQiOiJodHRwOi8vc2NoZW1hLm9yZyIsImFwcHMiOnsiaHR0cHM6Ly9wZWRhbnRpYy1tYWhhdmlyYS1mMTVkMDQubmV0bGlmeS5jb20iOiJodHRwczovL2dhaWEuYmxvY2tzdGFjay5vcmcvaHViLzFQaDQzZTl3dXBnd3J4Z2hnRU1XUU11c3JpMmh3aWI5dDEvIn19fQ.tykC6ZFHT7O2Dy_HJ5OnSVr9FnkI8YDZOSfqb756J9hNQgsp53NY3_Yn1StYo22gk6roT0JlEmzVuGL7GpFz8Q"
                let tokenFile = Blockstack.shared.wrapProfileToken(token: profileToken)
                expect(tokenFile).toNot(beNil())
                expect(tokenFile?.decodedToken).toNot(beNil())
            }
            
            it("can validateProofs") {
                var didValidateProofs = false
                let userProfileUrl = "https://gaia.blockstack.org/hub/15GAGiT2j2F1EzZrvjk3B8vBCfwVEzQaZx/0/profile.json"
                let userOwnerAddress = "15GAGiT2j2F1EzZrvjk3B8vBCfwVEzQaZx"
                ProfileHelper.fetch(profileURL: URL(string: userProfileUrl)!) { profile, error in
                    Blockstack.shared.validateProofs(profile: profile!, ownerAddress: userOwnerAddress) { proofs in
                        expect(proofs).toNot(beNil())
                        proofs!.forEach { proof in
                            if !proof.valid {
                                fail("Failed to validate proof for: \(proof.service)")
                            }
                        }
                        didValidateProofs = true
                    }
                }
                expect(didValidateProofs).toEventually(beTrue(), timeout: 10, pollInterval: 1)
            }
        }
    }
}
