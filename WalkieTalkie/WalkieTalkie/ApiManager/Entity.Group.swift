//
//  Entity.Group.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/4/1.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation

extension Entity {
    
    struct GroupProto: Codable {
        var topicId: String
        var cover: String
        var name: String
        var description: String
    }
    
}

extension Entity {
    
    struct Group: Codable {
        var uid: Int
        var gid: String
        var topicId: String
        var cover: String?
        var name: String?
        var description: String?
        var status: Int
        var createTime: Double
        var rtcType: String?
        var topicName: String?
        var coverUrl: String?
        var broadcaster: Entity.UserProfile
        var membersCount: Int
    }
    
}

extension Entity {
    
    struct GroupInfo: Codable {
                
        struct Members: Codable {
            var list: [Entity.UserProfile]
            var count: Int
        }
        
        var group: Group
        var members: Members
        var userStatusInt: Int

        private enum CodingKeys: String, CodingKey {
            case group
            case members
            case userStatusInt = "user_status"
        }
        
    }
    
}

extension Entity.GroupInfo {
    
    enum UserStatus: Int {
        case owner = 1
        case admin
        case memeber
        case applied
        case none
    }
    
    var userStatusEnum: UserStatus? {
        return UserStatus(rawValue: userStatusInt)
    }
}

extension Entity {
    
    struct FollowersToAddToGroup: Codable {
        var list: [Entity.UserProfile]
        var more: Bool
    }
    
}


extension Entity {
    // MARK: - GroupRoom
    struct GroupRoom: Codable, RoomInfoable {
        var roomId: String {
            gid
        }
        
        let uid: Int
        let gid: String
        let cover: String
        let name: String
        let status, createTime: Int
        let coverURL: String
        let broadcaster: Entity.UserProfile
        let membersCount: Int
//        let liveID: String
        let playerCount, onlineUserCount: Int?
        let usersUpdateTime: UInt
        var description: String?
        //
        
        var topicId, topicName: String
        let rtcType: Entity.Room.RtcType?
        let rtcBitRate: Int?
        var userList: [Entity.RoomUser]
        var amongUsCode: String?
        var amongUsZone: AmongUsZone?
        var note: String?
        
        
//        var userListMap: [Int: RoomUser] {
//            var map: [Int: RoomUser] = [:]
//            userList.forEach { user in
//                map[user.seatNo - 1] = user
//            }
//            return map
//        }
        
        var loginUserIsAdmin: Bool {
            return uid == Settings.loginUserId
        }
        
        var topicType: AmongChat.Topic {
            guard let topic = AmongChat.Topic(rawValue: topicId) else {
                return .chilling
            }
            
            return topic
        }
        
        var loginUserSeatNo: Int {
            for (index, user) in userList.enumerated() {
                if user.uid == Settings.loginUserId {
                    return index
                }
            }
            return 0
        }

        enum CodingKeys: String, CodingKey {
            case uid, gid
            case topicId
            case cover, name
            case description = "description"
            case status, createTime, rtcType, topicName
            case coverURL = "coverUrl"
            case broadcaster, membersCount
//            case liveID = "liveId"
            case userList, playerCount
            case usersUpdateTime = "_usersUpdateTime"
            case onlineUserCount = "online_user_count"
            case rtcBitRate = "rtc_bit_rate"
            case amongUsCode
            case amongUsZone
            case note
        }
    }

}
