//
//  Settings.swift
//  Castbox
//
//  Created by ChenDong on 2017/8/21.
//  Copyright © 2017年 Guru. All rights reserved.
//

import UIKit
import RxSwift
import FirebaseInstanceID
import SwiftyUserDefaults

extension DefaultsKeys {
    /// 用户选择的国家
    static let selectedCountry = DefaultsKey<String?>("CountryCode")
    /// 是否接收following
    static let isPushNotificationReceiveFollowing = DefaultsKey<Bool?>("isPushNotificationReceiveFollowing")
    
    /// 是否接收moments推送
    static let isPushReceiveMoments = DefaultsKey<Bool?>("isPushReceiveMoments")
    
    /// 是否同意接收 system
    static let isPushReceiveSystem = DefaultsKey<Bool?>("isPushReceiveSystem")
    
    static let isPushReceiveMessage = DefaultsKey<Bool?>("isPushReceiveMessage")
    
    /// app 主题
    static let theme = DefaultsKey<Theme.Mode?>("castboxTheme")
    /// cuddle 是否登出
    static let isLogout = DefaultsKey<Bool?>("isLogout")
    
    // room setup 是否刷新
    static let isRoomSetupRefresh = DefaultsKey<Bool?>("isRoomSetupRefresh")
    
    // 用户首次follow
    static let firstFollow = DefaultsKey<Bool?>("firstFollow")
    
    // 用户首次进入直播间
    static let firstJoinLive = DefaultsKey<Bool?>("firstJoinLive")
    
    // 用户首次开播
    static let firstCreateLive = DefaultsKey<Bool?>("firstCreateLive")
    
    // 首次call-in成功
    static let firstCallIn = DefaultsKey<Bool?>("firstCallIn")
    
    // 当用户首次 Login In 成功时
    static let firstLogin = DefaultsKey<Bool?>("firstLogin")
    
    // 当用户首次 发送message
    static let firstSendMsg = DefaultsKey<Bool?>("firstSendMsg")
    
    // 当用户首次充值成功
    static let firstCharge = DefaultsKey<Bool?>("firstCharge")
    
    // 当用户首次打赏成功
    static let firstReward = DefaultsKey<Bool?>("firstReward")
    
    // 轮盘不显示Join alert
    static let rouletteDontRemindOnJoin = DefaultsKey<Bool?>("LV.Room.Roulette.Not.Remind.On.Join")
    
    // 转盘游戏金额
    static let rouletteEntranceFee = DefaultsKey<Int?>("LV.Room.Roulette.Setting.Entrance.Fee")
    
    // 转盘游戏人数
    static let roulettePlayerCount = DefaultsKey<Int?>("LV.Room.Roulette.Setting.Player.Count")
    
    // push fans
    static let pushToFans = DefaultsKey<Int?>("message.push.fans")
    
    // fisrt active
    static let firstActive = DefaultsKey<Int?>("active.first")
    
    // second active
    static let secondActive = DefaultsKey<Int?>("active.second")
    
    static let sensitiveWords = DefaultsKey<[String]?>("setting.sensitive.words")
    
    // second active
    static func dayActiveKey(_ day: Int) -> DefaultsKey<Int?> {
        return DefaultsKey<Int?>("active.second.\(day)")
    }
    
    static let purchasedItemsKey = DefaultsKey<String?>.init("purchased.item.key")
    
    /// pk 匹配直播是否开启语言
    static let isEnableLivePKAudioConnection = DefaultsKey<Bool?>("isEnableLivePKAudioConnection")
}

extension UserDefaults {
    
//    subscript(key: DefaultsKey<Theme.Mode?>) -> Theme.Mode? {
//        get {
//            let mode = numberForKey(key._key)?.intValue
//            return mode.flatMap { Runner.Theme.Mode(rawValue: $0) }
//        }
//        set {
//            set(key, newValue?.rawValue)
//        }
//    }
    
//    subscript(key: DefaultsKey<Settings.SubscriptionViewMode?>) -> Settings.SubscriptionViewMode? {
//        get {
//            let mode = numberForKey(key._key)?.intValue
//            return mode.flatMap { Settings.SubscriptionViewMode(rawValue: $0) }
//        }
//        set {
//            set(key, newValue?.rawValue)
//        }
//    }
    
//    subscript(key: DefaultsKey<Float?>) -> Float? {
//        get {
//            return float(forKey: key._key)
//        }
//        set {
//            set(key, newValue)
//        }
//    }
//
//    subscript(key: DefaultsKey<Settings.SubscriptionSort?>) -> Settings.SubscriptionSort? {
//        get {
//            let mode = numberForKey(key._key)?.intValue
//            return mode.flatMap { Settings.SubscriptionSort(rawValue: $0) }
//        }
//        set {
//            set(key, newValue?.rawValue)
//        }
//    }
    
//    subscript(key: DefaultsKey<[String: String]?>) -> [String: String]? {
//        get {
//            return object(forKey: key._key) as? [String: String]
//        }
//        set {
//            set(key, newValue)
//        }
//    }
//
//    subscript(key: DefaultsKey<[String: Bool]>) -> [String: Bool]? {
//        get {
//            return object(forKey: key._key) as? [String: Bool]
//        }
//        set {
//            set(key, newValue)
//        }
//    }
}

class Settings {
    
    static let shared = Settings()
    
    let countries: [String] = [
        
        "ar", "ae", "au",
        "be", "br",
        "ca", "ch", "cn",
        "de",
        "es",
        "fi", "fr",
        "gb",
        "ie", "in", "it",
        "jp",
        "kr",
        "mx",
        "nl", "no", "nz",
        "pt",
        "ru",
        "se",
        "ua",
        "us"
    ]
    
    /// 用户选择的国家
    let selectedCountry: PublishProperty<String?> = {
        var value = Defaults[.selectedCountry] ?? Locale.current.regionCode?.lowercased()
        return DynamicProperty.stored(value)
            .didSet({ Defaults[.selectedCountry] = $0.new })
            .asPublishProperty()
    }()
    
    /// 是否接收 following 消息
    let isFollowingPushOpen: PublishProperty<Bool> = {
        var value = Defaults[.isPushNotificationReceiveFollowing] ?? true
        return DynamicProperty.stored(value)
            .didSet({ Defaults[.isPushNotificationReceiveFollowing] = $0.new })
            .asPublishProperty()
    }()
    
    /// 是否接收 monments 推送
    let isMomentsPushOpen: PublishProperty<Bool> = {
        var value = Defaults[.isPushReceiveMoments] ?? true
        return DynamicProperty.stored(value)
            .didSet({ Defaults[.isPushReceiveMoments] = $0.new })
            .asPublishProperty()
    }()
    /// 是否同意接收 system message
    let isSystemPushOpen: PublishProperty<Bool> = {
        var value = Defaults[.isPushReceiveSystem] ?? true
        return DynamicProperty.stored(value)
            .didSet({ Defaults[.isPushReceiveSystem] = $0.new })
            .asPublishProperty()
    }()
    
    let isMessagePushOpen: PublishProperty<Bool> = {
        var value = Defaults[.isPushReceiveMessage] ?? true
        return DynamicProperty.stored(value)
            .didSet({ Defaults[.isPushReceiveMessage] = $0.new })
            .asPublishProperty()
    }()
    
    /// app 主题
    let theme: PublishProperty<Theme.Mode> = {
        var value = Defaults[.theme] ?? .light
        return DynamicProperty.stored(value)
            .didSet({ Defaults[.theme] = $0.new })
            .asPublishProperty()
    }()
    
    /// 是否登出
    let isLogout: PublishProperty<Bool> = {
        var value = Defaults[.isLogout] ?? true
        return DynamicProperty.stored(value)
            .didSet({ Defaults[.isLogout] = $0.new })
            .asPublishProperty()
    }()
    
    /// roomsetup 是否更新
    let isRoomSetupRefresh: PublishProperty<Bool> = {
        var value = Defaults[.isRoomSetupRefresh] ?? true
        return DynamicProperty.stored(value)
            .didSet({ Defaults[.isRoomSetupRefresh] = $0.new })
            .asPublishProperty()
    }()
    
    var isEnableLivePKAudioConnection: Bool {
        get {
            return Defaults[.isEnableLivePKAudioConnection] ?? true
        }
        set {
            Defaults[.isEnableLivePKAudioConnection] = newValue
        }
    }
}

extension Settings {
    
    enum SubscriptionViewMode: Int {
        case _1xn = 1
        case _3xn = 3
        case _4xn = 4
        
        func next() -> SubscriptionViewMode {
            switch self {
            case ._1xn:
                return ._3xn
            case ._3xn:
                return ._4xn
            case ._4xn:
                return ._1xn
            }
        }
    }
    
//    enum SubscriptionSort: Int {
//        /// 按照订约时间降序的 cids
//        case standard
//        /// 按照字母升序的 cids
//        case alphabetical
//        /// 按照发布日期降序的 cids
//        case latest
//
//        case last
//        /// 自定义排序
//        case custom
//
//        func next() -> SubscriptionSort {
//            switch self {
//            case .standard:
//                return .alphabetical
//            case .alphabetical:
//                return .latest
//            case .latest:
//                return .last
//            case .last:
//                return .standard
//            case .custom:
//                return .standard
//            }
//        }
//    }
    
//    enum EpisodeVisionStyle: Int, CaseIterable {
//        // 按照 episode release_date 进行分组、排序，以 table view cell 方式呈现
//        case episode = 0
//        // 按照 episode cid 进行分组、排序，以 table view cell 方式呈现
//        case channel = 1
//        // 按照 episode cid 进行分组、排序，以 collection view cell 方式呈现
//        case brick = 2
//
//        mutating func next() {
//            switch self {
//            case .episode:
//                self = .channel
//            case .channel:
//                self = .brick
//            case .brick:
//                self = .episode
//            }
//        }
//
//        var localizedString: String {
//            switch self {
//            case .episode:
//                return NSLocalizedString("By.all.Episodes", comment: "")
//            case .channel:
//                return NSLocalizedString("Episodes.by.Channel", comment: "")
//            case .brick:
//                return NSLocalizedString("By.Channels", comment: "")
//            }
//        }
//    }
    
    /// Download 排序的时间选项
//    enum DownloadSortOption: Int {
//        case createTime
//        case releaseDate
//    }
}
