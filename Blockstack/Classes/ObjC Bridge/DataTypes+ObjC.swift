//
//  DataTypes+ObjC.swift
//  Blockstack
//
//  Created by Shreyas Thiagaraj on 9/7/18.
//

import Foundation

@objc(DecryptedValue)
@objcMembers public class ObjCDecryptedValue: NSObject {
    public let plainText: String?
    public let bytes: Bytes?

    public var isString: Bool {
        return self.plainText != nil
    }
    
    public init(_ decryptedValue: DecryptedValue) {
        self.plainText = decryptedValue.plainText
        self.bytes = decryptedValue.bytes
    }
}

@objc(Payload)
@objcMembers public class ObjCUserData: NSObject {
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

@objc(Profile)
@objcMembers public class ObjCProfile: NSObject {
    public let type: String?
    public let context: String?
    public let name: String?
    public let profileDescription: String?
    public let apps: [String: String]?
    public let account: [ObjCExternalAccount]?
    public let image: [ObjCContent]?
    
    public init(_ profile: Profile) {
        self.type = profile.type
        self.context = profile.context
        self.name = profile.name
        self.profileDescription = profile.description
        self.apps = profile.apps
        self.account = profile.account?.compactMap { ObjCExternalAccount($0) }
        self.image = profile.image?.compactMap { ObjCContent($0) }
    }
}

@objc(Content)
@objcMembers public class ObjCContent: NSObject {
    public let type: String?
    public let name: String?
    public let contentUrl: String?

    public init(_ content: Content) {
        self.type = content.type
        self.name = content.name
        self.contentUrl = content.contentUrl
    }
}

@objc(ExternalAccount)
@objcMembers public class ObjCExternalAccount: NSObject {
    public let type: String?
    public let placeholder: Bool?
    public let service: String?
    public let identifier: String?
    public let proofType: String?
    public let proofUrl: String?
    
    init(_ account: ExternalAccount) {
        self.type = account.type
        self.placeholder = account.placeholder
        self.service = account.service
        self.identifier = account.identifier
        self.proofType = account.proofType
        self.proofUrl = account.proofUrl
    }
}

