//
//  Gaia.swift
//  Blockstack
//
//  Created by Yukan Liao on 2018-04-15.
//

import Foundation

public struct GaiaConfig: Codable {
    
}

public class Gaia {
    
    static func getOrSetLocalGaiaHubConnection() {
        if (retrieveGaiaConfig() == nil) {
            
        }
    }
 
    static func setLocalGaiaHubConnection() {
        
    }
    
    static func storeGaiaConfig(config: GaiaConfig) {
        UserDefaults.standard.set(try? PropertyListEncoder().encode(config),
                                  forKey: BlockstackConstants.GaiaHubConfigUserDefaultLabel)
    }
    
    static func retrieveGaiaConfig() -> GaiaConfig? {
        if let data = UserDefaults.standard.value(forKey:BlockstackConstants.GaiaHubConfigUserDefaultLabel) as? Data {
            return try? PropertyListDecoder().decode(GaiaConfig.self, from: data)
        } else {
            return nil
        }
    }
    
}
