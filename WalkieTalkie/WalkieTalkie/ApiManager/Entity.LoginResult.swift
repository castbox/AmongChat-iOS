//
//  Request.Entity.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/12/16.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation
import WCDBSwift

extension Entity {
    
    public enum LoginProvider: String {
        case google
        case apple
        case snapchat
        case facebook
    }
}

extension Entity {
    
    struct LoginResult: Codable {
        enum Provider: String, Codable {
            case facebook
            case google
            case twitter
            case line
            case email
            case apple
            case snapchat
            case phone
            case device
        }
        
        var uid: Int
        var access_token: String
        var provider: Provider

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
        
        var isAnonymousUser: Bool {
            return provider == .device
        }
    }
}

extension Entity {
    struct RoomProto: Encodable {
        
        static let watchAdEntry = "watch_ad"
        static let cardEntry = "free_card"
        
        var note: String
        var state: RoomPublicType
        var topicId: String
        var entry: String?
        
        init() {
            note = ""
            state = .public
            topicId = AmongChat.Topic.chilling.rawValue
        }
        
        var topicType: AmongChat.Topic {
            guard let topic = AmongChat.Topic(rawValue: topicId) else {
                return .chilling
            }
            
            return topic
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
        var topicId: String
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
    
    struct ThirdPartyAuthData: ColumnJSONCodable {
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
    
    struct AvatarData: Codable {
        
        let avatarList: [String]?
        
        private enum CodingKeys: String, CodingKey {
            case avatarList = "avatar_list"
        }
    }
}

extension Entity {
    
    struct ProfileProto: Codable {
        var birthday: String?
        var name: String?
        var pictureUrl: String?
        var chatLanguage: String?
        var countryCode: String? // 国家，如cn，us
        var hideLocation: Bool? // true/false
        var gender: Int? //   0-保密，1-男，2-女, 3-中性
        var constellation: Constellation? // 星座，字符串，如Aries
        var description: String? // 个人介绍
        
        var pronoun: Pronoun {
            Pronoun(rawValue: gender ?? 0) ?? .pronounNotShare
        }
        
        init(birthday: String? = nil,
             name: String? = nil,
             pictureUrl: String? = nil,
             chatLanguage: String? = nil,
             countryCode: String? = nil,
             hideLocation: Bool? = nil,
             gender: Int? = nil,
             constellation: Constellation? = nil,
             description: String? = nil) {
            
            self.birthday = birthday
            self.name = name
            self.pictureUrl = pictureUrl
            self.chatLanguage = chatLanguage
            self.countryCode = countryCode
            self.hideLocation = hideLocation
            self.gender = gender
            self.constellation = constellation
            self.description = description
        }
        
        
        private enum CodingKeys: String, CodingKey {
            case birthday
            case name
            case pictureUrl = "picture_url"
            case chatLanguage = "language_u"
            case countryCode = "country_code"
            case hideLocation = "hide_location"
            case gender
            case constellation
            case description
        }
    }
    
}

extension Entity {
    
    struct DefaultAvatars: Codable {
        
        var avatarList: [DefaultAvatar]
        
        private enum CodingKeys: String, CodingKey {
            case avatarList = "avatar_list"
        }
    }
    
}

extension Entity {
    
    struct DefaultAvatar: Codable {
        
        enum UnlockType: String, Codable {
            case free, rewarded, premium, pay, claim = "hide"
        }
        
        var avatarId: String
        var url: String
        var lock: Bool
        var unlockType: UnlockType?
        var selected: Bool
        private enum CodingKeys: String, CodingKey {
            case avatarId = "avatar_id"
            case url
            case lock
            case unlockType = "type"
            case selected
        }
    }
    
}

extension Entity.DefaultAvatars {
    
    var randomAvatar: Entity.DefaultAvatar? {
        return avatarList.randomItem()
    }
    
}

extension Entity {
    
    struct PlayingUser: Codable {
        var user: Entity.UserProfile
        
        struct Room: Codable {
            var roomId: String?
            var gid: String?
            var state: RoomPublicType
            var topicId: String
            var playerCount: Int
            var topicName: String
            var name: String
            var uid: Int?
            var isGroup: Bool {
                gid != nil
            }
            
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                
                self.roomId = try container.decodeStringIfPresent(.roomId)
                self.gid = try container.decodeStringIfPresent(.gid)
                let stateStr = (try? container.decodeString(.state)) ?? ""
                self.state = RoomPublicType(rawValue: stateStr) ?? .private
                self.topicId = try container.decodeString(.topicId)
                self.playerCount = (try? container.decodeInt(.playerCount)) ?? 0
                let topicName = try container.decodeString(.topicName)
                self.topicName = topicName
                self.name = try container.decodeStringIfPresent(.name) ?? topicName
                self.uid = try? container.decodeInt(.uid)
            }
            
            #if DEBUG
            
            init() {
                roomId = "asdfasf"
                state = .public
                topicId = "amongus"
                playerCount = 0
                topicName = "Among Us"
                name = ""
            }
            
            static func defaultRoom() -> Room {
                
                var room = Room()
                
                return room
            }
            #endif
        }
        
        var room: Room?
        var group: Room?
        
    }
}

extension Entity.PlayingUser {
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.user = try container.decode(Entity.UserProfile.self, forKey: .user)
        self.room = (try? container.decode(Room.self, forKey: .room)) ?? (try? container.decode(Room.self, forKey: .group))
        self.group = try? container.decode(Room.self, forKey: .group)
    }

}

extension Entity {
    
//    struct FriendUpdatingInfo: PeerMessage {
//        
//        typealias Room = PlayingUser.Room
//        var user: UserProfile
//        private var room: Room?
//        var isOnline: Bool?
//        var msgType: Peer.MessageType
//        private var group: Entity.Group?
//        
////        var room: RoomDetailable? {
////            return _room ?? _group
////        }
//        
//        private enum CodingKeys: String, CodingKey {
//            case user
//            case room = "room"
//            case msgType = "message_type"
//            case isOnline = "is_online"
//            case group = "group"
//        }
//        
////        func asPlayingUser() -> PlayingUser {
////            return PlayingUser(user: user, room: room)
////        }
//    }
}

extension Entity {
    
    struct AccountMetaData: Codable {
        var freeRoomCards: Int
        private enum CodingKeys: String, CodingKey {
            case freeRoomCards = "free_room_cards"
        }
    }
}

extension Entity {
    struct Region: Codable {
        var regionCode: String
        var region: String
        var telCode: String
        private enum CodingKeys: String, CodingKey {
            case regionCode = "region_code"
            case region
            case telCode = "tel_code"
        }
        
        static var `default`: Region {
            return Region(regionCode: "US", region: "United States", telCode: "+1")
        }
        
    }
}

extension Entity {
    struct SmsCodeResponse: Codable {
        var code: Int
        struct Data: Codable {
            var expire: Int?
            var token: String?
        }
        var data: Data?
    }
}

extension Entity {
    struct DecorationCategory: Codable {
        var name: String
        var list: [DecorationEntity]
        
        private enum CodingKeys: String, CodingKey {
            case name
            case list
        }
    }
}

extension Entity {
    
    struct DecorationEntity : Codable {
        
        var id: Int
        var url: String?
        var listUrl: String?
        var sayUrl: String?
        var lock: Bool?
        var unlockType: Entity.DefaultAvatar.UnlockType?
        var iapKey: String?
        var decoType: String
        var product: DecorationProduct?
        var selected: Bool?
        var decoList: [DecorationEntity]?
        var hide: Bool?
        var isClaimed: Bool?
        
        private enum CodingKeys: String, CodingKey {
            case id
            case url
            case listUrl = "list_url"
            case sayUrl = "say_url"
            case lock
            case unlockType = "type"
            case iapKey = "iap_key"
            case decoType = "deco_type"
            case product
            case selected
            case decoList = "deco_list"
            case hide
            case isClaimed = "is_claimed"
        }
        
    }
}

extension Entity {
    
    struct DecorationProduct: Codable {
        
        var internalProductId: String
        var products: [IAPProduct]
        
        struct IAPProduct: Codable {
            
            var productId: String
            var deviceType: String
            var price: Int
            var name: String
            
            private enum CodingKeys: String, CodingKey {
                case productId = "product_id"
                case deviceType = "device_type"
                case price
                case name
            }
            
        }
        
        private enum CodingKeys: String, CodingKey {
            case internalProductId = "internal_product_id"
            case products
        }
        
    }

}

extension Entity.DecorationCategory {
    
    enum DecorationType: String, Codable {
        case skin, bg, pet, hat, suit
    }
    
}

extension Entity.DecorationEntity {
    
    static func entityOf(id: Int) -> Entity.DecorationEntity? {
        guard id > 0 else {
            return nil
        }
        let decorations = Settings.shared.defaultProfileDecorationCategoryList.value.flatMap { $0.list }
        
        return decorations.first { $0.id == id }
    }
    
}

extension Entity.UserProfile {
    
    var decorations: [Social.ProfileLookViewController.DecorationViewModel] {
        
        return [decoBgId, decoSkinId, decoHatId, decoPetId]
            .compactMap({
                guard let id = $0,
                      let entity = Entity.DecorationEntity.entityOf(id: id),
                      let decoType = Entity.DecorationCategory.DecorationType.init(rawValue: entity.decoType) else { return nil }
                let deco = Social.ProfileLookViewController.DecorationViewModel(dataModel: entity, decorationType: decoType)
                deco.selected = true
                return deco
            })
    }
    
}

extension Entity {
    
    struct GameSkill: Codable {
        enum Status: Int, Codable {
            case inreview
            case added
            case none
        }
        
        let topicId: String
        let topicName: String
        let coverUrl: String
        let example: String
        let isAdd: Bool
        //
        let status: Int?//，0审核中，1已添加，2或者没有该字段，可添加状态
        var statusType: Status {
            guard let value = status else {
                return .none
            }
            return Status(rawValue: value) ?? .none
        }

        private enum CodingKeys: String, CodingKey {
            case topicId
            case topicName
            case coverUrl = "cover_url"
            case example
            case isAdd = "is_add"
            case status = "status"
        }
    }
    
    struct UserGameSkill: Codable {
        let topicId: String
        let img: String
        let topicName: String
        let example: String
        let h5: String
    }
    
}
