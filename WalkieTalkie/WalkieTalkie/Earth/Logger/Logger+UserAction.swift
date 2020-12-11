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
            case channel_create_new
            case channel_choice
            case connect
            case music
            //"点击分享时所在页面
            case share_channel //channel页
            case share_secret_channel_create //创建secret channel弹窗"
            case secret
            case channel_up
            case channel_down
            case create_secret
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
        
        static func logChannelCategoryClick(id: Int) {
            GuruAnalytics.log(event: "clk_home_category_\(id)")
        }

    }
}

extension Logger {
    
    struct Action {
        enum EventName: String {
            case input_passcode
            case secret_tab
            case global_tab
            case global_create_imp
            case create_secret_clk
            case enter_secret
            case enter_secret_success
            case create_global_clk
            case create_secret_list_clk
            case secret_channel_share_pop_confirm
            case secret_channel_share_pop_cancel
            case emoji_sent
            case emoji_imp
        }
        
        enum Category: String {
            case channel_list
            case channel_create
            case channel_create_new
            case channel_choice
            case connect
            case music
            //"点击分享时所在页面
            case share_channel //channel页
            case share_secret_channel_create //创建secret channel弹窗"
            case secret
            case channel_up
            case channel_down
            case create_secret
            case update_pro
            case enter_secret
            //source
            case normal //正常半页/
            case empty //列表为空、点击按钮/
            case wrong_passcode //：输入passcode错误/
            case invaild //房间失效"
        }
        
        static func log(_ eventName: EventName, category: Category? = nil, _ itemName: String? = nil) {
            GuruAnalytics.log(event: eventName.rawValue, category: category?.rawValue, name: itemName, value: nil, content: nil)
        }
    }
}

extension Logger {
    
    struct Share {
        enum EventName: String {
            case share
            case share_clk
            case share_dialog_pop
        }
        
        enum Category: String {
            case global
            case secret
        }
        
        static func log(_ eventName: EventName, category: Category? = nil, _ itemName: String? = nil) {
            GuruAnalytics.log(event: eventName.rawValue, category: category?.rawValue, name: itemName, value: nil, content: nil)
        }
        
        static func log(_ eventName: EventName, category: String?, _ itemName: String? = nil) {
            GuruAnalytics.log(event: eventName.rawValue, category: category, name: itemName, value: nil, content: nil)
        }
    }
}
