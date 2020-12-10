//
//  Constants.swift
//  AgoraChatRoom
//
//  Created by LXH on 2019/11/27.
//  Copyright © 2019 CavanSu. All rights reserved.
//

import UIKit

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
    
    static let countryCode: String = {
        return Locale.current.regionCode ?? ""
    }()
    
    static let timeZone: String = {
        return TimeZone.current.identifier
    }()
    
    static let languageCode: String = {
        return Locale.current.languageCode ?? ""
    }()
    
    static let localeCode: String = {
        return Locale.current.identifier
    }()
    
    static var deviceToken: String {
        FireMessaging.shared.fcmToken ?? ""
    }
    
    static func deviceInfo() -> [String : Any] {
        return [
            "uid" : Settings.shared.loginResult.value?.uid ?? "",
            "deviceCountry" : countryCode,
            "language" : languageCode,
            "locale" : localeCode,
            "timezone" : timeZone,
            "appVersion" : appVersion,
            "deviceId" : deviceID,
            "deviceToken" : deviceToken,
            "deviceType" : "iOS",
            "pushType" : "FCM",
            "pushNotificationEnable": Settings.shared.isOpenSubscribeHotTopic.value
        ]
    }

    static var defaultUsername: String {
        
        if let loginResult = Settings.shared.loginResult.value,
           let uidSufix = loginResult.uid.split(bySeparator: "-").last {
            return "\(uidSufix)"
        } else {
            return "\(sUserId)"
        }
    }
}
