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
