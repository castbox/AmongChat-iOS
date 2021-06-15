//
//  Logger+Ads.swift
//  Quotes
//
//  Created by 江嘉睿 on 2020/4/18.
//  Copyright © 2020 Guru Network Limited Inc. All rights reserved.
//

import Foundation
import CastboxDebuger

extension Logger {
    struct VideoAds {
        enum Action: RawRepresentable {
            init?(rawValue: String) {
                return nil
            }
            
            var rawValue: String {
                switch self {
                case .loaded(_):
                    return "loaded"
                default:
                    return "\(self)"
                }
            }
            
            typealias RawValue = String
            
            case request
            case load_fail
            case loaded(Int64)
            case no_cached
            case expire
            case show
            case rewarded
            case fail_to_play
            case click
            case close
            
        }
        
        static func log(_ action: Action, with error: NSError? = nil) {
            
            if let e = error {
                GuruAnalytics.log(event: "rads_\(action.rawValue)", category: nil, name: e.domain, value: Int64(e.code))
            } else {
                
                let value: Int64?
                
                switch action {
                case .loaded(let timespan):
                    value = timespan
                default:
                    value = nil
                }
                
                GuruAnalytics.log(event: "rads_\(action.rawValue)", category: nil, name: nil, value: value)
            }
            
            mlog.info("action:\(action)" + (error?.localizedDescription ?? ""), context: "VideoAds")
        }
    }
}

extension Logger {
    struct NativeAds {
        enum Action: RawRepresentable {
            init?(rawValue: String) {
                return nil
            }
            
            var rawValue: String {
                switch self {
                case .loaded(_):
                    return "loaded"
                default:
                    return "\(self)"
                }
            }
            
            typealias RawValue = String
            
            case request
            case load_fail
            case loaded(Int64)
            case no_cached
            case show
            case click
        }
        
        static func log(_ action: Action, with error: NSError? = nil) {
            
            if let e = error {
                GuruAnalytics.log(event: "nads_\(action.rawValue)", category: nil, name: e.domain, value: Int64(e.code))
            } else {
                
                let value: Int64?
                
                switch action {
                case .loaded(let timespan):
                    value = timespan
                default:
                    value = nil
                }
                
                GuruAnalytics.log(event: "nads_\(action.rawValue)", category: nil, name: nil, value: value)
            }
            
            mlog.info("action:\(action)" + (error?.localizedDescription ?? ""), context: "NativeAds")
        }
    }
}
