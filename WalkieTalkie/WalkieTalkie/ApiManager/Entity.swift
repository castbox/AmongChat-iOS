//
//  Entity.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/6/29.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation
import SwiftyUserDefaults

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
    
    struct RTMToken: Codable, DefaultsSerializable {
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
    
    struct Processed: Codable {
        let processed: Bool
    }
}

extension Entity {
    struct GlobalSetting: Codable {
        
        struct RoomBg: Codable {
            let topicId: String
            let bgUrl: URL
            
            var topicType: AmongChat.Topic {
                return AmongChat.Topic(rawValue: topicId) ?? .chilling
            }
        }
        
        struct RoomEmoji: Codable {
            let topicId: String
            let emojiList: [URL]
            
            var topicType: AmongChat.Topic {
                return AmongChat.Topic(rawValue: topicId) ?? .chilling
            }
        }
        
        struct KeyValue: Codable {
            let key: String
            let value: String
            
            //for avatar guide
            let list: [String]
            
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                key = (try? container.decodeString(.key)) ?? ""
                value = (try? container.decodeString(.value)) ?? ""
                list = (try? container.decodeIfPresent([String].self, forKey: .list)) ?? []
            }
        }
        
        let roomBg: [RoomBg]
        let roomEmoji: [RoomEmoji]
        let changeTip: [KeyValue]
        let chatLanguage: [KeyValue]
        let iosCheckVersion: String
        
        private enum CodingKeys: String, CodingKey {
            case roomBg = "room_bg"
            case roomEmoji = "room_emoji"
            case changeTip = "change_tip"
            case chatLanguage = "chat_language"
            case iosCheckVersion = "ios_check_version"
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            roomBg = try container.decode([RoomBg].self, forKey: .roomBg)
            roomEmoji = try container.decode([RoomEmoji].self, forKey: .roomEmoji)
            changeTip = (try? container.decode([KeyValue].self, forKey: .changeTip)) ?? []
            chatLanguage = (try? container.decode([KeyValue].self, forKey: .chatLanguage)) ?? []
            iosCheckVersion = (try? container.decode(String.self, forKey: .iosCheckVersion)) ?? ""
        }
    }
    
}

extension Entity.GlobalSetting.KeyValue {
    
    enum KeyType: String {
        case avatar
    }
    
}

extension Entity.GlobalSetting {
    
    var avatarVersion: String {
        return changeTipValue(.avatar)
    }
    
    func changeTip(_ key: KeyValue.KeyType) -> KeyValue? {
        guard let tip = changeTip.first(where: { $0.key == key.rawValue }) else {
            return nil
        }
        return tip
    }
    
    func changeTipValue(_ key: KeyValue.KeyType) -> String {
        guard let tip = changeTip.first(where: { $0.key == key.rawValue }) else {
            return ""
        }

        return tip.value
    }
}


extension Entity {
    struct ListData<T: Codable>: Codable {
        var list: [T]?
        var more: Bool?
        private enum CodingKeys: String, CodingKey {
            case list
            case more
        }
    }
    
    struct ContactFriend: Codable, Equatable {
        let phone: String
        let name: String
        let count: Int
    }
}
