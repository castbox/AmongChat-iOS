//
//  Logger+UserAction.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/4/21.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation

extension Logger {
    
    struct UserAction {
        
        enum Category: String {
            case channel_list
            case channel_create
            case channel_choice
            case connect
            case music
            //"点击分享时所在页面
            case share_channel //channel页
            case share_secret_channel_create //创建secret channel弹窗"
            case secret
            case channel_up
            case channel_down
            case create_new
            case update_pro
            case enter_secret
        }
        
        static func log(_ category: Category? = nil, _ itemName: String? = nil) {
            GuruAnalytics.log(event: "user_action", category: category?.rawValue, name: itemName, value: nil, content: nil)
        }
    }
}


extension Logger {
    
    struct Channel {
        
        enum Category: String {
            case deeplink
        }
        
        static func log(_ category: Category? = nil, _ itemName: String? = nil, value: Int) {
            GuruAnalytics.log(event: "channel_imp", category: category?.rawValue, name: itemName, value: Int64(value), content: nil)
        }
    }
}
