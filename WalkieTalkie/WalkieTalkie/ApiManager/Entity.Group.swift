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
        var topicId: String?
        var cover: String?
        var name: String?
        var description: String?
        
        var isValid: Bool {
            
            return !(topicId?.isEmpty ?? true) ||
                !(cover?.isEmpty ?? true) ||
                !(name?.isEmpty ?? true) ||
                !(description?.isEmpty ?? true)
            
        }
    }
    
}

extension Entity {
    
//    struct Group: Codable {
//        var uid: Int
//        var gid: String
//        var topicId: String
//        var cover: String?
//        var name: String?
//        var description: String?
//        var status: Int //0 关播 1 开播
//        var createTime: Double
//        var rtcType: String?
//        var topicName: String?
//        var coverUrl: String?
//        var broadcaster: Entity.UserProfile
//        var membersCount: Int
//    }
    
}

extension Entity {
    
    struct GroupInfo: Codable {
                
        struct Members: Codable {
            var list: [Entity.UserProfile]
            var count: Int
        }
        
        var group: Group
        var members: Members?
        var userStatusInt: Int
        
        var showApplyButton: Bool {
            (userStatusEnum == .some(.applied) || userStatusEnum == .some(.none))
        }

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
    
    var titleForApplyButton: String? {
        switch userStatusEnum {
        case .applied?:
            return R.string.localizable.amongChatGroupApplied()
        case .none?:
            return R.string.localizable.amongChatGroupApplyToJoin()
        default:
            return nil
        }
    }
}

extension Entity {
    
    struct GroupUserList: Codable {
        var list: [Entity.UserProfile]
        var more: Bool
        var count: Int?
    }
    
}


extension Entity {
    // MARK: - GroupRoom
//    struct GroupEnter: Codable {
//        user_status：当前用户与该group的关系
//        GROUP_USER_STATUS_OWNER = 1
//        GROUP_USER_STATUS_ADMIN = 2
//        GROUP_USER_STATUS_MEMBER = 3
//        GROUP_USER_STATUS_APPLIED = 4
//        GROUP_USER_STATUS_NONE = 5
//
//        let userStatus:
//        let processed: Bool
//    }
    
    struct Group: Codable, RoomDetailable {
        var roomId: String {
            gid
        }
        
        let uid: Int
        let gid: String
        //group cover
        let cover: String
        let name: String
        let status: Int //0 关播 1 开播
        let createTime: Int
        let broadcaster: Entity.UserProfile
        let membersCount: Int
        var applyCount: Int?
        var isAskSeat, isHostOff: Bool?
//        let liveID: String
        let playerCount, onlineUserCount: Int?
        let usersUpdateTime: UInt?
        var description: String?
        //
        
        var topicId, topicName: String
        //topic cover url
        let coverURL: String
        let bgUrl: String?
        let rtcType: Entity.Room.RtcType?
        let rtcBitRate: Int?
        var aliasUserList: [Entity.RoomUser]?
        var amongUsCode: String?
        var amongUsZone: AmongUsZone?
        var note: String?
        var robloxLink: String?
        var defaultRole: RtcUserRole {
            loginUserIsAdmin ? .broadcaster : .audience
        }
        
        //开播
        var isLiving: Bool {
            status == 1
        }
        
        var micQueueEnabled: Bool {
            return isAskSeat ?? false
        }
        
        var hostOffLine: Bool {
            return isHostOff ?? false
        }
        
        var userList: [Entity.RoomUser] {
            get {
                guard let l = aliasUserList else {
                    return []
                }
                return l
            }
            
            set {
                aliasUserList = newValue
            }
        }
        
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
            return -1
        }
        
        var hostNickname: String? {
            switch topicType {
            case .fortnite:
                return broadcaster.nameFortnite
            case .freefire:
                return broadcaster.nameFreefire
            case .roblox:
                return broadcaster.nameRoblox
            case .minecraft:
                return broadcaster.nameMineCraft
            case .callofduty:
                return broadcaster.nameCallofduty
            case .pubgmobile:
                return broadcaster.namePubgmobile
            case .mobilelegends:
                return broadcaster.nameMobilelegends
            case .animalCrossing:
                return broadcaster.nameAnimalCrossing
            case .brawlStars:
                return broadcaster.nameBrawlStars
            default:
                return nil
            }
        }

        enum CodingKeys: String, CodingKey {
            case uid, gid
            case topicId
            case cover, name
            case description = "description"
            case status, createTime, rtcType, topicName
            case coverURL = "coverUrl"
            case bgUrl
            case broadcaster, membersCount
//            case liveID = "liveId"
            case playerCount
            case aliasUserList = "userList"
            case usersUpdateTime = "_usersUpdateTime"
            case onlineUserCount = "online_user_count"
            case rtcBitRate = "rtc_bit_rate"
            case amongUsCode
            case amongUsZone
            case note
            case robloxLink
            case applyCount = "apply_count"
            case isAskSeat, isHostOff
        }
    }

}
