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
