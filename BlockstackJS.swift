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
    
    public func parseZoneFile(zoneFile: String) -> ZoneFile? {
        guard let context = context else {
            print("JSContext not found.")
            return nil
        }
        context.evaluateScript("""
            function parseZoneFile(text) {
                text = removeComments(text);
                text = flatten(text);
                return parseRRs(text);
            };

            var removeComments = function removeComments(text) {
                var re = /(^|[^\\\\]);.*/g;
                return text.replace(re, function (m, g1) {
                    return g1 ? g1 : ""; // if g1 is set/matched, re-insert it, else remove
                });
            };

            var flatten = function flatten(text) {
                var captured = [];
                var re = /\\([\\s\\S]*?\\)/gim;
                var match = re.exec(text);
                while (match !== null) {
                    match.replacement = match[0].replace(/\\s+/gm, ' ');
                    captured.push(match);
                    // captured Text, index, input
                    match = re.exec(text);
                }
                var arrText = text.split('');
                for (var i in captured) {
                    match = captured[i];
                    arrText.splice(match.index, match[0].length, match.replacement);
                }
                return arrText.join('').replace(/\\(|\\)/gim, ' ');
            };

            var parseURI = function parseURI(rr) {
                var rrTokens = rr.trim().split(/\\s+/g);
                var l = rrTokens.length;
                var result = {
                    name: rrTokens[0],
                    target: rrTokens[l - 1].replace(/"/g, ''),
                    priority: parseInt(rrTokens[l - 3], 10),
                    weight: parseInt(rrTokens[l - 2], 10)
                };

                if (!isNaN(rrTokens[1])) result.ttl = parseInt(rrTokens[1], 10);
                return result;
            };

            var parseRRs = function parseRRs(text) {
                var ret = {};
                var rrs = text.split('\\n');
                for (var i in rrs) {
                    var rr = rrs[i];
                    if (!rr || !rr.trim()) {
                        continue;
                    }
                    var uRR = rr.toUpperCase();
                    if (/\\s+TXT\\s+/.test(uRR)) {
                        ret.txt = ret.txt || [];
                        ret.txt.push(parseTXT(rr));
                    } else if (uRR.indexOf('$ORIGIN') === 0) {
                        ret.$origin = rr.split(/\\s+/g)[1];
                    } else if (uRR.indexOf('$TTL') === 0) {
                        ret.$ttl = parseInt(rr.split(/\\s+/g)[1], 10);
                    } else if (/\\s+SOA\\s+/.test(uRR)) {
                        ret.soa = parseSOA(rr);
                    } else if (/\\s+NS\\s+/.test(uRR)) {
                        ret.ns = ret.ns || [];
                        ret.ns.push(parseNS(rr));
                    } else if (/\\s+A\\s+/.test(uRR)) {
                        ret.a = ret.a || [];
                        ret.a.push(parseA(rr, ret.a));
                    } else if (/\\s+AAAA\\s+/.test(uRR)) {
                        ret.aaaa = ret.aaaa || [];
                        ret.aaaa.push(parseAAAA(rr));
                    } else if (/\\s+CNAME\\s+/.test(uRR)) {
                        ret.cname = ret.cname || [];
                        ret.cname.push(parseCNAME(rr));
                    } else if (/\\s+MX\\s+/.test(uRR)) {
                        ret.mx = ret.mx || [];
                        ret.mx.push(parseMX(rr));
                    } else if (/\\s+PTR\\s+/.test(uRR)) {
                        ret.ptr = ret.ptr || [];
                        ret.ptr.push(parsePTR(rr, ret.ptr, ret.$origin));
                    } else if (/\\s+SRV\\s+/.test(uRR)) {
                        ret.srv = ret.srv || [];
                        ret.srv.push(parseSRV(rr));
                    } else if (/\\s+SPF\\s+/.test(uRR)) {
                        ret.spf = ret.spf || [];
                        ret.spf.push(parseSPF(rr));
                    } else if (/\\s+URI\\s+/.test(uRR)) {
                        ret.uri = ret.uri || [];
                        ret.uri.push(parseURI(rr));
                    }
                }
                return ret;
            };
        """)
        
        // JavascriptCore cannot handle newlines ('\n') in strings.
        // Other escaped charpacters don't have the same problem.
        guard let jsValue = context.evaluateScript("""
            parseZoneFile('\(zoneFile.replacingOccurrences(of: "\n", with: "\\n"))')
            """),
            let zoneFileJSON = jsValue.toDictionary() as? [String: Any] else {
            return nil
        }
        return ZoneFile(from: zoneFileJSON)
    }
}

public struct ZoneFile {
    var uri: [[String: Any]]
    var origin: String
    var ttl: Int
    
    init?(from zoneFileJSON: [String: Any]) {
        guard let uri = zoneFileJSON["uri"] as? [[String: Any]],
            let origin = zoneFileJSON["$origin"] as? String,
            let ttl = zoneFileJSON["$ttl"] as? Int else {
                return nil
        }
        self.uri = uri
        self.origin = origin
        self.ttl = ttl
    }
}
