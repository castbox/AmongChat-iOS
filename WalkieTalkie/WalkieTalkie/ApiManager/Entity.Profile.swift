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
}

func attribuated(with name: String?, isVerified: Bool?, isVip: Bool?, fontSize: CGFloat = 16) -> NSAttributedString {
    let nameString = name ?? ""
    let fullString = NSMutableAttributedString(string: nameString)
    if isVerified == true {
        let font = R.font.nunitoExtraBold(size: fontSize)!
        var extraTopPadding: CGFloat = 0
        var image: UIImage {
            if fontSize == 12 {
                return R.image.icon_verified_13()!
            } else if fontSize > 24  {
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
            } else if fontSize > 24  {
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
    return fullString
}

extension Verifiedable {
    
    func nameWithVerified(fontSize: CGFloat = 16) -> NSAttributedString {
        return attribuated(with: name ?? "", isVerified: isVerified, isVip: isVip, fontSize: fontSize)
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
        var decoBgId: Int?
        var decoSkinId: Int?
        var decoHatId: Int?
        var decoPetId: Int?
        var inGroup: Bool?
        var followersCount: Int?
        var online: Bool?

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
            case online
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
        var more: Bool?
        private enum CodingKeys: String, CodingKey {
            case list
            case more
        }
    }
}

extension Entity.UserProfile {
    var nameWithAge: String {
        if let b = birthday, !b.isEmpty {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd"
            
            if let startDate = dateFormatter.date(from: b)  {
                let endDate = Date()
                
                let calendar = Calendar.current
                let calcAge = calendar.dateComponents([.year], from: startDate, to: endDate)
                
                if let age = calcAge.year?.string, !age.isEmpty {
                    return "\(name ?? ""), \(age)"
                }
            }
        }
        return name ?? ""
    }
    
    func nameWithVerified(fontSize: CGFloat = 16, withAge: Bool = false, isShowVerify: Bool = true) -> NSAttributedString {
        let nameString = withAge ? nameWithAge : (name ?? "")
        return attribuated(with: nameString, isVerified: isShowVerify ? isVerified : false, isVip: isVip, fontSize: fontSize)
    }
}

extension Entity.UserProfile {
    func toRoomUser(with seatNo: Int) -> Entity.RoomUser {
        return Entity.RoomUser(uid: uid, name: name, pic: pictureUrl, seatNo: seatNo, status: .connected, isMuted: false, isMutedByLoginUser: false, isVerified: isVerified, isVip: isVip, decoPetId: decoPetId)
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
