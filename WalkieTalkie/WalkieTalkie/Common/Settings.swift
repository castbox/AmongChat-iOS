//
//  Settings.swift
//  Scanner
//
//  Created by 江嘉睿 on 2019/8/13.
//  Copyright © 2019 江嘉睿. All rights reserved.
//

import Foundation
import RxSwift
import SwiftyUserDefaults
import CoreLocation
import SwiftHash

enum PushType: Int {
    case off = 0
    case fav
    case all
    case nearby
}

enum BrowseSelection: Int {
    case nearby = 0
    case popular
    case all
}

class Settings {
    static let shared = Settings()
    
    let loginResult: PublishProperty<Entity.LoginResult?> = {
        
        typealias LoginResult = Entity.LoginResult
        let value: LoginResult?
        
        if let json = Defaults[\.loginResultKey],
           let result = try? JSONDecoder().decodeAnyData(Entity.LoginResult.self, from: json) {
            value = result
        } else {
            value = nil
        }
        
        return DynamicProperty.stored(value)
            .didSet({ event in
                Defaults[\.loginResultKey] = event.new?.dictionary ?? nil
                SharedDefaults[\.loginResultTokenKey] = event.new?.access_token
            })
            .asPublishProperty()
    }()
    
    let isProValue: PublishProperty<Bool> = {
        var value = Defaults[\.isProKey]
        UserProperty.setIsPro(value)
        return DynamicProperty.stored(value)
            .didSet({ event in
                Defaults[\.isProKey] = event.new
                UserProperty.setIsPro(event.new)
                if event.new == false && Settings.shared.lockScreenOn.value == true {
                    Settings.shared.lockScreenOn.value = false
                }
            })
            .asPublishProperty()
    }()
    
    let lockScreenOn: PublishProperty<Bool> = {
        let value = Defaults[\.lockScreenOn]
        UserProperty.setLockScreenOn(value)
        return DynamicProperty.stored(value)
            .didSet({ event in
                Defaults[\.lockScreenOn] = event.new
                UserProperty.setLockScreenOn(event.new)
            })
            .asPublishProperty()
    }()
    
    let pushTypeValue: PublishProperty<PushType> = {
        let defaultInt = Defaults[\.pushTypeKey]
        let value = PushType(rawValue: defaultInt) ?? PushType.all
        return DynamicProperty.stored(value)
            .didSet({ Defaults[\.pushTypeKey] = $0.new.rawValue })
            .asPublishProperty()
    }()
    
    let browseSelectionValue: PublishProperty<BrowseSelection?> = {
        let defaultInt = Defaults[\.browseSelectionKey]
        let value: BrowseSelection? = BrowseSelection(rawValue: defaultInt ?? -1)
        return DynamicProperty.stored(value)
            .didSet({ Defaults[\.browseSelectionKey] = $0.new?.rawValue })
            .asPublishProperty()
    }()
    
    let nearbyDistanceValue: PublishProperty<Int> = {
        let value = Defaults[\.nearbyAlertDistance]
        return DynamicProperty.stored(value)
            .didSet({ Defaults[\.nearbyAlertDistance] = $0.new })
            .asPublishProperty()
    }()
    
    /// app 主题
    let theme: PublishProperty<Theme.Mode> = {
        var value = Defaults[\.theme]
        return DynamicProperty.stored(value)
            .didSet({ Defaults[\.theme] = $0.new })
            .asPublishProperty()
    }()
    
    let isOpenSubscribeHotTopic: PublishProperty<Bool> = {
        let value = Defaults[\.isOpenSubscribeHotTopicKey]
        return DynamicProperty.stored(value)
            .didSet({ event in
                Defaults[\.isOpenSubscribeHotTopicKey] = event.new
            })
            .asPublishProperty()
    }()
    
    var appInstallDate: Date {
        get {
            if let dt = Defaults[\.appInstallDateKey] {
                return dt
            } else {
                let current = Date()
                Defaults[\.appInstallDateKey] = current
                return current
            }
        }
    }
    
    var premiumShowRecord: PremiumFreqControl.Record {
        get {
            let storedStr = Defaults[\.premiumShowRecordKey]
            if let rec = PremiumFreqControl.Record(str: storedStr) {
                return rec
            } else {
                let r = PremiumFreqControl.Record(lastImpressionTime: nil, currentTimes: 0)
                Defaults[\.premiumShowRecordKey] = r.toString()
                return r
            }
        }
        set {
            Defaults[\.premiumShowRecordKey] = newValue.toString()
        }
    }
    
    var lastChatRoom: String? {
        get {
            return Defaults[\.lastChatRoomKey]
        } set {
            if let n = newValue {
                Defaults[\.lastChatRoomKey] = n
            }
        }
    }
    
    private var memoryFirstOpenValue: Bool? = nil
    
    /// 考虑老用户升级上来没有DefaultsKeys.firstOpenKey的情况，对比appInstallDate，和当前时间相差不超过10秒钟，判断为第一次启动
    private func complexFirstOpen() -> Bool {
        let prefValue: Bool = Defaults[\.firstOpenKey]
        if !prefValue { return false }
        let interval = Date().timeIntervalSince(appInstallDate)
        return interval < 10.0
    }
    
    var isFirstOpen: Bool {
        get {
            if let val = memoryFirstOpenValue {
                return val
            }
            
            let calcVal = complexFirstOpen()
            memoryFirstOpenValue = calcVal
            return calcVal
        }
    }
    
    var interstitalLastShowTime: Date {
        get {
            if let dt = Defaults[\.interstitialLastShowDateKey] {
                return dt
            } else {
                let now = Date().addingTimeInterval(-24*3600)
                Defaults[\.interstitialLastShowDateKey] = now
                return now
            }
        } set {
            Defaults[\.interstitialLastShowDateKey] = newValue
        }
    }
    
    var lastReviewRequestTime: Date {
        get {
            if let dt = Defaults[\.rateRequestDateKey] {
                return dt
            } else {
                let now = Date().addingTimeInterval(-86400)
                Defaults[\.rateRequestDateKey] = now
                return now
            }
        } set {
            Defaults[\.rateRequestDateKey] = newValue
        }
    }
    
    var userId: String {
        get {
            if let storedId = Defaults[\.userIdKey] {
                return storedId
            } else {
                let newId = MD5(UUID().uuidString)
                Defaults[\.userIdKey] = newId
                return newId
            }
        }
    }
    
    var userInAGroup: Bool {
        get {
            #if DEBUG
            return true
            #endif
            if let c = userId.unicodeScalars.last {
                return c.value % 2 == 0
            }
            return true
        }
    }
    
    let firestoreUserProfile: PublishProperty<FireStore.Entity.User.Profile?> = {
        typealias Profile = FireStore.Entity.User.Profile
        let profile: Profile?
        
        if let dict = Defaults[\.firestoreUserProfileKey] {
            profile = Profile(with: dict)
        } else {
            profile = nil
        }
        
        return DynamicProperty.stored(profile)
            .didSet({ (event) in
                var dict = event.new?.toDictionary()
                dict?.removeValue(forKey: Profile.Keys.updatedAt)
                Defaults[\.firestoreUserProfileKey] = dict
            })
            .asPublishProperty()
    }()
    
}

extension DefaultsKeys {
    var mode: DefaultsKey<Mode> { /// app 主题 {
        .init("mode", defaultValue: .public)
    }
    
    var channelName: DefaultsKey<String> {
        .init("channelName", defaultValue: "WELCOME")
    }
    
    var firstInstall: DefaultsKey<Bool> {
        .init("first.install", defaultValue: true)
    }
    
    var channel: DefaultsKey<Room> {
        .init("channel", defaultValue: Room(name: "WELCOME", user_count: 0))
    }
    
    var secretChannels: DefaultsKey<[Room]> {
        .init("secret.channels.joined", defaultValue: [])
    }
    
    var isProKey: DefaultsKey<Bool> {
        .init("is.pro.key", defaultValue: false)
    }
    
    var lockScreenOn: DefaultsKey<Bool> {
        .init("lockscreen.key", defaultValue: false)
    }
    var pushTypeKey: DefaultsKey<Int> {
        .init("push.type.key", defaultValue: 2)
    }
    var hasRequestedNotificationKey: DefaultsKey<Bool> {
        .init("noti.has.requested.key", defaultValue: false)
    }
    var premiumShowRecordKey: DefaultsKey<String> {
        .init("premium_show_record", defaultValue: "")
    }
    var firstOpenKey: DefaultsKey<Bool> {
        .init("app.first.open.key", defaultValue: true)
    }
    var nearbyAlertDistance: DefaultsKey<Int> {
        .init("noti.nearby.distance", defaultValue: 25) /// 推送设置中距离参数，默认250，单位miles
    }
    var useStandardFreetrialText: DefaultsKey<Bool> {
        .init("use.standard.freetrial.text", defaultValue: true)
    }
    
    var theme: DefaultsKey<Theme.Mode> { /// app 主题 {
        .init("theme", defaultValue: .light)
    }
    
    var browseSelectionKey: DefaultsKey<Int?> {
        .init("browse.selection.key")
    }
    var appInstallDateKey: DefaultsKey<Date?> {
        .init("app.install.date")
    }
    var latestLocationKey: DefaultsKey<CLLocation?> {
        .init("latest.location")
    }
    var lastChatRoomKey: DefaultsKey<String?> {
        .init("walkietalkie.last.room")
    }
    var interstitialLastShowDateKey: DefaultsKey<Date?> {
        .init("interstitial.last.show")
    }
    var rateRequestDateKey: DefaultsKey<Date?> {
        .init("rate.request.last")
    }
    
    //    static let purchasedItemsKey = DefaultsKey<String?>.init("purchased.item.key")
    
    var purchasedItemsKey: DefaultsKey<String?> {
        .init("purchased.item.key")
    }
    
    
    var userIdKey: DefaultsKey<String?> {
        .init("generated.user.id")
    }
    
    var debugAdsLogKey: DefaultsKey<Bool> {
        .init("debug.ads.log", defaultValue: false)
    }
    
    var isOpenSubscribeHotTopicKey: DefaultsKey<Bool> {
        .init("subscrbe.hot.topic", defaultValue: true)
    }
    
    var isFirstShowSecretChannel: DefaultsKey<Bool> {
        .init("walkie.talkie.first.show.secret", defaultValue: true)
    }
    
    static func channel(for mode: Mode) -> DefaultsKey<Room?> {
        .init("channel_with_mode_\(mode.rawValue)", defaultValue: nil)
    }
    
    var emojiMaps: DefaultsKey<[String: Any]> {
        .init("emoji.maps", defaultValue: [:])
    }
    
    var loginResultKey: DefaultsKey<[String : Any]?> {
        .init("among.chat.login.result", defaultValue: nil)
    }
    
    var blockedUsersKey: DefaultsKey<[ChannelUser]> {
        .init("blocked.users", defaultValue: [])
    }
    
    var profileInitialShownTsKey: DefaultsKey<Double?> {
        .init("profile.initial.shown.timestamp", defaultValue: nil)
    }
    
    var firestoreUserProfileKey: DefaultsKey<[String : Any]?> {
        .init("social.user.profile", defaultValue: nil)
    }
    
    var socialBirthdayUpdateAtTsKey: DefaultsKey<Double> {
        .init("social.profile.birthday.updated.timestamp", defaultValue: 0)
    }
    
    var joinChannelRequestsSentKey: DefaultsKey<[String : Double]> {
        .init("social.join.channel.request.sent.list", defaultValue: [:])
    }
    
    /// 最近一次启动广告展示时间
    var appOpenAdShowTime: DefaultsKey<Double> { .init("app.open.ad.latest.impression.timestamp", defaultValue: 0) }

}

extension DefaultsAdapter {
    func channel(for mode: Mode) -> Room {
        return Defaults[key: DefaultsKeys.channel(for: mode)] ?? Room.empty(for: mode)
    }
    
    func set(channel: Room?, mode: Mode) {
        //保护存储错误
        if mode == .public,
            channel?.name.isPrivate ?? false {
            return
        }
        if mode == .private,
        !(channel?.name.isPrivate ?? true) {
            return
        }
        Defaults[key: DefaultsKeys.channel(for: mode)] = channel
    }
}

extension CLLocation: DefaultsSerializable {}
