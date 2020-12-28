//
//  Entity.Profile.swift
//  WalkieTalkie
//
//  Created by zhang dekai on 2020/12/25.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation

extension Entity {
    
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
}
