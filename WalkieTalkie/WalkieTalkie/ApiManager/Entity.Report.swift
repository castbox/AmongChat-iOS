//
//  Entity.Report.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 21/04/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation

extension Entity {
    struct Report: Codable {
        
        struct Reason: Codable {
            let reasonId: Int
            let reasonText: String
            
            enum CodingKeys: String, CodingKey {
                case reasonId = "reason_id"
                case reasonText = "reason_text"
            }
        }
        
        struct Source: Codable {
            let room: [Reason]?
            let user: [Reason]?
            let post: [Reason]?
            let comment: [Reason]?
            let reply: [Reason]?
        }
        
        let reportType: [String]
        let reasonDict: Source?
        
        enum CodingKeys: String, CodingKey {
            case reportType = "report_type"
            case reasonDict = "reason_dict"
        }
    }
    
    struct UserMuteInfo: Codable {
        var isMute: Bool
        var isMuteIm: Bool
        
        enum CodingKeys: String, CodingKey {
            case isMute = "is_mute"
            case isMuteIm = "is_mute_im"
        }
        static func empty() -> UserMuteInfo {
            return UserMuteInfo(isMute: false, isMuteIm: false)
        }
    }
}
