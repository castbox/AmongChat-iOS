//
//  Constants.swift
//  AgoraChatRoom
//
//  Created by LXH on 2019/11/27.
//  Copyright © 2019 CavanSu. All rights reserved.
//

import UIKit
import AdSupport

struct Constants {
    static let sUserId: UInt = UInt(UInt32(bitPattern: MemberUtil.getUserId()))

    static func isMyself(_ userId: UInt) -> Bool {
        userId == sUserId
    }

    enum ABGroup: String {
        case a
        case b
    }
    
    static let deviceID: String = {
        let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? ""
        return deviceID
    }()
    
    static let appId = "1539641263"
    
    static var appStoreUrl: String {
        "https://itunes.apple.com/app/id\(appId)"
    }
    
    static let giphyApiKey = "7QHAiZsbbDQEczlOLPM2173dYaMBbGYb"
    
    static let abGroup: ABGroup = {
//        #if DEBUG
        return .b
//        #else
//        let deviceId_t = UIDevice.current.identifierForVendor?.uuid
//        let deviceId_int: UInt8 = deviceId_t?.15 ?? 0
//        let group: ABGroup
//        if deviceId_int % 2 == 0 {
//            group = .b
//        } else {
//            group = .a
//        }
//        return group
//        #endif
    }()
    
    static let appVersion: String = {
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
        return currentVersion
    }()
    
    static var preferredLocale: Locale = {
        guard let preferredIdentifier = Locale.preferredLanguages.first else {
            return Locale.current
        }
        return Locale(identifier: preferredIdentifier)
    }()
    
    static let countryCode: String = {
        return preferredLocale.regionCode ?? ""
    }()
    
    static let timeZone: String = {
        return TimeZone.current.identifier
    }()
    
    static let languageCode: String = {
        return preferredLocale.languageCode ?? ""
    }()
    
    static let localeCode: String = {
        return preferredLocale.identifier
    }()
    
    static let idfa: String = {
        guard ASIdentifierManager.shared().isAdvertisingTrackingEnabled else { return "" }
        return ASIdentifierManager.shared().advertisingIdentifier.uuidString
    }()
    
    static let modelName: String = {
        return UIDevice.current.model
    }()
    
    static var deviceToken: String {
        FireMessaging.shared.fcmToken ?? ""
    }
    
    static var localTime: String {
        get {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
            formatter.locale = Locale(identifier: "en_US")
            return formatter.string(from: Date())
        }
    }
    
    static func deviceInfo() -> [String : Any] {
        return [
            "countryCode" : countryCode,
            "lang" : languageCode,
            "locale" : localeCode,
            "timeZone" : timeZone,
            "appVersion" : appVersion,
            "deviceId" : deviceID,
            "deviceType" : modelName,
            "pushType" : "FCM",
            "IDFA_ios" : idfa,
            "localTime" : localTime,
            "appIdentifier" : Config.appBundleIdentifier,
//            "pushNotificationEnable": Settings.shared.isOpenSubscribeHotTopic.value
        ]
    }

    static var defaultUsername: String {
        
//        if let loginResult = Settings.shared.loginResult.value,
//           let uidSufix = loginResult.uid.split(bySeparator: "-").last {
//            return "\(uidSufix)"
//        } else {
            return "\(sUserId)"
//        }
    }
}
