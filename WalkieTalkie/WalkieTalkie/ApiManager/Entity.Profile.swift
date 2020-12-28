//
//  Entity.Profile.swift
//  WalkieTalkie
//
//  Created by zhang dekai on 2020/12/25.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation

extension Entity {
    
    struct ProfilePage: Codable {
        var profile: UserProfile?
        var followData: RelationData?
        var relationData: RelationData?
        
        private enum CodingKeys: String, CodingKey {
            case profile
            case followData = "follow_data"
            case relationData = "relation_data"
        }
    }
    
    
    struct RelationData: Codable {
        var followingCount: Int?
        var followersCount: Int?
        var isBlocked: Bool?
        var isFollowed: Bool?
        
        private enum CodingKeys: String, CodingKey {
            case isBlocked = "is_blocked"
            case followingCount = "following_count"
            case followersCount = "followers_count"
            case isFollowed = "is_followed"
        }
    }
    
    struct FollowData: Codable {
        var list: [UserProfile]?
        var more: Bool?
        private enum CodingKeys: String, CodingKey {
            case list
            case more
        }
    }
}
