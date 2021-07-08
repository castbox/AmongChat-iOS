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
        cdPrint("[FireRemote] - fetchAndActivate")
        config.fetchAndActivate { [unowned self] (status, error) in
            cdPrint("[FireRemote] - fetchAndActivate result: status: \(status.rawValue) error: \(error)")
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
        
        let auditVersion: String
        
        let age_prompt_enable: Bool
                
        //展示直播间快速切换房间
        let showQuickChangeRoomButton: Bool
        
        //
        let defaultMainTabIndex: Int
        
        ///Feeds 广告加载间隔数 < 0 则不需要加载广告
        let feedsAdInterval: Int
        
        //认证申请入口
        let verifyApplyUrl: String
        
        init(config: RemoteConfig) {
            cdPrint("remote config: \(config.allKeys(from: .remote))")
            let str = config["premium_prompt"].stringValue ?? ""
            premiumPromopt = PremiumPrompt(str)
            adsFreeMinutes = config["ads_free_minutes"].numberValue?.intValue ?? 5
            popularProduct = config["popular_product"].stringValue ?? ""
            reviewProtectMinutes = config["review_protect_minutes"].numberValue? .intValue ?? 1440
            
            notificationAutoPlay = config["notification_auto_play"].boolValue
            
            premiumProducts = Set(config["ios_premium_product"].jsonValue as? [String] ?? [])
            
            chatChannels = config["chat_channels"].jsonValue as? [String] ?? []
            
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
            auditVersion = config["ios_audit_version"].stringValue ?? ""
            age_prompt_enable = config["age_prompt_enable"].boolValue
            //
            showQuickChangeRoomButton = config["show_quick_change_button"].boolValue
            defaultMainTabIndex = config["default_main_tab_index"].numberValue?.intValue ?? 0
            feedsAdInterval = config["feeds_ad_interval"].numberValue?.intValue ?? -1
            verifyApplyUrl = config["verify_apply_url"].stringValue ?? ""
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
