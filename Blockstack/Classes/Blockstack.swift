//
//  Blockstack.swift
//  Blockstack
//
//  Created by Yukan Liao on 2018-03-09.
//

import Foundation

@objc open class Blockstack: NSObject {
    
    private var instance: BlockstackInstance?
    
    private static var shared: Blockstack = {
        let blockstack = Blockstack()
        return blockstack
    }()
    
    @objc open class func sharedInstance() -> BlockstackInstance {
        return shared.getInstance()
    }
    
    override private init() {
        instance = BlockstackInstance()
    }
    
    private func getInstance() -> BlockstackInstance {
        return instance!
    }
}


