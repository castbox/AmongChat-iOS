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
//        var bgUrl: String?
        
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
    
    struct RoomUser: Codable, DefaultsSerializable, Verifiedable {
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
        var name: String?
        let pictureUrl: String
        let seatNo: Int
        var status: Status
        var isMuted: Bool
        var isMutedByLoginUser: Bool
        var nameRoblox: String?
        var nameFortnite: String?
        var nameFreefire: String?
        var nameMinecraft: String?
        var nameCallofduty: String?
        var namePubgmobile: String?
        var nameMobilelegends: String?
        var topic: AmongChat.Topic?
        var isVerified: Bool?
        var isVip: Bool?
        
        var nickname: String? {
            switch topic {
            case .fortnite:
                return nameFortnite
            case .freefire:
                return nameFreefire
            case .roblox:
                return nameRoblox
            case .minecraft:
                return nameMinecraft
            case .callofduty:
                return nameCallofduty
            case .pubgmobile:
                return namePubgmobile
            case .mobilelegends:
                return nameMobilelegends
            default:
                return nil
            }
        }
        
        
        init(uid: Int, name: String, pic: String, seatNo: Int = 0, status: Int? = 0, isMuted: Bool? = false, isMutedByLoginUser: Bool? = false, isVerified: Bool = false) {
            self.uid = uid
            self.name = name
            self.pictureUrl = pic
            self.seatNo = seatNo
            self.status = Status(rawValue: "blocked") ?? .blocked
            self.isMuted = isMuted ?? false
            self.isMutedByLoginUser = isMutedByLoginUser ?? false
            self.isVerified = isVerified
        }
        
        private enum CodingKeys: String, CodingKey {
            case uid
            case name
            case pictureUrl = "picture_url"
            case seatNo
            case status
            case isMuted = "is_muted"
            case isMutedByLoginUser
            case nameRoblox = "name_roblox"
            case nameFortnite = "name_fortnite"
            case nameFreefire = "name_freefire"
            case nameMinecraft = "name_minecraft"
            case nameCallofduty = "name_callofduty"
            case namePubgmobile = "name_pubgmobile"
            case nameMobilelegends = "name_mobilelegends"
            case isVerified = "is_verified"
            case isVip = "is_vip"
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let statusValue = try container.decodeStringIfPresent(.status)
            self.status = Status(rawValue: statusValue ?? Status.connected.rawValue) ?? .connected
            self.uid = try container.decodeInt(.uid)
            self.name = try container.decodeString(.name)
            self.pictureUrl = try container.decodeString(.pictureUrl)
            self.seatNo = try container.decodeInt(.seatNo)
//            self.status = try container.decodeString(.status)
            self.isMuted = try container.decodeBoolIfPresent(.isMuted) ?? false
            self.isMutedByLoginUser = try container.decodeBoolIfPresent(.isMutedByLoginUser) ?? false
            self.nameRoblox = try container.decodeStringIfPresent(.nameRoblox)
            self.nameFortnite = try container.decodeStringIfPresent(.nameFortnite)
            self.nameFreefire = try container.decodeStringIfPresent(.nameFreefire)
            self.nameMinecraft = try container.decodeStringIfPresent(.nameMinecraft)
            self.nameCallofduty = try container.decodeStringIfPresent(.nameCallofduty)
            self.namePubgmobile = try container.decodeStringIfPresent(.namePubgmobile)
            self.nameMobilelegends = try container.decodeStringIfPresent(.nameMobilelegends)
            self.isVerified = try container.decodeBoolIfPresent(.isVerified) ?? false
            self.isVip = try container.decodeBoolIfPresent(.isVip) ?? false
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
