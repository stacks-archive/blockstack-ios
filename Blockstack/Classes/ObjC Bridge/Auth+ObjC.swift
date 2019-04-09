//
//  Auth+ObjC.swift
//  Blockstack
//
//  Created by Shreyas Thiagaraj on 9/7/18.
//

import Foundation

@objc(AuthResult)
@objcMembers public class ObjCAuthResult: NSObject {
    public let result: OperationResult
    public let userData: ObjCUserData?
    public let error: Error?
    
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

@objc public enum OperationResult: Int {
    case success, failed, cancelled
}
