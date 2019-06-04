//
//  Errors.swift
//  Blockstack
//
//  Created by Yukan Liao on 2018-04-11.
//

import Foundation

public enum AuthError: Error {
    case invalidResponse
}

@objc public enum GaiaError: Int, Error {
    case requestError
    case invalidResponse
    case connectionError
    case configurationError
    case signatureVerificationError
    case fileNotFoundError
    case serverError
}
