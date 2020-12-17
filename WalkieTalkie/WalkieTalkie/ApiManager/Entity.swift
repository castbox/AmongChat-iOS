//
//  Entity.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/6/29.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation

struct Entity {
    
}

extension Entity {
    struct LoginResult: Codable {
        let uid: String
        let token: String
        let newUser: Bool
        let firebaseToken : String
    }
    
    struct Channel: Codable {
        let name: String
        let user_count: Int
        let user_list: [UInt]
        let channel_exist: Bool
        
        init?(with dict: [String : Any]) {
            guard  let name = dict["name"] as? String,
                   let user_count = dict["user_count"] as? Int,
                   let user_list = dict["user_list"] as? [UInt],
                   let channel_exist = dict["channel_exist"] as? Bool else { return nil }
            self.name = name
            self.user_count = user_count
            self.user_list = user_list
            self.channel_exist = channel_exist
        }
    }
    
//    struct RoomUser: Codable {
//        let avatar: String
//        let name: String
//        let robloxName: String?
//        let seatNo: Int
//        let uid: String
//    }
    
    enum RoomPublicType: String, Codable {
        case `public`
        case `private`
        
        private enum CodingKeys: String, CodingKey {
            case `public` = "PUBLIC"
            case `private` = "PRIVATE"
        }
    }
    
    //房间类型
    struct Room: Codable {
        
        let amongUsCode: String?
        let amongUsZone: String?
        let note: String?
        let roomId: String
        
        let roomUserList: [ChannelUser]
        var state: RoomPublicType
        let topicId: AmongChat.Topic
        let topicName: String
        
        var isValidAmongConfig: Bool {
            guard topicId == .amongus,
                  let code = amongUsCode,
                  let zone = amongUsZone else {
                return false
            }
            return !code.isEmpty && !zone.isEmpty
        }
    }
}

