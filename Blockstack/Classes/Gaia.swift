//
//  Gaia.swift
//  Blockstack
//
//  Created by Yukan Liao on 2018-04-15.
//

import Foundation

public class Gaia {
    private var session: GaiaSession?
    
    private static var session: Gaia = {
        let gaia = Gaia()
        return gaia
    }()
    
    open class func sharedSession() -> GaiaSession {
        return session.getSession()
    }
    
    private init() {
        session = GaiaSession()
    }
    
    private func getSession() -> GaiaSession {
        return session!
    }
}
    

