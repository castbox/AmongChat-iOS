//
//  AppConfig.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/4/20.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation
import SwiftyUserDefaults

struct Config {
    enum AppEnvironment: Int {
        case debug, release
    }
    
    static var environment: AppEnvironment {
        return AppEnvironment(rawValue: Defaults[\.isReleaseMode].int) ?? .release
    }
    
    enum PolicyType: String {
        case terms = "https://among.chat/term.html"
        case policy = "https://among.chat/policy.html"
        case appShare = "https://amongchat.page.link/app"
        case guideline = "https://among.chat/guideline.html"
        
        static func url(_ type: Self) -> String {
            return type.rawValue
        }
    }
    
    struct AppKey {

    }
    
    static var appStoreUrl: String {
        return ""
    }
    
    static var scheme: String {
        return "amongchat"
    }
    
//
//    static var supportUrl: String {
//        return "\(Api.host_H5)/help"
//    }
//
//    static var privacyUrl: String {
//        return "\(Api.host_H5)/privacy"
//    }
    
    static var officialWebsiteUrl: String {
        return ""
    }
    
    static private let defaultVersion = "1.0"
    static var appVersion: String {
        guard let infoDictionary = Bundle.main.infoDictionary else { return defaultVersion }
        let shortVersion = infoDictionary["CFBundleShortVersionString"] as? String
        return shortVersion ?? defaultVersion
    }
    
    static private let defaultVersionCode = "1"
    static var versionCode: String {
        guard let infoDictionary = Bundle.main.infoDictionary else { return defaultVersionCode }
        return infoDictionary["CFBundleVersion"] as? String ?? defaultVersionCode
    }
    
    static var versionCodeIntValue: Int {
        return versionCode.int ?? 1
    }
    
    static var appVersionWithBuildVersion: String {
        if environment == .debug {
            return "\(appVersion) # - Build-\(versionCode) - dev"
        } else {
            return appVersion
        }
    }
    
    static private let defaultBundleIdentifier = "com.talkie.walkie"
    static var appBundleIdentifier: String {
        guard let infoDictionary = Bundle.main.infoDictionary else { return defaultBundleIdentifier }
        let shortVersion = infoDictionary["CFBundleIdentifier"] as? String
        return shortVersion ?? defaultBundleIdentifier
    }
    
    static var dateFormat: String {
        return "MM/dd/yyyy HH:mm:ss"
    }
    
}

extension Config.AppEnvironment {
//    var heartBeatingInterval: Int {
//        switch self {
//        case .debug:
//            return 10
//        default:
//            return 60
//        }
//    }
}
