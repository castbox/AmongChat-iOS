//
//  Logger+PageShow.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/4/21.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation

extension Logger {
    
    struct PageShow {
        
        enum EventName: String {
            case screen
            case secret_channel_create_pop_imp
            case secret_channel_share_pop_imp
            case secret_channel_create_pop_close
            case secret_channel_share_pop_close
            
        }
        
        enum Category: String {
            case screen
            case screen_life
        }
        
        static func log(_ eventName: EventName, _ category: Category? = nil, _ itemName: String? = nil, _ value: Int64? = nil, content: String? = nil) {
            GuruAnalytics.log(event: eventName.rawValue, category: category?.rawValue, name: itemName, value: value, content: content)
        }
        
        static func logger(_ eventName: String, _ category: String?, _ itemName: String?, _ value: Int64?, content: String? = nil) {
            GuruAnalytics.log(event: eventName, category: category, name: itemName, value: value, content: content)
        }
    }
}
