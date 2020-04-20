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
    
    let isProValue: PublishProperty<Bool> = {
        var value = Defaults[.isProKey]
        UserProperty.setIsPro(value)
        return DynamicProperty.stored(value)
            .didSet({ event in
                Defaults[.isProKey] = event.new
                UserProperty.setIsPro(event.new)
                if event.new == false && Settings.shared.lockScreenOn.value == true {
                    Settings.shared.lockScreenOn.value = false
                }
            })
            .asPublishProperty()
    }()
    
    let lockScreenOn: PublishProperty<Bool> = {
        let value = Defaults[.lockScreenOn]
        UserProperty.setLockScreenOn(value)
        return DynamicProperty.stored(value)
            .didSet({ event in
                Defaults[.lockScreenOn] = event.new
                UserProperty.setLockScreenOn(event.new)
            })
            .asPublishProperty()
    }()
    
    let pushTypeValue: PublishProperty<PushType> = {
        let defaultInt = Defaults[DefaultsKeys.pushTypeKey]
        let value = PushType(rawValue: defaultInt) ?? PushType.all
        return DynamicProperty.stored(value)
            .didSet({ Defaults[.pushTypeKey] = $0.new.rawValue })
            .asPublishProperty()
    }()
    
    let browseSelectionValue: PublishProperty<BrowseSelection?> = {
        let defaultInt = Defaults[DefaultsKeys.browseSelectionKey]
        let value: BrowseSelection? = BrowseSelection(rawValue: defaultInt ?? -1)
        return DynamicProperty.stored(value)
            .didSet({ Defaults[DefaultsKeys.browseSelectionKey] = $0.new?.rawValue })
            .asPublishProperty()
    }()
    
    let nearbyDistanceValue: PublishProperty<Int> = {
        let value = Defaults[DefaultsKeys.nearbyAlertDistance]
        return DynamicProperty.stored(value)
            .didSet({ Defaults[DefaultsKeys.nearbyAlertDistance] = $0.new })
        .asPublishProperty()
    }()
    
    /// app 主题
    let theme: PublishProperty<Theme.Mode> = {
        var value = Defaults[.theme] ?? .light
        return DynamicProperty.stored(value)
            .didSet({ Defaults[.theme] = $0.new })
            .asPublishProperty()
    }()

    var appInstallDate: Date {
        get {
            if let dt = Defaults[DefaultsKeys.appInstallDateKey] {
                return dt
            } else {
                let current = Date()
                Defaults[DefaultsKeys.appInstallDateKey] = current
                return current
            }
        }
    }
    
    var premiumShowRecord: PremiumFreqControl.Record {
        get {
            let storedStr = Defaults[DefaultsKeys.premiumShowRecordKey]
            if let rec = PremiumFreqControl.Record(str: storedStr) {
                return rec
            } else {
                let r = PremiumFreqControl.Record(lastImpressionTime: nil, currentTimes: 0)
                Defaults[DefaultsKeys.premiumShowRecordKey] = r.toString()
                return r
            }
        }
        set {
            Defaults[DefaultsKeys.premiumShowRecordKey] = newValue.toString()
        }
    }
    
    var lastChatRoom: String? {
        get {
            return Defaults[DefaultsKeys.lastChatRoomKey]
        } set {
            if let n = newValue {
                Defaults[DefaultsKeys.lastChatRoomKey] = n
            }
        }
    }
    
    private var memoryFirstOpenValue: Bool? = nil
    
    /// 考虑老用户升级上来没有DefaultsKeys.firstOpenKey的情况，对比appInstallDate，和当前时间相差不超过10秒钟，判断为第一次启动
    private func complexFirstOpen() -> Bool {
        let prefValue: Bool = Defaults[DefaultsKeys.firstOpenKey]
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
            if let dt = Defaults[.interstitialLastShowDateKey] {
                return dt
            } else {
                let now = Date().addingTimeInterval(-24*3600)
                Defaults[.interstitialLastShowDateKey] = now
                return now
            }
        } set {
            Defaults[.interstitialLastShowDateKey] = newValue
        }
    }
    
    var lastReviewRequestTime: Date {
        get {
            if let dt = Defaults[.rateRequestDateKey] {
                return dt
            } else {
                let now = Date().addingTimeInterval(-86400)
                Defaults[.rateRequestDateKey] = now
                return now
            }
        } set {
            Defaults[.rateRequestDateKey] = newValue
        }
    }
    
    var userId: String {
        get {
            if let storedId = Defaults[.userIdKey] {
                return storedId
            } else {
                let newId = MD5(UUID().uuidString)
                Defaults[.userIdKey] = newId
                return newId
            }
        }
    }
    
    var userInAGroup: Bool {
        get {
            if let c = userId.unicodeScalars.last {
                return c.value % 2 == 0
            }
            return true
        }
    }
}

extension DefaultsKeys {
    static let isProKey = DefaultsKey<Bool>.init("is.pro.key", defaultValue: false)
    
    static let lockScreenOn = DefaultsKey<Bool>.init("lockscreen.key", defaultValue: false)
    
    static let pushTypeKey = DefaultsKey<Int>.init("push.type.key", defaultValue: 2)
    
    static let browseSelectionKey = DefaultsKey<Int?>.init("browse.selection.key")
    
    static let hasRequestedNotificationKey = DefaultsKey<Bool>.init("noti.has.requested.key", defaultValue: false)
    
    static let appInstallDateKey = DefaultsKey<Date?>.init("app.install.date")
    
    static let premiumShowRecordKey = DefaultsKey<String>.init("premium_show_record", defaultValue: "")
    
    static let firstOpenKey = DefaultsKey<Bool>.init("app.first.open.key", defaultValue: true)
    
    /// 推送设置中距离参数，默认250，单位miles
    static let nearbyAlertDistance = DefaultsKey<Int>.init("noti.nearby.distance", defaultValue: 25)
    
    /// app 主题
    static let theme = DefaultsKey<Theme.Mode?>("theme")
    
    /// spotlight
    static let spotlightFavourItemKey = DefaultsKey<Int>.init("spotlight.favour.item", defaultValue: 0)
    
    static let latestLocationKey = DefaultsKey<CLLocation?>.init("latest.location")
    
    static let lastChatRoomKey = DefaultsKey<String?>.init("walkietalkie.last.room")
    
    static let useStandardFreetrialText = DefaultsKey<Bool>.init("use.standard.freetrial.text", defaultValue: true)
    
    static let interstitialLastShowDateKey = DefaultsKey<Date?>.init("interstitial.last.show")
    
    static let rateRequestDateKey = DefaultsKey<Date?>.init("rate.request.last")
    
    static let purchasedItemsKey = DefaultsKey<String?>.init("purchased.item.key")
    
    static let userIdKey = DefaultsKey<String?>.init("generated.user.id")
    
    
    static let debugAdsLogKey = DefaultsKey<Bool>.init("debug.ads.log", defaultValue: false)
    
}

extension CLLocation: DefaultsSerializable {}
