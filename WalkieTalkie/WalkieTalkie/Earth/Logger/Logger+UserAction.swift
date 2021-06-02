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
            case profile_avatar_select_alert_imp
            case profile_avatar_select_alert_clk
            case profile_avatar_clk
            case profile_avatar_get
            case profile_avatar_get_success
            case profile_avatar_get_failed
            case profile_nikename_clk
            case profile_birthday_clk
            case profile_birthday_update_success
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
            case space_card_tip_clk
            case space_card_use_dialog_imp
            case space_card_use_dialog_clk
            case space_card_ads_dialog_imp
            case space_card_ads_claim_clk
            case space_card_ads_claim_success
            case space_card_ads_claim_failed
            case space_card_pro_clk
            case room_share_clk
            case room_open_game
            case room_send_message_clk
            case room_send_message_success
            case room_mic_state
            case room_user_profile_imp
            case room_emoji_clk
            case room_emoji_selected
            case room_next_room_clk
            case room_next_room_success
            case room_user_profile_clk
            case room_amongus_code_copy
            case room_enter
            case room_enter_set_age_imp
            case room_enter_set_age_confirm
            case room_enter_set_age_save
            
            
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
            case invite_top_dialog_imp
            case invite_top_dialog_clk
            case invite_top_dialog_auto_dismiss
            case settings_chat_language_imp
            case settings_chat_language_clk
            
            case home_tab
            case home_friends_profile_clk
            case home_friends_following_join
            case home_friends_invite_clk
            case home_friends_suggestion_following_clk
            case home_friends_apply_verified
            case home_search_clk
            case search_done
            case search_result_clk
            
            //for admin
            case admin_imp
            case admin_edit_imp
            case admin_edit_success
            case admin_kick_imp
            case admin_kick_success
            case admin_change_state
            
            case login_imp
            case login_clk
            case login_result
            case logout_clk
            case logout_success
            case start_result
            case start_result_fail
            
            case signin_imp
            case signin_clk
            
            case signin_phone_next_result
            case signin_phone_next_result_fail
            
            case signin_phone_verify_imp
            case signin_phone_verify_resend
            
            case signin_result
            case signin_result_fail
            
            case age_imp
            case age_done
            case age_done_result
            case age_done_result_fail
            
            case profile_tiktok_amongchat_tag_clk
            
            //
            case contact_imp
            case contact_clk
            case contact_permission_enable
            case suggested_contact_imp
            case suggested_contact_clk
            case suggested_contact_page_imp
            case suggested_contact_page_clk
            case new_avatar_dialog_imp
            case new_avatar_dialog_clk
            //
            case enter_room_show_pet
            
            case profile_customize_imp
            case profile_customize_clk
            case profile_customize_rewarded_get
            case profile_customize_rewarded_get_success
            case profile_customize_pet_get
            case profile_customize_pet_get_success
            case profile_customize_pet_equip
            case profile_customize_pet_remove
            case profile_show_verify_icon
            case profile_add_game_clk
            case profile_game_state_item_clk
            case profile_game_state_item_delete_clk
            case gameskill_choose_game_next_clk
            case gameskill_add_state_done
            case profile_other_game_state_item_clk
            case profile_game_state_detail_edit_clk
            case attracking_request_imp
            
            //group
            case profile_group_clk
            case profile_other_group_clk
            case group_list_imp
            case group_list_clk
            case group_list_tab_clk
            case group_create_info_next
            case group_create_add_topic_imp
            case group_create_add_topic_clk
            case group_add_members_imp
            case group_add_members_clk
            case group_enter
            case group_apply_join_clk
            case group_share_clk
            case group_send_message_clk
            case group_send_message_success
            case group_mic_state
            case group_user_profile_imp
            case group_user_profile_clk
            case group_amongus_code_set_done
            case group_amongus_code_copy
            case group_roblox_link_set_done
            case group_roblox_link_copy
            case group_notes_set_done
            case group_leave_clk
            case group_edit_nickname
            case group_edit_nickname_success
            case group_edit_clk
            case group_audience_raise_hands_clk
            case group_broadcaster_raise_hands_imp
            case group_raise_hands_accept
            case group_raise_hands_reject
            case group_broadcaster_join_request_imp
            case group_broadcaster_join_request_accept
            case group_broadcaster_join_request_ignore
            case group_member_list_imp
            case group_cover_clk
            case group_audience_drop_confirm
            case group_info_clk
            case group_emoji_clk
            case group_emoji_selected
            
//            case dm_notice_clk
            case notice_tab_system_clk
            case notice_tab_social_clk
            case notice_tab_group_request_clk
            case group_join_request_imp
            
            //dm
            case profile_other_chat_clk
            case dm_notice_clk
            case dm_list_item_click
            case dm_detail_imp
            case dm_detail_clk
            case dm_detail_item_clk
            case dm_detail_tool_bar_clk
            case dm_detail_send_msg
            case gif_search_clk
            case gif_select_clk
            
            case dm_interactive_imp
            case dm_interactive_filter_clk
            case dm_interactive_item_clk
            case feeds_create_clk
            case feeds_item_clk
            case feeds_comment_send_clk
            case emotes_imp
            case emotes_item_clk
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
            case premium
            case free
            case profile
            case follow
            case following
            case followers
            case unfollow
            
            case avatar
            case camera
            case album
            
            case phone
            case google
            case apple_id
            case snapchat
            case facebook
            case success
            case fail
            
            case search
            case invite
            case all
            case skip
            case sms
            case copy
            case share
            case go
            //dm
            case chat
            case delete
            case join_channel
            case join_group
            case block
            case unblock
            case report
            case delete_history
            case resend //失败后重试
            case voice_play // 播放语音消息"
            case voice
            case textvoice
            case gift
            //
            case comments
            case emotes
            case likes
            case pause
            case play
            case comment
            case slide_play // 拖动播放
            case not_intereasted
        }
        
        static func log(_ eventName: EventName, category: Category? = nil, _ itemName: String? = nil, _ value: Int? = nil, extra: [String: Any]? = nil) {
            GuruAnalytics.log(event: eventName.rawValue, category: category?.rawValue, name: itemName, value: value?.int64, content: nil,  extra: extra)
        }
        
        static func log(_ eventName: EventName, categoryValue: String?, _ itemName: String? = nil, _ value: Int? = nil, extra: [String: Any]? = nil) {
            GuruAnalytics.log(event: eventName.rawValue, category: categoryValue, name: itemName, value: value?.int64, content: nil, extra: extra)
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

extension Logger.Action {
    
    static func loginSource(from style: AmongChat.Login.LoginStyle) -> String? {
        return style.loggerSource
    }
    
}
