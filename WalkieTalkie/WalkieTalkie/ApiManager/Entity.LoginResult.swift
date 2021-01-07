//
//  Request.Entity.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/12/16.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation

extension Entity {
    
    public enum LoginProvider: String {
        case google
        case apple
        case snapchat
        case facebook
    }
}

extension Entity {
    
    struct LoginResult: Codable {
        
        var uid: Int
        var access_token: String
        var provider: String

        var source: String?
        
        // will be deprecated soon
        var firebase_custom_token: String
        //
        
        var picture_url: String?
        var name: String?
        var is_login: Bool?
        var is_new_user: Bool?
        var new_guide: Bool?
        
        var create_time : Int64?
    }
}

extension Entity {
    struct RoomProto: Encodable {
        var note: String
        var state: RoomPublicType
        var topicId: String
        
        init() {
            note = ""
            state = .public
            topicId = AmongChat.Topic.chilling.rawValue
        }
        
        var topicType: AmongChat.Topic {
            guard let topic = AmongChat.Topic(rawValue: topicId) else {
                return .chilling
            }
            
            return topic
        }
    }
}

extension Entity {
    
    struct Summary: Codable {
        var title: String?
        var topicList: [SummaryTopic]
    }
    
}

extension Entity {
    
    struct SummaryTopic: Codable {
        var topicId: String
        var coverUrl: String?
        var bgUrl: String?
        var playerCount: Int?
        var topicName: String?
        
        private enum CodingKeys: String, CodingKey {
            case topicId
            case coverUrl = "cover_url"
            case bgUrl = "bg_url"
            case playerCount
            case topicName
        }
        
    }
    
}

extension Entity {
    struct UserProfile: Codable {
        var googleAuthData: ThirdPartyAuthData?
        var appleAuthData: ThirdPartyAuthData?
        var pictureUrl: String?
        var name: String?
        var email: String?
        var newGuide: Bool?
        var pictureUrlRaw: String?
        var uid: Int
        var birthday: String?
        var nameRoblox: String?
        var nameFortnite: String?
        var nameFreefire: String?
        var isFollowed: Bool?
        var opTime: Double?
        var invited: Bool?
        
        private enum CodingKeys: String, CodingKey {
            case googleAuthData = "google_auth_data"
            case appleAuthData = "apple_auth_data"
            case pictureUrl = "picture_url"
            case name
            case email
            case newGuide = "new_guide"
            case pictureUrlRaw = "picture_url_raw"
            case uid
            case birthday
            case isFollowed = "is_followed"
            case opTime = "op_time"
            case invited = "invited"
            case nameRoblox = "name_roblox"
            case nameFortnite = "name_fortnite"
            case nameFreefire = "name_freefire"
        }
    }
    
    struct ThirdPartyAuthData: Codable {
        var id: String
        var pictureUrl: String?
        var name: String?
        var email: String?
        private enum CodingKeys: String, CodingKey {
            case id
            case pictureUrl = "picture_url"
            case name
            case email
        }
    }
    
    struct AvatarData: Codable {
        
        let avatarList: [String]?
        
        private enum CodingKeys: String, CodingKey {
            case avatarList = "avatar_list"
        }
    }
}

extension Entity {
    
    struct ProfileProto: Codable {
        var birthday: String?
        var name: String?
        var pictureUrl: String?
        private enum CodingKeys: String, CodingKey {
            case birthday
            case name
            case pictureUrl = "picture_url"
        }
    }
    
}

extension Entity {
    
    struct DefaultAvatars: Codable {
        
        var avatarList: [DefaultAvatar]
        
        private enum CodingKeys: String, CodingKey {
            case avatarList = "avatar_list"
        }
    }
    
}

extension Entity {
    
    struct DefaultAvatar: Codable {
        var avatarId: String
        var url: String
        var lock: Bool
        var unlockType: String
        var selected: Bool
        private enum CodingKeys: String, CodingKey {
            case avatarId = "avatar_id"
            case url
            case lock
            case unlockType = "type"
            case selected
        }
    }
    
}

extension Entity.DefaultAvatars {
    
    var randomAvatar: Entity.DefaultAvatar? {
        return avatarList.randomItem()
    }
    
}

extension Entity {
    
    struct PlayingUser: Codable {
        var user: UserProfile
        
        struct Room: Codable {
            var roomId: String
            var state: RoomPublicType
            var topicId: String
            var playerCount: Int
            var topicName: String
            
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                
                self.roomId = try container.decodeString(.roomId)
                let stateStr = (try? container.decodeString(.state)) ?? ""
                self.state = RoomPublicType(rawValue: stateStr) ?? .private
                self.topicId = try container.decodeString(.topicId)
                self.playerCount = (try? container.decodeInt(.playerCount)) ?? 0
                self.topicName = try container.decodeString(.topicName)
            }
            
            #if DEBUG
            
            init() {
                roomId = "asdfasf"
                state = .public
                topicId = "amongus"
                playerCount = 0
                topicName = "Among Us"
            }
            
            static func defaultRoom() -> Room {
                
                var room = Room()
                
                return room
            }
            #endif
        }
        
        var room: Room?
        
    }
}

extension Entity {
    struct FriendUpdatingInfo: Codable {
        typealias Room = PlayingUser.Room
        var user: UserProfile
        var room: Room?
        var isOnline: Bool?
        var messageType: String
        
        private enum CodingKeys: String, CodingKey {
            case user
            case room
            case messageType = "message_type"
        }
        
        func asPlayingUser() -> PlayingUser {
            return PlayingUser(user: user, room: room)
        }
        
    }
}
