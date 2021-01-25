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
    var isVerified: Bool? {  get set }
}

extension Verifiedable {
    func nameWithVerified(fontSize: CGFloat = 16) -> NSAttributedString {
        let nameString = name ?? ""
        guard isVerified == true else {
            return NSAttributedString(string: nameString)
        }
        let font = R.font.nunitoExtraBold(size: fontSize)!
        var image: UIImage {
            if fontSize == 12 {
                return R.image.icon_verified_13()!
            } else if fontSize > 24  {
                return R.image.icon_verified_24()!
            }
            return R.image.icon_verified()!
        }
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = image
        imageAttachment.bounds = CGRect(x: 0, y: (font.capHeight - image.size.height)/2, width: image.size.width, height: image.size.height)

        let imageString = NSAttributedString(attachment: imageAttachment)
        let fullString = NSMutableAttributedString(string: nameString + " ")
        fullString.append(imageString)
        return fullString
    }
}

extension Entity {
    struct UserProfile: Codable {
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
        var isFollowed: Bool?
        var opTime: Double?
        var invited: Bool?
        var chatLanguage: String?
        var isVerified: Bool?
        
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
            case chatLanguage = "language_u"
            case isVerified = "is_verified"
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
    
    func nameWithVerified(fontSize: CGFloat = 16, withAge: Bool = false) -> NSAttributedString {
        let nameString = withAge ? nameWithAge : (name ?? "")
        guard isVerified == true else {
            return NSAttributedString(string: nameString)
        }
        let font = R.font.nunitoExtraBold(size: fontSize)!
        let image = fontSize >= 20 ? R.image.icon_verified_24()! : R.image.icon_verified()!
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = image
        imageAttachment.bounds = CGRect(x: 0, y: (font.capHeight - image.size.height)/2, width: image.size.width, height: image.size.height)

        let imageString = NSAttributedString(attachment: imageAttachment)
        let fullString = NSMutableAttributedString(string: nameString + " ")
        fullString.append(imageString)
        return fullString
    }
}
