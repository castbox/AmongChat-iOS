//
//  Entity.Profile.swift
//  WalkieTalkie
//
//  Created by zhang dekai on 2020/12/25.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

protocol Verifiedable {
    var name: String? { get set }
    var isVerified: Bool? { get set }
    var isVip: Bool? { get set }
    var isOfficial: Bool? { get set }
}

enum Constellation: String, Codable {
    case aquarius = "Aquarius"
    case pisces = "Pisces"
    case aries = "Aries"
    case taurus = "Taurus"
    case gemini = "Gemini"
    case cancer = "Cancer"
    case leo = "Leo"
    case virgo = "Virgo"
    case libra = "Libra"
    case scorpio = "Scorpio"
    case sagittarius = "Sagittarius"
    case capricorn = "Capricorn"
}

enum Pronoun: Int {
    case pronounNotShare = 0
    case pronounHe
    case pronounShe
    case pronounThey
    case pronounOther
}

func attribuated(with name: String?, isVerified: Bool?, isVip: Bool?, isOfficial: Bool?, officialHeight: OfficialBadgeView.HeightStyle = ._18, fontSize: CGFloat = 16) -> NSAttributedString {
    let nameString = name ?? ""
    let fullString = NSMutableAttributedString(string: nameString)
    if isVerified == true {
        let font = R.font.nunitoExtraBold(size: fontSize)!
        var extraTopPadding: CGFloat = 0
        var image: UIImage {
            if fontSize == 12 {
                return R.image.icon_verified_13()!
            } else if fontSize >= 24  {
                extraTopPadding = -2
                return R.image.icon_verified_20()!
            }
            return R.image.icon_verified()!
        }
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = image
        imageAttachment.bounds = CGRect(x: 0, y: (font.capHeight - image.size.height)/2 + extraTopPadding, width: image.size.width, height: image.size.height)

        let imageString = NSAttributedString(attachment: imageAttachment)
        fullString.yy_appendString(" ")
        fullString.append(imageString)

    }
    if isVip == true {
        let font = R.font.nunitoExtraBold(size: fontSize)!
        var extraTopPadding: CGFloat = 0
        var image: UIImage {
            if fontSize == 12 {
                return R.image.icon_vip_13()!
            } else if fontSize >= 24  {
                extraTopPadding = -2
                return R.image.icon_vip_20()!
            }
            return R.image.icon_vip()!
        }
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = image
        imageAttachment.bounds = CGRect(x: 0, y: (font.capHeight - image.size.height)/2 + extraTopPadding, width: image.size.width, height: image.size.height)

        let imageString = NSAttributedString(attachment: imageAttachment)
        fullString.yy_appendString(" ")
        fullString.append(imageString)
    }
    
    if isOfficial == true {
        let b = OfficialBadgeView(heightStyle: officialHeight)
        
        if let image = b.asImage() {
            let font = R.font.nunitoExtraBold(size: fontSize)!
            let extraTopPadding: CGFloat = 0
            let imageAttachment = NSTextAttachment()
            imageAttachment.image = image
            imageAttachment.bounds = CGRect(x: 0, y: (font.capHeight - image.size.height)/2 + extraTopPadding, width: image.size.width, height: image.size.height)
            
            let imageString = NSAttributedString(attachment: imageAttachment)
            fullString.yy_appendString(" ")
            fullString.append(imageString)
        }
    }
    
    return fullString
}

extension Verifiedable {
    
    func nameWithVerified(fontSize: CGFloat = 16, isShowVerify: Bool = true, isShowOfficial: Bool = true, officialHeight: OfficialBadgeView.HeightStyle = ._18) -> NSAttributedString {
        return attribuated(with: name, isVerified: isShowVerify ? isVerified : false, isVip: isVip, isOfficial: isShowOfficial ? isOfficial : false, officialHeight: officialHeight, fontSize: fontSize)
    }
}

extension Entity {
    struct UserProfile: Codable {
        enum Role: Int {
            case none = 0
            case admin
            case monitor
        }
        
        var uid: Int
        var googleAuthData: ThirdPartyAuthData?
        var appleAuthData: ThirdPartyAuthData?
        var pictureUrl: String?
        var name: String?
        var email: String?
        var newGuide: Bool?
        var pictureUrlRaw: String?
        var birthday: String?
        var countryCode: String? // 国家，如cn，us
        var hideLocation: Bool? // true/false
        var gender: Int? //   0-保密，1-男，2-女, 3-中性
        var constellation: Constellation? // 星座，字符串，如Aries
        var description: String? // 个人介绍
        var nameRoblox: String?
        var nameFortnite: String?
        var nameFreefire: String?
        var nameMineCraft: String?
        var nameCallofduty: String?
        var namePubgmobile: String?
        var nameMobilelegends: String?
        var nameAnimalCrossing: String?
        var nameBrawlStars: String?
        var isFollowed: Bool?
        var opTime: Double?
        var invited: Bool?
        var chatLanguage: String?
        var isVerified: Bool?
        var isVip: Bool?
        var isOfficial: Bool?
        var decoBgId: Int?
        var decoSkinId: Int?
        var decoHatId: Int?
        var decoPetId: Int?
        var inGroup: Bool?
        var followersCount: Int?
        var isAnonymous: Bool?
        var isOnline: Bool?
        
        var role: Int?
        
        var roleType: Role {
            Role(rawValue: role ?? 0) ?? .none
        }
        
        var isSuperAdmin: Bool {
            roleType == .admin
        }
        
        var isMonitor: Bool {
            roleType == .monitor
        }
        
        var isOnlineValue: Bool {
            isOnline ?? false
        }
        
        var pronoun: Pronoun {
            Pronoun(rawValue: gender ?? 0) ?? .pronounNotShare
        }
        
        func hostNickname(for topicType: AmongChat.Topic) -> String? {
            switch topicType {
            case .fortnite:
                return nameFortnite
            case .freefire:
                return nameFreefire
            case .roblox:
                return nameRoblox
            case .minecraft:
                return nameMineCraft
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
            case countryCode = "country_code"
            case hideLocation = "hide_location"
            case gender
            case constellation
            case description
            case isFollowed = "is_followed"
            case opTime = "op_time"
            case invited = "invited"
            case nameRoblox = "name_roblox"
            case nameFortnite = "name_fortnite"
            case nameFreefire = "name_freefire"
            case nameMineCraft = "name_minecraft"
            case nameCallofduty = "name_callofduty"
            case namePubgmobile = "name_pubgmobile"
            case nameMobilelegends = "name_mobilelegends"
            case nameAnimalCrossing = "name_animalcrossing"
            case nameBrawlStars = "name_brawlstars"
            case chatLanguage = "language_u"
            case isVerified = "is_verified"
            case isVip = "is_vip"
            case decoBgId = "deco_bg_id"
            case decoSkinId = "deco_skin_id"
            case decoHatId = "deco_hat_id"
            case decoPetId = "deco_pet_id"
            case inGroup = "in_group"
            case followersCount = "followers_count"
            case role
            case isAnonymous = "is_anonymous"
            case isOfficial = "is_official"
            case isOnline = "is_online"
        }
    }
    
    struct ProfilePage: Codable {
        var profile: UserProfile?
        var followData: RelationData?
        var relationData: RelationData?
        
        private enum CodingKeys: String, CodingKey {
            case profile
            case followData = "follow_data"
            case relationData = "relation_data"
        }
    }
    
    
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
    
    struct FollowData: Codable {
        var list: [UserProfile]?
        var more: Bool?
        private enum CodingKeys: String, CodingKey {
            case list
            case more
        }
    }
    
    struct SearchData: Codable {
        var list: [UserProfile]?
        var welfare: Entity.DecorationEntity?
        var more: Bool?
        var type: String
        private enum CodingKeys: String, CodingKey {
            case list
            case welfare
            case more
            case type
        }
    }
}

extension Pronoun {
    var title: String {
        switch self {
        case .pronounNotShare:
//            return R.string.localizable.profilePronounNotShare()
            return ""
        case .pronounHe:
            return R.string.localizable.profilePronounHeHim()
        case .pronounShe:
            return R.string.localizable.profilePronounSheHer()
        case .pronounThey:
            return R.string.localizable.profilePronounTheyThem()
        case .pronounOther:
            return R.string.localizable.profilePronounOther()
        }
    }
    
    var logString: String {
        switch self {
        case .pronounNotShare:
            return "not_share"
        case .pronounHe:
            return "he"
        case .pronounShe:
            return "she"
        case .pronounThey:
            return "they"
        case .pronounOther:
            return "other"
        }
    }
}

extension Constellation {
    var title: String {
        switch self {
        case .aquarius:
            return R.string.localizable.profileConstellationAquarius()
        case .pisces:
            return R.string.localizable.profileConstellationPisces()
        case .aries:
            return R.string.localizable.profileConstellationAries()
        case .taurus:
            return R.string.localizable.profileConstellationTaurus()
        case .gemini:
            return R.string.localizable.profileConstellationGemini()
        case .cancer:
            return R.string.localizable.profileConstellationCancer()
        case .leo:
            return R.string.localizable.profileConstellationLeo()
        case .virgo:
            return R.string.localizable.profileConstellationVirgo()
        case .libra:
            return R.string.localizable.profileConstellationLibra()
        case .scorpio:
            return R.string.localizable.profileConstellationScorpio()
        case .sagittarius:
            return R.string.localizable.profileConstellationSagittarius()
        case .capricorn:
            return R.string.localizable.profileConstellationCapricorn()
        }
    }
}

extension Entity.UserProfile {
    var dmProfile: Entity.DMProfile {
        Entity.DMProfile(uid: uid.int64, name: name, pictureUrl: pictureUrl, isVerified: isVerified, isVip: isVip, isOfficial: isOfficial)
    }
    
    var age: String? {
        
        guard let b = birthday,
              !b.isEmpty else {
            return nil
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"

        guard let startDate = dateFormatter.date(from: b) else {
            return nil
        }

        let endDate = Date()
        let calendar = Calendar.current
        
        let calcAge = calendar.dateComponents([.year], from: startDate, to: endDate)
        
        guard let age = calcAge.year?.string,
              !age.isEmpty else {
            return nil
        }
        
        return age
    }
    
    var nameWithAge: String {
        if let age = age, !age.isEmpty {
            return "\(name ?? ""), \(age)"
        }
        return name ?? ""
    }
    
    func nameWithVerified(fontSize: CGFloat = 16, withAge: Bool = false, isShowVerify: Bool = true, isShowOfficial: Bool = true, officialHeight: OfficialBadgeView.HeightStyle = ._18) -> NSAttributedString {
        let nameString = withAge ? nameWithAge : (name ?? "")
        return attribuated(with: nameString, isVerified: isShowVerify ? isVerified : false, isVip: isVip, isOfficial: isShowOfficial ? isOfficial : false, officialHeight: officialHeight, fontSize: fontSize)
    }
    
    var locale: String? {
        
        guard !(hideLocation ?? false),
            let code = countryCode else {
            return nil
        }
        
        return Locale(identifier: code).localizedString(forRegionCode: code)
    }
}

extension Entity.UserProfile {
    func toRoomUser(with seatNo: Int) -> Entity.RoomUser {
        return Entity.RoomUser(uid: uid, name: name, pic: pictureUrl, seatNo: seatNo, status: .connected, isMuted: false, isMutedByLoginUser: false, isVerified: isVerified, isVip: isVip, decoPetId: decoPetId, isOfficial: isOfficial)
    }
}


extension Entity {
    struct CallInUser {
        var uid: Int { user.uid }
        var user: UserProfile { message.user }
        var message: Peer.CallMessage
        //开始通话时间戳
        var startTimeStamp: Double?
        
    }
}

protocol ProfileLiveRoom {
    var roomCover: String { get }
    var roomName: String { get }
    var isPrivate: Bool { get }
}

extension Entity {
    
    struct UserStatus: Codable {
        
        var uid: Int
        var room: Room?
        var group: Group?
        var isOnline: Bool?
        
        private enum CodingKeys: String, CodingKey {
            case uid
            case room
            case group
            case isOnline = "is_online"
        }
        
        struct Room: Codable, ProfileLiveRoom {

            var roomCover: String {
                return coverUrl ?? ""
            }
            
            var roomName: String {
                return R.string.localizable.profileUserInChannel(topicName)
            }
            
            var isPrivate: Bool {
                return state == "private"
            }
            
            let roomId: String
            let state: String
            let topicId: String
            let playerCount: Int?
            let topicName: String
            let coverUrl: String?
        }
        
        struct Group: Codable, ProfileLiveRoom {
            var roomCover: String {
                return cover
            }
            
            var roomName: String {
                return R.string.localizable.profileUserInGroup(name)
            }
            
            var isPrivate: Bool {
                return false
            }

            var gid: String
            var topicId: String
            var status: Int
            var name: String
            var cover: String
            var uid: Int
            var topicName: String
        }
    }
    
}
