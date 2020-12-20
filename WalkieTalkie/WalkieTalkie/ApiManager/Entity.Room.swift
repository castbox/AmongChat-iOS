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
        case northAmercia = 1
        case asia = 2
        case europe = 3
    }
    
    //房间类型
    struct Room: Codable {
        
        var amongUsCode: String?
        var amongUsZone: AmongUsZone?
        var note: String?
        let roomId: String
        
        var roomUserList: [RoomUser]
        var state: RoomPublicType
        var topicId: String
        let topicName: String
        var bgUrl: String?
        
        var isValidAmongConfig: Bool {
            guard topicType == .amongus,
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
        
        var topicType: AmongChat.Topic {
            guard let topic = AmongChat.Topic(rawValue: topicId) else {
                return .chilling
            }
            
            return topic
        }
    }
    
    struct RoomUser: Codable, DefaultsSerializable {
        enum Status: String, Codable, DefaultsSerializable {
            case connected
            case talking
            case blocked
            case muted
            case droped //已下麦
//            case mutedByLoginUser
            

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
        var status: Status
        var isMuted: Bool
        var isMutedByLoginUser: Bool
        let nickname: String?
        
        private enum CodingKeys: String, CodingKey {
            case uid
            case name
            case pictureUrl = "picture_url"
            case seatNo
            case status
            case isMuted = "is_muted"
            case nickname
            case isMutedByLoginUser
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            var statusValue = try container.decodeStringIfPresent(.status)
            self.status = Status(rawValue: statusValue ?? Status.connected.rawValue) ?? .connected
            self.uid = try container.decodeInt(.uid)
            self.name = try container.decodeString(.name)
            self.pictureUrl = try container.decodeString(.pictureUrl)
            self.seatNo = try container.decodeInt(.seatNo)
//            self.status = try container.decodeString(.status)
            self.isMuted = try container.decodeBoolIfPresent(.isMuted) ?? false
            self.isMutedByLoginUser = try container.decodeBoolIfPresent(.isMutedByLoginUser) ?? false
            self.nickname = try container.decodeStringIfPresent(.nickname)
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
