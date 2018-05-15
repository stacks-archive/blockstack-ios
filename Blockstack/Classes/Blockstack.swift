//
//  Blockstack.swift
//  Blockstack
//
//  Created by Yukan Liao on 2018-03-09.
//

import Foundation

open class Blockstack {
    
    public static let shared: BlockstackInstance = {
        return BlockstackInstance()
    }()
    
}

