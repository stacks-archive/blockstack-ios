//
//  Blockstack.swift
//  Blockstack
//
//  Created by Yukan Liao on 2018-03-09.
//

import Foundation

open class Blockstack {
    
    private var instance: BlockstackInstance?
    
    private static var sharedBlockstack: Blockstack = {
        let blockstack = Blockstack()
        return blockstack
    }()
    
    open class func sharedInstance() -> BlockstackInstance {
        return sharedBlockstack.getInstance()
    }
    
    private init() {
        instance = BlockstackInstance()
    }
    
    private func getInstance() -> BlockstackInstance {
        return instance!
    }
}


