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
        case chilling = "justchatting"
    }
    
    //用户身份
    enum UserRole {
        case normal
        case host
    }
    
    enum AmongServiceLocation: Int {
        case northAmerica = 0
        case asia = 1
        case europe = 2
    }
}

extension AmongChat.AmongServiceLocation {
    var text: String {
        switch self {
        case .northAmerica:
            return "North America"
        case .asia:
            return "Asia"
        case .europe:
            return "Europe"
        }
    }
}
