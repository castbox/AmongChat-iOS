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
    
    var roomBgUrl: URL? {
        guard let setting = Settings.shared.globalSetting.value else {
            return nil
        }
        return setting.roomBg.first(where: { $0.topicType == self })
            .map { $0.bgUrl }

    }
    
    var enableNickName: Bool {
        switch self {
        case .roblox, .freefire, .fortnite, .minecraft:
            return true
        default:
            return false
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
        default:
            return 0
        }
    }
}
