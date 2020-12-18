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
        var topicId: AmongChat.Topic
        
        init() {
            note = ""
            state = .public
            topicId = .amongus
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
        var topicId: AmongChat.Topic
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
        var newGuide: Bool
        var pictureUrlRaw: String?
        var uid: Int
        var birthday: String?
        var nickname: String?
        
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
            case nickname
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
