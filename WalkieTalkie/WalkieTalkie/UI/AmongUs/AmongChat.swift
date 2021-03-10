//
//  AmongChat.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/11/25.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation

struct AmongChat {
    
}


extension AmongChat {
    //
    enum Topic: String, Codable, CaseIterable {
        case amongus
        case roblox
        case fortnite
        case freefire
        case minecraft
        case chilling = "justchatting"
        case callofduty = "callofduty"
        case pubgmobile = "pubgmobile"
        case mobilelegends = "mobilelegends"
        case brawlStars = "brawlstars"
        case animalCrossing = "animalcrossing"
    }
    
    //用户身份
    enum UserRole {
        case normal
        case host
    }
}

extension AmongChat.Topic {
    var roomEmojis: [URL] {
        guard let setting = Settings.shared.globalSetting.value else {
            return []
        }
        return setting.roomEmoji.first(where: { $0.topicType == self })
            .map { $0.emojiList } ?? []
    }
    
    var roomEmojiNames: [String] {
        ["room-emoji-yellow",
        "room-emoji-blue",
        "room-emoji-red",
        "room-emoji-green",
        "room-emoji-bluegreen",
        "room-emoji-darkgreen",
        "room-emoji-purple",
        "room-emoji-orange",
        "room-emoji-pink",
        "room-emoji-brown"]
    }
    
//    var roomBgUrl: URL? {
//        guard let setting = Settings.shared.globalSetting.value else {
//            return nil
//        }
//        return setting.roomBg.first(where: { $0.topicType == self })
//            .map { $0.bgUrl }
//
//    }
    
    var enableNickName: Bool {
        switch self {
        case .amongus, .chilling:
            return false
        default:
            return true
        }
    }
    var productId: Double {
        switch self {
        case .amongus:
        return 1351168404
        case .roblox:
            return 431946152
        case .freefire:
            return 1300146617
        case .minecraft:
            return 479516143
        case .pubgmobile:
            return 1330123889
        case .callofduty:
            return 1287282214
        case .mobilelegends:
            return 1160056295
        case .animalCrossing:
            return 1179915619
        case .brawlStars:
            return 1229016807
        default:
            return 0
        }
    }
    
    var notes: String? {
        switch self {
        case .roblox:
            return R.string.localizable.amongChatRoomRebloxTitle()
        case .minecraft:
            return R.string.localizable.amongChatRoomMinecraftTitle()
        case .freefire:
            return R.string.localizable.amongChatRoomFreefireTitle()
        case .fortnite:
            return R.string.localizable.amongChatRoomFortniteTitle()
        case .callofduty:
            return R.string.localizable.amongChatRoomCallOfDutyTitle()
        case .mobilelegends:
            return R.string.localizable.amongChatRoomMobileLegendsTitle()
        case .pubgmobile:
            return R.string.localizable.amongChatRoomPubgMobileTitle()
        default:
            return nil
        }
    }
}
