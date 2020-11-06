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
    
    struct Emoji: Codable {
        let chars: [String]
        let updated: String //key
    }
    
    static let `default` = Room(name: "WELCOME", user_count: 0)
    static let empty = Room(name: "", user_count: 0, type: .empty)
    static let add = Room(name: "Create new", user_count: 0, type: .add)

    let name: String
    let user_count: Int
    var joinAt: TimeInterval
    let persistence: Bool?
    let type: RoomType
    let emoji: Emoji?
    var user_list: [UInt] = []
    
    init(name: String,
         user_count: Int,
         joinAt: TimeInterval = Date().timeIntervalSince1970,
         persistence: Bool = false,
         type: RoomType = .default,
         emoji: Emoji? = nil) {
        self.name = name
        self.user_count = user_count
        self.joinAt = joinAt
        self.persistence = persistence
        self.type = type
        self.emoji = emoji
    }
    
    static func empty(for mode: Mode) -> Room {
        return Room(name: mode == .public ? "": "_", user_count: 0)
    }
    
    mutating func updateJoinInterval() {
        joinAt = Date().timeIntervalSince1970
    }
    
    var isValidForPrivateChannel: Bool {
        guard isPrivate, !(persistence ?? false) else {
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


struct ChannelUser: Codable, DefaultsSerializable {
    enum Status: String, Codable, DefaultsSerializable {
        case connected
        case talking
        case blocked
        case muted
        case droped //已下麦
        

        static var _defaults: DefaultsRawRepresentableBridge<Status> {
            return DefaultsRawRepresentableBridge<Status>()
        }
        
        static var _defaultsArray: DefaultsRawRepresentableArrayBridge<[Status]> {
            return DefaultsRawRepresentableArrayBridge<[Status]>()
        }
    }
    
    let uid: UInt
    let name: String
    let prefix: String
    let iconColor: String
    var status: Status
    var isMuted: Bool
    
    private static let colors: [String] = [
        "F5CEC7",
        "FFB384",
        "FFC98B",
        "C6C09C",
        "BD9DDE"
    ]
    
    private static let tag: [String] = [
        "A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
    ]
    
    static func randomUser(uid: UInt) -> ChannelUser {
        return ChannelUser(uid: uid, name: "User - \(uid)", prefix: tag.randomItem() ?? "A", iconColor: colors.randomItem() ?? "F5CEC7", status: .connected, isMuted: false)
    }
}


extension ChannelUser.Status {
    var title: String {
        switch self {
        case .connected, .droped:
            return "Connected"
        case .talking:
            return "Talking..."
        case .blocked:
            return "Blocked"
        case .muted:
            return "Mute"
        }
    }
    
    var textColor: UIColor {
        switch self {
        case .talking:
            return "81BB01".color()
        default:
            return UIColor.black.alpha(0.54)
        }
    }
    
    var micImage: UIImage? {
        switch self {
        case .blocked:
            return R.image.icon_user_list_mic_block()
        case .talking:
            return  R.image.icon_user_list_mic()
        case .connected, .droped:
            return  nil
        case .muted:
            return R.image.icon_user_list_mic_block()
        }
    }
}
