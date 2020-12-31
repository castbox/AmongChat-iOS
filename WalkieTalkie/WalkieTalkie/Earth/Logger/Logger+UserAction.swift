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
        
        enum Source: String {
            case home
            case all_rooms
        }
        
        static func logChannelCategoryClick(id: Int, source: Source) {
            GuruAnalytics.log(event: "clk_home_category_\(id)", category: source.rawValue)
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
            
            //new for amongchat
            case enter_home_topic
            case profile_imp
            case profile_avatar_imp
            case profile_avatar_clk
            case profile_avatar_get
            case profile_avatar_get_success
            case profile_nikename_clk
            case profile_birthday_clk
            case profile_invite_friend_clk
            case profile_followers_imp
            case profile_followers_clk
            case profile_following_imp
            case profile_following_clk
            case profile_other_imp
            case profile_other_clk
            case profile_other_followers_imp
            case profile_other_followers_clk
            case profile_other_following_imp
            case profile_other_following_clk
            case settings_share_app_clk
            case create_topic_imp
            case create_topic_edit
            case create_topic_create
            case create_topic_hot_clk
            case room_share_clk
            case room_open_game
            case room_send_message_clk
            case room_send_message_success
            case room_mic_state
            case room_user_profile_imp
            case room_user_profile_clk
            case room_amongus_code_copy
            case room_enter
            case room_leave_clk
            case room_edit_nickname
            case room_edit_nickname_success
            case room_edit_clk
            case room_change_state_clk
            case room_exit_channel_imp
            case room_exit_channel_clk
            case room_share_item_clk
            case rtc_call_roominfo
            case invite_dialog_imp
            case invite_dialog_clk
            case invite_dialog_auto_dimiss
            case home_tab
            case home_friends_profile_clk
            case home_friends_following_join
            case home_friends_invite_clk
            case home_friends_suggestion_following_clk
            
            //for admin
            case admin_imp
            case admin_edit_imp
            case admin_edit_success
            case admin_kick_imp
            case admin_kick_success
            case admin_change_state
            
            case login_imp
            case login_clk
            case login_success
            case login_result
            case login_birthday_imp
            case login_birthday_skip
            case login_birthday_done
            case login_birthday_success
            case logout_clk
            case logout_success
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
            
            //头像
            case rewarded
            case free
            case profile
            case follow
            case following
            case followers
            case unfollow
            
            case google
            case apple_id
            case success
            case fail
        }
        
        static func log(_ eventName: EventName, category: Category? = nil, _ itemName: String? = nil, _ value: Int? = nil) {
            GuruAnalytics.log(event: eventName.rawValue, category: category?.rawValue, name: itemName, value: value?.int64, content: nil)
        }
        
        static func log(_ eventName: EventName, categoryValue: String?, _ itemName: String? = nil, _ value: Int? = nil) {
            GuruAnalytics.log(event: eventName.rawValue, category: categoryValue, name: itemName, value: value?.int64, content: nil)
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
