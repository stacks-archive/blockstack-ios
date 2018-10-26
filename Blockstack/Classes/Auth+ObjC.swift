//
//  Auth+ObjC.swift
//  Blockstack
//
//  Created by Shreyas Thiagaraj on 9/7/18.
//

import Foundation

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
