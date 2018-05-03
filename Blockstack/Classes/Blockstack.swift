//
//  Blockstack.swift
//  Blockstack
//
//  Created by Yukan Liao on 2018-03-09.
//

import Foundation

open class Blockstack {
    
    private var instance: BlockstackInstance?
    
    private static var shared: Blockstack = {
        let blockstack = Blockstack()
        return blockstack
    }()
    
    open class func sharedInstance() -> BlockstackInstance {
        return shared.getInstance()
    }
    
    private init() {
        instance = BlockstackInstance()
    }
    
    private func getInstance() -> BlockstackInstance {
        return instance!
    }
}


