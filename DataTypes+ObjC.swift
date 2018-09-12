//
//  DataTypes+ObjC.swift
//  Blockstack
//
//  Created by Shreyas Thiagaraj on 9/7/18.
//

import Foundation

@objc(Profile)
public class ObjCProfile: NSObject {
    public let type: String?
    public let context: String?
    public let name: String?
    public let profileDescription: String?
    
    public init(_ profile: Profile) {
        self.type = profile.type
        self.context = profile.context
        self.name = profile.name
        self.profileDescription = profile.description
    }
}

@objc(Payload)
public class ObjCUserData: NSObject {
    public let jti: String?
    public let iat, exp: Int?
    public let iss: String?
    public var privateKey: String?
    public let publicKeys: [String]?
    public let username, email, coreToken, profileURL, hubURL, version: String?
    public let claim: ObjCProfile?
    public var profile: ObjCProfile?
    
    public init(_ userData: UserData) {
        self.jti = userData.jti
        self.iat = userData.iat
        self.exp = userData.exp
        self.iss = userData.iss
        self.privateKey = userData.privateKey
        self.publicKeys = userData.publicKeys
        self.username = userData.username
        self.email = userData.email
        self.coreToken = userData.coreToken
        self.profileURL = userData.profileURL
        self.hubURL = userData.hubURL
        self.version = userData.version
        
        if let profileStruct = userData.profile {
            self.profile = ObjCProfile(profileStruct)
        }

        if let claimStruct = userData.claim {
            self.claim = ObjCProfile(claimStruct)
        } else {
            self.claim = nil
        }
    }
}

@objc(AuthResult)
public class ObjCAuthResult: NSObject {
    let result: OperationResult
    let userData: ObjCUserData?
    let error: Error?

    init(_ authResult: AuthResult) {
        switch authResult {
        case let .success(data):
            self.result = .success
            self.userData = ObjCUserData(data)
            self.error = nil
        case let .failed(error):
            self.result = .failed
            self.userData = nil
            self.error = error
        case .cancelled:
            self.result = .cancelled
            self.userData = nil
            self.error = nil
        }
    }
}

@objc enum OperationResult: Int {
    case success, failed, cancelled
}
