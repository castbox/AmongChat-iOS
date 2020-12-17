//
//  AdjustAnalytics.swift
//  Quotes
//
//  Created by mayue_work on 2020/7/10.
//  Copyright © 2020 Guru Network Limited Inc. All rights reserved.
//

import Foundation
import Adjust

struct AdjustAnalytics {
    
    static let sharedInstance = AdjustAnalytics()
    
    let constants: Constants
    
    private init() {
        constants = Constants()
        
        guard constants.appToken.isEmpty == false else { return }
        
        #if DEBUG
        let env = ADJEnvironmentSandbox
        #else
        let env = ADJEnvironmentProduction
        #endif
        let cfg = ADJConfig(appToken: constants.appToken, environment: env)
        Adjust.appDidLaunch(cfg)
    }
    
    func log(event: ADJEvent?) {
        Adjust.trackEvent(event)
    }
}

extension AdjustAnalytics {
    
    struct Constants {
        let appToken: String
        let events: [String : String]
        
        fileprivate init() {
            
            let dictFromPlist: [String : Any]
            
            if let url = Bundle.main.url(forResource:"Adjust-Info", withExtension: "plist") {
                let data = try! Data(contentsOf:url)
                dictFromPlist = try! PropertyListSerialization.propertyList(from: data, format: nil) as! [String : Any]
            } else {
                #if DEBUG
                assert(false, "Adjust-Info.plist not found")
                #endif
                dictFromPlist = [:]
            }
            appToken = dictFromPlist["appToken"] as! String
            events = dictFromPlist["events"] as! [String : String]
        }
        
    }
    
}
