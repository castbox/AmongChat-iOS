//
//  Entity.Room.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 17/12/20.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation
import SwiftyUserDefaults

extension Entity {
    
    enum RoomPublicType: String, Codable {
        case `public`
        case `private`
        
//        private enum CodingKeys: String, CodingKey {
//            case `public` = "public"
//            case `private` = "private"
//        }
    }
    
    enum AmongUsZone: Int, Codable {
        case northAmercia
        case asia
        case europe
    }
    
    //房间类型
    struct Room: Codable {
        
        var amongUsCode: String?
        var amongUsZone: AmongUsZone?
        var note: String?
        let roomId: String
        
        var roomUserList: [RoomUser]
        var state: RoomPublicType
        var topicId: AmongChat.Topic
        let topicName: String
        var bgUrl: String?
        
        var isValidAmongConfig: Bool {
            guard topicId == .amongus,
                  let code = amongUsCode,
                  amongUsZone != nil else {
                return false
            }
            return !code.isEmpty
        }
        
        var userListMap: [Int: RoomUser] {
            var map: [Int: RoomUser] = [:]
            roomUserList.forEach { user in
                map[user.seatNo - 1] = user
            }
            return map
        }
        
        var loginUserIsAdmin: Bool {
            return userListMap[0]?.uid == Settings.loginUserId
        }
    }
    
    struct RoomUser: Codable, DefaultsSerializable {
        enum Status: String, Codable, DefaultsSerializable {
            case connected
            case talking
            case blocked
            case muted
            case droped //已下麦
            

            static var _defaults: DefaultsRawRepresentableBridge<Status> {
                return DefaultsRawRepresentableBridge<Status>()
            }
            
            static var _defaultsArray: DefaultsRawRepresentableArrayBridge<[Status]> {
                return DefaultsRawRepresentableArrayBridge<[Status]>()
            }
        }
        
        let uid: Int
        let name: String
        let pictureUrl: String
        let seatNo: Int
        var status: Status?
        var isMuted: Bool?
        let nickname: String?
        
        var isMutedValue: Bool {
            return isMuted ?? false
        }
        private enum CodingKeys: String, CodingKey {
            case uid
            case name
            case pictureUrl = "picture_url"
            case seatNo
            case status
            case isMuted = "is_muted"
            case nickname
        }
    }
}

extension Entity.AmongUsZone {
    var title: String {
        switch self {
        case .northAmercia:
            return "North America"
        case .asia:
            return "Asia"
        case .europe:
            return "Europe"
        }
    }
}
