//
//  Entity.Room.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 17/12/20.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation
import SwiftyUserDefaults

protocol RTCJoinable {
    var roomId: String { get }
    var rtcType: Entity.Room.RtcType? { get }
    var rtcBitRate: Int? { get }
    var userList: [Entity.RoomUser] { get set }
    var defaultRole: RtcUserRole { get }
}

protocol RoomInfoable: RTCJoinable {
    var topicId: String { get set }
    var topicName: String { get }
    var topicType: AmongChat.Topic { get }
    var loginUserIsAdmin: Bool { get }
    var loginUserSeatNo: Int { get }
    var amongUsCode: String? { get set }
    var amongUsZone: Entity.AmongUsZone? { get set }
    var note: String? { get set }
}

extension RoomInfoable {
    var isGroup: Bool {
        return self is Entity.Group
    }
    
    var userListMap: [Int: Entity.RoomUser] {
        var map: [Int: Entity.RoomUser] = [:]
        userList.forEach { user in
            map[user.seatNo - 1] = user
        }
        return map
    }
}

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
    struct Room: Codable, RoomInfoable {
        
        enum RtcType: String, Codable {
            case agora
            case zego
        }
        
        var amongUsCode: String?
        var amongUsZone: AmongUsZone?
        var note: String?
        let roomId: String
        var userList: [RoomUser]
        var state: RoomPublicType
        var topicId: String
        let topicName: String
        let rtcType: RtcType?
        let rtcBitRate: Int?
        var coverUrl: String?
        //
        var defaultRole: RtcUserRole = .broadcaster
        
        var isValidAmongConfig: Bool {
            guard topicType == .amongus,
                  let code = amongUsCode,
                  amongUsZone != nil else {
                return false
            }
            return !code.isEmpty
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
        
        var loginUserSeatNo: Int {
            for (index, user) in userList.enumerated() {
                if user.uid == Settings.loginUserId {
                    return index
                }
            }
            return 0
        }
        
        enum CodingKeys: String, CodingKey {
            case amongUsCode
            case amongUsZone
            case note
            case roomId
            case userList = "roomUserList"
            case state
            case topicId
            case topicName
            case rtcType
            case rtcBitRate
            case coverUrl
        }
    }
    
    struct RoomSeat {
        let user: RoomUser
        var call: ChatRoom.GroupInfoMessage
    }
    
    struct RoomUser: Codable, Hashable, DefaultsSerializable, Verifiedable {
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
        let pictureUrl: String?
        var seatNo: Int
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
        var nameAnimalCrossing: String?
        var nameBrawlStars: String?
        var topic: AmongChat.Topic?
        var isVerified: Bool?
        var isVip: Bool?
        var decoPetId: Int
        
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
            case .animalCrossing:
                return nameAnimalCrossing
            case .brawlStars:
                return nameBrawlStars
            default:
                return nil
            }
        }
        
        var isEnableEntrance: Bool {
            return Entity.DecorationEntity.entityOf(id: decoPetId)?.url != nil
        }
        
        
        init(uid: Int, name: String?, pic: String?, seatNo: Int = 0, status: Status? = .connected, isMuted: Bool? = false, isMutedByLoginUser: Bool? = false, isVerified: Bool? = false, isVip: Bool? = false, decoPetId: Int? = 0) {
            self.uid = uid
            self.name = name
            self.pictureUrl = pic
            self.seatNo = seatNo
            self.status = status ?? .blocked
            self.isMuted = isMuted ?? false
            self.isMutedByLoginUser = isMutedByLoginUser ?? false
            self.isVerified = isVerified
            self.isVip = isVip;
            self.decoPetId = decoPetId ?? 0
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
            case nameAnimalCrossing = "name_animalcrossing"
            case nameBrawlStars = "name_brawlstars"
            case isVerified = "is_verified"
            case isVip = "is_vip"
            case decoPetId = "deco_pet_id"
        }
        
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let statusValue = try container.decodeStringIfPresent(.status)
            self.status = Status(rawValue: statusValue ?? Status.connected.rawValue) ?? .connected
            self.uid = try container.decodeInt(.uid)
            self.name = try container.decodeString(.name)
            self.pictureUrl = try container.decodeString(.pictureUrl)
            self.seatNo = try container.decodeIntIfPresent(.seatNo) ?? -1
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
            self.nameBrawlStars = try container.decodeStringIfPresent(.nameBrawlStars)
            self.nameAnimalCrossing = try container.decodeStringIfPresent(.nameAnimalCrossing)
            self.isVerified = try container.decodeBoolIfPresent(.isVerified) ?? false
            self.isVip = try container.decodeBoolIfPresent(.isVip) ?? false
            self.decoPetId = try container.decodeIntIfPresent(.decoPetId) ?? 0
        }
    }
    
    struct EmojiItem: Codable {
        
        enum EmojiType: Int, Codable {
            case normal
            case dice //骰子
        }
        let id: Int
        let img: String
        let price: Int //value 0 is free emoji
        let duration: Int //value 0 is free emoji
        let hide_delay_sec: Int
        let resource: [String]
        let type: EmojiType
        var isEnable: Bool = true
        
        static func empty() -> EmojiItem {
            return EmojiItem(id: 0, img: "", price: 0, duration: 0, hide_delay_sec: 0, resource: [], type: .normal)
        }
        
        private enum CodingKeys: String, CodingKey {
            case id
            case img
            case price
            case duration
            case hide_delay_sec
            case resource
            case type
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
