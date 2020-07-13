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
            case tutorial_imp_1
            case tutorial_imp_2
            case tutorial_imp_3
        }
        
        enum Category: String {
            case screen
            case screen_life
            case normal //正常半页/
            case empty //列表为空、点击按钮/
            case wrong_passcode //：输入passcode错误/
            case invaild //房间失效"
        }
        
        static func log(_ eventName: EventName, _ category: Category? = nil, _ itemName: String? = nil, _ value: Int64? = nil, content: String? = nil) {
            GuruAnalytics.log(event: eventName.rawValue, category: category?.rawValue, name: itemName, value: value, content: content)
        }
        
        static func logger(_ eventName: String, _ category: String?, _ itemName: String? = nil, _ value: Int64? = nil, content: String? = nil) {
            GuruAnalytics.log(event: eventName, category: category, name: itemName, value: value, content: content)
        }
    }
    
    struct Push {
        
        enum Category: String {
            case hot
            case recommend
        }
        
        static func log(_ category: Category? = nil, _ itemName: String? = nil, _ value: Int64? = nil, content: String? = nil) {
            GuruAnalytics.log(event: "push_receive", category: category?.rawValue, name: itemName, value: value, content: content)
        }
    }
}
