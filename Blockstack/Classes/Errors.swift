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

public enum GaiaError: Error {
    case requestError
    case invalidResponse
    case connectionError
    case configurationError
}

