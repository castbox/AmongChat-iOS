//
//  FireRemote.swift
//  Scanner
//
//  Created by 江嘉睿 on 2019/9/26.
//  Copyright © 2019 江嘉睿. All rights reserved.
//

import Foundation
import SwiftyJSON
import RxSwift
import FirebaseRemoteConfig

class FireRemote {
    static let shared = FireRemote()
    
    private let config: RemoteConfig = {
        let fig = RemoteConfig.remoteConfig()
        fig.setDefaults(fromPlist: "DefaultRemoteConfig")
        let settings = RemoteConfigSettings()
        
        if Config.environment == .debug {
            settings.minimumFetchInterval = 0
        }
        fig.configSettings = settings
        return fig
    }()
    
    private var refreshSubject = PublishSubject<FireRemote>()
    private(set) var value: Value {
        didSet {
            refreshSubject.onNext(self)
        }
    }
    
    private init() {
        self.value = Value(config: config)
    }
    
    func refresh() {
        config.fetchAndActivate { [unowned self] (status, error) in
            if status == .successFetchedFromRemote {
                self.value = Value(config: self.config)
            }
        }
    }
    
    func remoteValue() -> Observable<FireRemote> {
        return refreshSubject.startWith(self)
    }
}

extension FireRemote {
    struct Value {
        let premiumPromopt: PremiumPrompt
        
        let adsFreeMinutes: Int
        
        let popularProduct: String
        
        let reviewProtectMinutes: Int
        
        let notificationAutoPlay: Bool
        
        let freeTrialActionTitle: String?
        
        let premiumProducts: Set<String>
        
        let chatChannels: [String]
        
//        let popularBanner: TableBannerInfo?
        
        let nativeRefreshSeconds: Int
        
        let interstitialConfig: InterstitialConfig
        
        let rateIntervalSeconds: Int
        
        let delayShowShareDialog: Int
        
        /// 启动广告
        let app_open_ad_config: AppOpenAdConfig
        
        let allowed_minimum_version: String
        
        init(config: RemoteConfig) {
            let str = config["premium_prompt"].stringValue ?? ""
            premiumPromopt = PremiumPrompt(str)
            adsFreeMinutes = config["ads_free_minutes"].numberValue?.intValue ?? 5
            popularProduct = config["popular_product"].stringValue ?? ""
            reviewProtectMinutes = config["review_protect_minutes"].numberValue? .intValue ?? 1440
            
            notificationAutoPlay = config["notification_auto_play"].boolValue
            
            premiumProducts = Set(config["ios_premium_product"].jsonValue as? [String] ?? [])
            
            chatChannels = config["chat_channels"].jsonValue as? [String] ?? []
            
//            if let pbJson = config["popular_alert"].jsonValue as? [String: String],
//                let image = pbJson["img"],
//                let action = pbJson["uri"],
//                let bgColor = pbJson["backgroundColor"] {
//                popularBanner = TableBannerInfo(image: image, action: action, bgColor: bgColor)
//            } else {
//                popularBanner = nil
//            }
            
            if let actionTitle = config["free_trial_action_title"].stringValue,
                !actionTitle.isEmpty {
                freeTrialActionTitle = actionTitle
            } else {
                freeTrialActionTitle = nil
            }
            
            let minInterval: Int = 20
            nativeRefreshSeconds = max(minInterval, config["native_ads_refresh_seconds"].numberValue?.intValue ?? minInterval)
            
            let interstitialString = config["iad_config"].stringValue ?? ""
            interstitialConfig = InterstitialConfig(interstitialString)
            
            rateIntervalSeconds = config["i_rate_interval_sec"].numberValue?.intValue ?? 86400
                    delayShowShareDialog = config["delay_show_share_dialog"].numberValue?.intValue ?? 10
            
            app_open_ad_config = AppOpenAdConfig(config["app_open_ad_config"].stringValue ?? "")
            
            allowed_minimum_version = config["allowed_minimum_version"].stringValue ?? ""
        }
    }
}

extension FireRemote.Value {
    struct PremiumPrompt {
        let enable: Bool
        let newUserSeconds: Int
        let intervalSeconds: Int
        
        /// 最大出现次数，-1为不限
        let maxTimes: Int
        
        init(_ string: String) {
            let json = JSON(parseJSON: string)
            self.enable = json["enable"].bool ?? true
            self.newUserSeconds = json["new_user_sec"].int ?? 0
            self.intervalSeconds = json["interval_sec"].int ?? 600
            self.maxTimes = json["max_times"].int ?? -1
        }
    }
    
    struct InterstitialConfig {
        let enable: Bool
        let reloadSeconds: Int
        let freeMinutes: Int
        
        init(_ string: String) {
            let json = JSON(parseJSON: string)
            self.enable = json["enable"].bool ?? true
            self.reloadSeconds = json["reload_s"].int ?? 60
            self.freeMinutes = json["free_m"].int ?? 10
        }
    }
}

extension FireRemote.Value {
    
    struct AppOpenAdConfig {
        let enable: Bool
        let free_h: Double
        let interval_s: Double
        let adId: String
        let delay_s: Double
        
        init(_ jsonString: String) {
            let json = JSON(parseJSON: jsonString)
            enable = json["enable"].bool ?? false
            free_h = json["free_h"].double ?? 12
            interval_s = json["interval_s"].double ?? 300
            adId = json["adId"].string ?? "ca-app-pub-2436733915645843/3571875937"
            delay_s = json["delay_s"].double ?? 0.5
        }
    }
    
}

extension FireRemote.Value {
    
    var forceUpgrade: Bool {
        
        switch Config.appVersion.compare(allowed_minimum_version, options: .numeric) {
        case .orderedSame, .orderedDescending:
            return false
        case .orderedAscending:
            return true
        }
    }
    
}
