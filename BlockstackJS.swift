//
//  BlockstackJS.swift
//  Blockstack
//
//  Created by Shreyas Thiagaraj on 8/18/18.
//

import Foundation
import JavaScriptCore

class BlockstackJS {
    
    lazy var context: JSContext? = {
        let context = JSContext()
        
        let frameworkBundle = Bundle(for: type(of: self))
        let bundleURL = frameworkBundle.resourceURL?.appendingPathComponent("Blockstack.bundle")
        let resourceBundle = Bundle(url: bundleURL!)
        
        guard let
            JSPath = resourceBundle?.path(forResource: "blockstack", ofType: "js") else {
                print("Unable to read resource files.")
                return nil
        }
        
        do {
            let blockstackJS = try String(contentsOfFile: JSPath, encoding: String.Encoding.utf8)
            _ = context?.evaluateScript(blockstackJS)
            
        } catch (let error) {
            print("Error while processing script file: \(error)")
        }
        
        context?.exceptionHandler = {(context: JSContext?, exception: JSValue?) -> Void in
            print(exception!.toString())
        }
        
        _ = context?.evaluateScript("var console = { log: function(message) { _consoleLog(message) } }")
        
        let consoleLog: @convention(block) (String) -> Void = { message in
            print("console.log: " + message)
        }
        
        context?.setObject(unsafeBitCast(consoleLog, to: AnyObject.self),
                           forKeyedSubscript: "_consoleLog" as NSCopying & NSObjectProtocol)
        return context
    }()
