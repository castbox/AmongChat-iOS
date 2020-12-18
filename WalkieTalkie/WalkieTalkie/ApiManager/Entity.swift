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
    
    struct RTMToken: Codable {
        let rcToken: String
        private enum CodingKeys: String, CodingKey {
            case rcToken = "rc_token"
        }
    }
    
    struct RTCToken: Codable {
        let roomToken: String
        private enum CodingKeys: String, CodingKey {
            case roomToken = "room_token"
        }
    }
    
}


