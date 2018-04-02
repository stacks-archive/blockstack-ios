//
//  Blockstack.swift
//  Blockstack
//
//  Created by Yukan Liao on 2018-03-09.
//

import Foundation

open class Blockstack {
    
    private var authenticationModule: BlockstackAuthentication
    private var storageModule: BlockstackStorage
    
    static var shared = Blockstack()
    
    init() {
        authenticationModule = BlockstackAuthentication()
        storageModule = BlockstackStorage()
    }
    
    // MARK: Public API methods
    
    open func signIn(redirectURLScheme: String, manifestURI: URL, scopes: Array<String> = ["store_write"]) {
        authenticationModule.signIn(redirectURLScheme: redirectURLScheme, manifestURI: manifestURI, scopes: scopes)
    }
    
    open func store(string: String) {
        storageModule.store(string: string)
    }
}


