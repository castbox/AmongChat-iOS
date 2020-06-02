//
//  Room.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/5/26.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation
import SwiftyUserDefaults

struct Room: Codable, DefaultsSerializable {
    
    enum RoomType: String, DefaultsSerializable, Codable {
        case `default`
        case add //add new
        case empty
        
        static var _defaults: DefaultsRawRepresentableBridge<RoomType> {
            return DefaultsRawRepresentableBridge<RoomType>()
        }
        
        static var _defaultsArray: DefaultsRawRepresentableArrayBridge<[RoomType]> {
            return DefaultsRawRepresentableArrayBridge<[RoomType]>()
        }
    }
    
    static let `default` = Room(name: "WELCOME", user_count: 0)
    static let empty = Room(name: "", user_count: 0, type: .empty)
    static let add = Room(name: "Create new", user_count: 0, type: .add)

    let name: String
    let user_count: Int
    var joinAt: TimeInterval
    let persistence: Bool
    let type: RoomType
    
    init(name: String,
         user_count: Int,
         joinAt: TimeInterval = Date().timeIntervalSince1970,
         persistence: Bool = false,
         type: RoomType = .default) {
        self.name = name
        self.user_count = user_count
        self.joinAt = joinAt
        self.persistence = persistence
        self.type = type
    }
    
    static func empty(for mode: Mode) -> Room {
        return Room(name: mode == .public ? "": "_", user_count: 0)
    }
    
    mutating func updateJoinInterval() {
        joinAt = Date().timeIntervalSince1970
    }
    
    var isValidForPrivateChannel: Bool {
        guard isPrivate, !persistence else {
            return true
        }
        let interval = Date().timeIntervalSince1970
        return (interval - joinAt) < 10 * 24 * 60 * 60 //10天
    }
    
    var showName: String {
        return name.showName
    }
    
    var isReachMaxUser: Bool {
        return FireStore.channelConfig.isReachMaxUser(self).0
    }
    
    var userCountForShow: String {
        let (isReachMaxUser, maxCount) = FireStore.channelConfig.isReachMaxUser(self)
        if isReachMaxUser {
            return maxCount.string
        } else {
            return user_count.string
        }
    }
    
    var isPrivate: Bool {
        return name.hasPrefix("_")
    }
}

extension String {
    var showName: String {
        if isPrivate {
            guard let name = split(bySeparator: "_").last else {
                return self
            }
//            guard name.count == PasswordGenerator.shared.totalCount else {
            return name
//            }
//            let start = name.index(name.startIndex, offsetBy: 2)
//            let end = name.endIndex
//            return name.replacingCharacters(in: start ..< end, with: "******")
        } else {
            return self
        }
    }
    
    var publicName: String? {
        return split(bySeparator: "_").last
    }
    
    var isPrivate: Bool {
        return hasPrefix("_")
    }
    
    var channelType: ChannelType {
        return isPrivate ? .private : .public
    }
}
