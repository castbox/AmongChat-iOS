//
//  Logger+AppOpenAd.swift
//  Castbox
//
//  Created by mayue_work on 2020/10/28.
//  Copyright © 2020 Guru. All rights reserved.
//

import Foundation

extension Logger {
    
    struct AppOpenAd {
        
        enum Event {
            case oads_load
            case oads_loaded(ts: Int64)
            case oads_failed(error: Error)
            case oads_imp
            case oads_close
            
            var name: String {
                let str = "\(self)"
                if let idx = str.firstIndex(of: "(") {
                    return String(str[..<idx])
                } else {
                    return str
                }
            }
        }
        
        static func logEvent(_ event: Event) {
            
            var loadTs: Int64? = nil
            var error: Error? = nil
            
            switch event {
            case .oads_loaded(let ts):
                loadTs = ts
            case .oads_failed(let err):
                error = err
            default:
                ()
            }
            
            GuruAnalytics.log(event: event.name, category: nil, name: nil, value: loadTs, error: error)
        }
        
    }
    
}

extension Logger {
    
    class AdRevenue {
        
        enum ParamKey: String {
            case ad_platform
            case ad_source
            case ad_format
            case ad_unit_name
            case value
            case currency
            case precision
            case country
        }
        
        private var data = [String : Any]()
        
        func addData(key: ParamKey, value: Any?) -> AdRevenue {
            if let value = value {
                data[key.rawValue] = value
            }
            return self
        }
        
        func log() {
            GuruAnalytics.log(event: "tch_ad_rev_value", extra: data)
        }
        
    }
    
}
