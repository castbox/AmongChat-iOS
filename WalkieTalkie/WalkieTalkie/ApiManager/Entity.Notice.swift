//
//  Entity.Notice.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/4/27.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation

extension Entity {
    
    struct Notice: Codable {
        
        var fromUid: Int
        var uid: Int
        var ms: Date
        
        var message: String
        
        private enum CodingKeys: String, CodingKey {
            case fromUid = "from_uid"
            case uid
            case ms
            case message
        }
        
    }
    
    struct Message: Codable {
        
        var type: String
        var title: String
        var text: String
        var img: String?
        var link: String?
        var objType: String?
        var objId: String?
        
        private enum CodingKeys: String, CodingKey {
            case type
            case title
            case text
            case img
            case link
            case objType = "obj_type"
            case objId = "obj_id"
        }
        
    }
    
}

extension Entity {
    
    struct GroupApplyStat: Codable {
        
        var uid: Int?
        var gid: String
        var topicId: String?
        var cover: String?
        var name: String?
        var description: String?
        var status: Int?
        var createTime: Double?
        var rtcType: String?
        var applyCount: Int?
        
        private enum CodingKeys: String, CodingKey {
            case uid
            case gid
            case topicId
            case cover
            case name
            case description
            case status
            case createTime
            case rtcType
            case applyCount = "apply_count"
        }
        
    }
}
