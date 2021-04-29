//
//  Settings.swift
//  Scanner
//
//  Created by 江嘉睿 on 2019/8/13.
//  Copyright © 2019 江嘉睿. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
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
                
                if let result = event.new {
                    if result.is_new_user == true {
                        //
                        _ = shared.updateAvatarGuideUpdateTime() //当天不显示
                    }
                    shared.updateProfile()
                }
                
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
    
    let isInReview: PublishProperty<Bool> = {
        return DynamicProperty.stored(false)
            .asPublishProperty()
    }()
    
    let preferredChatLanguage: PublishProperty<Entity.GlobalSetting.KeyValue?> = {

        typealias Language = Entity.GlobalSetting.KeyValue
        let value: Language?
        
        if let json = Defaults[\.preferredChatLanguageKey],
           let result = try? JSONDecoder().decodeAnyData(Language.self, from: json) {
            value = result
        } else {
            value = nil
        }
        
        return DynamicProperty.stored(value)
            .didSet({ event in
                guard let newDict = event.new?.dictionary else { return }
                Defaults[\.preferredChatLanguageKey] = newDict
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
            if Config.environment == .debug {
                return true
            } else {
                if let c = userId.unicodeScalars.last {
                    return c.value % 2 == 0
                }
            }
            return true
        }
    }
    
    let amongChatUserProfile: PublishProperty<Entity.UserProfile?> = {
        typealias Profile = Entity.UserProfile
        let profile: Profile?
        
        if let dict = Defaults[\.amongChatUserProfileKey],
           let p = try? JSONDecoder().decodeAnyData(Profile.self, from: dict) {
            profile = p
        } else {
            profile = nil
        }
        
        return DynamicProperty.stored(profile)
            .didSet({ (event) in
                Defaults[\.amongChatUserProfileKey] = event.new?.dictionary
                shared.isProValue.value = event.new?.isVip ?? false
            })
            .asPublishProperty()
    }()
    
    
    let profilePage: PublishProperty<Entity.ProfilePage?> = {
        typealias Profile = Entity.ProfilePage
        let profile: Profile?
        
        if let dict = Defaults[\.userProfilePageDataKey],
           let p = try? JSONDecoder().decodeAnyData(Profile.self, from: dict) {
            profile = p
        } else {
            profile = nil
        }
        
        return DynamicProperty.stored(profile)
            .didSet({ (event) in
                Defaults[\.userProfilePageDataKey] = event.new?.dictionary
            })
            .asPublishProperty()
    }()

        
    // 首页Summary缓存临时方案
    let amongChatHomeSummary: PublishProperty<Entity.Summary?> = {
        
        typealias Summary = Entity.Summary
        let summary: Summary?
        
        if let dict = Defaults[\.amongChatHomeSummaryKey],
           let s = try? JSONDecoder().decodeAnyData(Summary.self, from: dict) {
            summary = s
        } else {
            summary = nil
        }
        
        return DynamicProperty.stored(summary)
            .didSet({ (event) in
                guard let dict = event.new?.dictionary else { return }
                Defaults[\.amongChatHomeSummaryKey] = dict
            })
            .asPublishProperty()
    }()
    //end
    
    let amongChatAvatarListShown: PublishProperty<Double?> = {
        var value = Defaults[\.amongChatAvatarListShownTsKey]
        return DynamicProperty.stored(value)
            .didSet({ event in
                Defaults[\.amongChatAvatarListShownTsKey] = event.new
            })
            .asPublishProperty()
    }()
    
    let globalSetting: PublishProperty<Entity.GlobalSetting?> = {
        
        let settings: Entity.GlobalSetting?
        
        if let dict = Defaults[\.amongChatGlobalSettingKey],
           let s = try? JSONDecoder().decodeAnyData(Entity.GlobalSetting.self, from: dict) {
            settings = s
        } else {
            settings = nil
        }
        
        return DynamicProperty.stored(settings)
            .didSet({ (event) in
                guard let dict = event.new?.dictionary else { return }
                Defaults[\.amongChatGlobalSettingKey] = dict
            })
            .asPublishProperty()
    }()
    
    let supportedTopics: PublishProperty<Entity.Summary?> = {
        typealias Summary = Entity.Summary
        let summary: Summary?
        
        if let dict = Defaults[\.supportedTopicsKey],
           let s = try? JSONDecoder().decodeAnyData(Summary.self, from: dict) {
            summary = s
        } else {
            summary = nil
        }
        
        return DynamicProperty.stored(summary)
            .didSet({ (event) in
                guard let dict = event.new?.dictionary else { return }
                Defaults[\.supportedTopicsKey] = dict
            })
            .asPublishProperty()
    }()
    
    let lastCreatedTopic: PublishProperty<Entity.SummaryTopic?> = {
        typealias Topic = Entity.SummaryTopic
        let topic: Topic?
        
        if let dict = Defaults[\.lastCreatedTopicKey],
           let s = try? JSONDecoder().decodeAnyData(Topic.self, from: dict) {
            topic = s
        } else {
            topic = nil
        }
        
        return DynamicProperty.stored(topic)
            .didSet({ (event) in
                guard let dict = event.new?.dictionary else { return }
                Defaults[\.lastCreatedTopicKey] = dict
            })
            .asPublishProperty()
    }()
    
    let defaultProfileDecorationCategoryList: PublishProperty<[Entity.DecorationCategory]> = {
        
        typealias DecorationCategory = Entity.DecorationCategory
        let decos: [DecorationCategory]
        
        if let dict = Defaults[\.defaultProfileDecorations],
           let s = try? JSONDecoder().decodeAnyData([DecorationCategory].self, from: dict) {
            decos = s
        } else {
            decos = [DecorationCategory]()
        }
        
        return DynamicProperty.stored(decos)
            .didSet({ (event) in
                let list = event.new.compactMap({ $0.dictionary })
                Defaults[\.defaultProfileDecorations] = list
            })
            .asPublishProperty()
    }()
    
    var cachedRtmToken: Entity.RTMToken? {
        get { Defaults[\.amongChatRtmToken] }
        set { Defaults[\.amongChatRtmToken] = newValue}
    }
    
    var canShowAvatarGuide: Bool {
        guard amongChatAvatarListShown.value == nil, globalSetting.value?.changeTip(.avatar)?.list.isEmpty == false else {
            return false
        }
        let privious = Defaults[\.avatarGuideUpdateTime]
        let current = Date().string(withFormat: "yyyy-MM-dd")
        guard privious != current else {
            return false
        }
        Defaults[\.avatarGuideUpdateTime] = current
        return true
    }
    
    var showQuickChangeRoomButton: Bool {
        //新用户
        if Defaults[\.showQuickChangeRoomButton] == false {
            let remoteValue = FireRemote.shared.value.showQuickChangeRoomButton
            Defaults[\.showQuickChangeRoomButton] = remoteValue
        }
        return Defaults[\.showQuickChangeRoomButton] ?? false
    }
    
    let hasUnreadNoticeRelay = BehaviorRelay<Bool>(value: false)
    
    //设置默认值
    func updateDefaultConfig() {
        if Defaults[\.showQuickChangeRoomButton] == nil {
            Defaults[\.showQuickChangeRoomButton] = Defaults[\.loginResultKey] != nil
        }
    }
    
    private func updateAvatarGuideUpdateTime() {
        let current = Date().string(withFormat: "yyyy-MM-dd")
        Defaults[\.avatarGuideUpdateTime] = current
    }
    
    func startObserver() {
        loginResult.replay()
            .subscribe(onNext: { [weak self] result in
//                guard let result = result, result.uid > 0 else {
//                    return
//                }
                self?.fetchGlobalConfig()
            })
    }
    
    func updateProfile() {
        guard let uid = Settings.loginUserId else {
            return
        }
        _ = Request.profilePage(uid: uid)
            .subscribe(onSuccess: { (profile) in
                guard let p = profile else {
                    return
                }
                Settings.shared.amongChatUserProfile.value = p.profile
                Settings.shared.profilePage.value = p
            }, onError: { (error) in
                cdPrint("")
            })
    }
    
    func clearAll() {
        if loginResult.value != nil {
            loginResult.value = nil
        }
        if amongChatUserProfile.value != nil {
            amongChatUserProfile.value = nil            
        }
        
        if profilePage.value != nil {
            profilePage.value = nil
        }
        Defaults[\.amongChatReleationSuggestedContacts] = []
    }
}


extension Settings {
    static var loginUserId: Int? {
        return shared.loginResult.value?.uid
    }
    
    static var loginUserProfile: Entity.UserProfile? {
        return shared.amongChatUserProfile.value
    }
    
    static var profilePage: Entity.ProfilePage? {
         shared.profilePage.value
    }
    
    static var profileFollowData: Entity.RelationData? {
        return shared.profilePage.value?.followData
    }
    
    //巡警
    static var isMonitor: Bool {
        shared.profilePage.value?.profile?.isMonitor ?? false
    }
    
    //超管
    static var isSuperAdmin: Bool {
        shared.profilePage.value?.profile?.isSuperAdmin ?? false
    }
    
    static var isSilentUser: Bool {
        isMonitor || isSuperAdmin
    }
    
    func fetchGlobalConfig() {
        _ = Request.amongchatProvider.rx.request(.globalSetting)
            .retry(2)
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.GlobalSetting.self)
            .do(onSuccess: { [unowned self] (value) in
                guard let newValue = value else {
                    return
                }
                if !newValue.avatarVersion.isEmpty,
                   newValue.avatarVersion != self.globalSetting.value?.avatarVersion ?? ""  {
                    DispatchQueue.main.async {
                        self.amongChatAvatarListShown.value = nil
                    }
                }
                Settings.shared.isInReview.value = newValue.iosCheckVersion == Config.appVersion
            })
            .subscribe(onSuccess: { [unowned self] value in
                self.globalSetting.value = value
            })
    }
}


extension DefaultsKeys {
//    var mode: DefaultsKey<Mode> { /// app 主题 {
//        .init("mode", defaultValue: .public)
//    }
    
    var channelName: DefaultsKey<String> {
        .init("channelName", defaultValue: "WELCOME")
    }
    
    var firstInstall: DefaultsKey<Bool> {
        .init("first.install", defaultValue: true)
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
    
    var emojiMaps: DefaultsKey<[String: Any]> {
        .init("emoji.maps", defaultValue: [:])
    }
    
    var loginResultKey: DefaultsKey<[String : Any]?> {
        .init("among.chat.login.result", defaultValue: nil)
    }
    
    var blockedUsersV2Key: DefaultsKey<[Entity.RoomUser]> {
        .init("blocked.users.v2", defaultValue: [])
    }
    
    var followersCount: DefaultsKey<Int> {
        .init("followers.count", defaultValue: 0)
    }
    
    var profileInitialShownTsKey: DefaultsKey<Double?> {
        .init("profile.initial.shown.timestamp", defaultValue: nil)
    }
    
    var amongChatUserProfileKey: DefaultsKey<[String : Any]?> {
        .init("among.chat.user.profile", defaultValue: nil)
    }
    
    var userProfilePageDataKey: DefaultsKey<[String : Any]?> {
        .init("among.chat.user.profile.page", defaultValue: nil)
    }
    
    var joinChannelRequestsSentKey: DefaultsKey<[String : Double]> {
        .init("social.join.channel.request.sent.list", defaultValue: [:])
    }
    
    /// 最近一次启动广告展示时间
    var appOpenAdShowTime: DefaultsKey<Double> { .init("app.open.ad.latest.impression.timestamp", defaultValue: 0) }
        
    // 首页Summary缓存临时方案
    var amongChatHomeSummaryKey: DefaultsKey<[String : Any]?> {
        .init("among.chat.home.summary", defaultValue: nil)
    }
    
    var sensitiveWords: DefaultsKey<[String]?> {
        .init("setting.sensitive.words")
    }
    
    var isReleaseMode: DefaultsKey<Bool> {
        .init("settings.isReleaseMode", defaultValue: true)
    }
    
    //end
    
    var amongChatAvatarListShownTsKey: DefaultsKey<Double?> {
        .init("among.chat.avatar.list.shown.timestamp", defaultValue: nil)
    }
    
    var amongChatGlobalSettingKey: DefaultsKey<[String : Any]?> {
        .init("among.chat.global.setting", defaultValue: [:])
    }
    
    var preferredChatLanguageKey: DefaultsKey<[String : Any]?> {
        .init("among.chat.preferred.chat.language", defaultValue: nil)
    }
    
    var amongChatEnterRoomTopicHistory: DefaultsKey<[String]> {
        .init("among.chat.enter.room.topic.history", defaultValue: [])
    }
        
    var supportedTopicsKey: DefaultsKey<[String : Any]?> {
        .init("among.chat.supported.topics", defaultValue: nil)
    }
    
    var lastCreatedTopicKey: DefaultsKey<[String : Any]?> {
        .init("among.chat.last.create.topic", defaultValue: nil)
    }
    
    var amongChatRtmToken: DefaultsKey<Entity.RTMToken?> {
        .init("among.chat.rtm.token", defaultValue: nil)
    }
    
    var amongChatReleationSuggestedContacts: DefaultsKey<[String]> {
        .init("among.chat.relation.suggested.contacts", defaultValue: [])
    }
    
    var avatarGuideUpdateTime: DefaultsKey<String> {
        .init("among.chat.avatar.guide.update.time", defaultValue: "")
    }
    
    static func permissionRequestStatusKey(for request: PermissionManager.RequestType) -> DefaultsKey<Int> {
        .init("permission.request.status.\(request.rawValue)", defaultValue: 0)
    }

    static func permissionRequestUpdateTime(for request: PermissionManager.RequestType) -> DefaultsKey<String?> {
        .init("permission.requested.update.time.\(request.rawValue)", defaultValue: nil)
    }
    
    //请求次数
    static func permissionRequestTimes(for request: PermissionManager.RequestType) -> DefaultsKey<Int> {
        .init("permission.requested.times.\(request.rawValue)", defaultValue: 0)
    }
    
    var defaultProfileDecorations: DefaultsKey<[[String : Any]]?> {
        .init("among.chat.default.profile.decoration.category.list", defaultValue: nil)
    }
    
    var setAgePromptShowsTime: DefaultsKey<Double?> {
        .init("among.chat.set.age.prompt.shows.time.\(Settings.shared.amongChatUserProfile.value?.uid ?? 0)", defaultValue: nil)
    }
    
    var updateInstalledAppTime: DefaultsKey<String?> {
        .init("among.chat.update.ins.app.time", defaultValue: nil)
    }
    
    var showQuickChangeRoomButton: DefaultsKey<Bool?> {
        .init("show.quick.change.button", defaultValue: nil)
    }
    
    static func groupRoomCanShowGameNameTips(for topic: AmongChat.Topic) -> DefaultsKey<Bool> {
        .init("group.room.can.show.game.name.tips.\(topic.rawValue)", defaultValue: true)
    }
    
}

//extension DefaultsAdapter {
////    permissionRequestStatusKey
////    //上次时间
////    permissionLaterKey
//
//    func permissionRequestStatusKey(for request: PermissionManager.RequestType) -> Room {
//        return Defaults[key: DefaultsKeys.channel(for: mode)] ?? Room.empty(for: mode)
//    }
//
//    func set(channel: Room?, mode: Mode) {
//        //保护存储错误
//        if mode == .public,
//           channel?.name.isPrivate ?? false {
//            return
//        }
//        if mode == .private,
//           !(channel?.name.isPrivate ?? true) {
//            return
//        }
//        Defaults[key: DefaultsKeys.channel(for: mode)] = channel
//    }
//}

extension CLLocation: DefaultsSerializable {}

extension Date {
    static var currentDay: String {
        return Date().string(withFormat: "yyyy-MM-dd")
    }
}
