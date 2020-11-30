//
//  Ad.AppOpenAdManager.swift
//  Castbox
//
//  Created by mayue_work on 2020/10/14.
//  Copyright © 2020 Guru. All rights reserved.
//

import Foundation
import GoogleMobileAds
import SwiftyUserDefaults
import RxSwift
import RxCocoa
import CastboxDebuger

extension Ad {
    
    class AppOpenAdManager: NSObject, GADFullScreenContentDelegate {
        
        static let shared = AppOpenAdManager()
        
        private var appOpenAd: GADAppOpenAd? = nil
        private var loadedTime: Date = Date()
        
        private override init() { }
        
        private func shouldLoad() -> Bool {
            let enabled = FireRemote.shared.value.app_open_ad_config.enable
            let freeToShow: Bool = {
                let free_h = FireRemote.shared.value.app_open_ad_config.free_h
                let freeFrom = Settings.shared.appInstallDate
                let secPerH: Double = 60 * 60
                let freeDuration = Date().timeIntervalSince(freeFrom)
                return freeDuration > (free_h * secPerH)
            }()
            
            let isPremium = Settings.shared.isProValue.value
            let flag = enabled &&
                freeToShow &&
                !isPremium
            return flag
        }
        
        private func shouldShow() -> Bool {
            let intervalExpired: Bool = {
                let interval = FireRemote.shared.value.app_open_ad_config.interval_s
                let lastImpTs = Defaults[\.appOpenAdShowTime]
                return Date().timeIntervalSince(Date(timeIntervalSince1970: lastImpTs)) > interval
            }()
            
            let isPremium = Settings.shared.isProValue.value
            let flag = !isPremium && intervalExpired
            return flag
        }
        
        private func requestAppOpenAd() {
            guard shouldLoad() else {
                return
            }
            self.appOpenAd = nil
            let loadAt = Date()
            Logger.AppOpenAd.logEvent(.oads_load)
            GADAppOpenAd.load(withAdUnitID: FireRemote.shared.value.app_open_ad_config.adId, request: GADRequest(), orientation: .portrait) { [weak self] (appOpenAd, error) in
                guard let `self` = self else { return }
                guard let ad = appOpenAd else {
                    if let err = error {
                        Logger.AppOpenAd.logEvent(.oads_failed(error: err))
                    }
                    return
                }
                ad.fullScreenContentDelegate = self
                self.appOpenAd = ad
                let loadTs = Date().timeIntervalSince(loadAt)
                self.loadedTime = Date()
                Logger.AppOpenAd.logEvent(.oads_loaded(ts: Int64(loadTs * 1000)))
            }
        }
        
        private func wasLoadTimeLessThanNHoursAgo(_ n: Int) -> Bool {
            let now = Date()
            let timeIntervalBetweenNowAndLoadTime = now.timeIntervalSince(loadedTime)
            let secondsPerHour = Double(3600)
            let intervalInHours = Int(timeIntervalBetweenNowAndLoadTime / secondsPerHour)
            return intervalInHours < n
        }
        
        func tryToPresentAd() {
            let presentAd = { (ad: GADAppOpenAd) in
                let _  = Observable.just(())
                    .delay(.milliseconds(Int(FireRemote.shared.value.app_open_ad_config.delay_s * 1000)), scheduler: MainScheduler.instance)
                    .subscribe(onNext: {  [weak self] _ in
                        
                        guard let `self` = self,
                              self.shouldShow() else { return }
                        
                        guard let vc = UIApplication.topViewController(),
                              vc is AmongChat.Home.ViewController else { return }
                        
                        ad.present(fromRootViewController: vc)
                    })
            }
            
            if let ad = appOpenAd,
               wasLoadTimeLessThanNHoursAgo(4) {
                presentAd(ad)
            } else {
                requestAppOpenAd()
            }
        }
        
        // MARK: - GADFullScreenContentDelegate
            
        func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
            Logger.AppOpenAd.logEvent(.oads_failed(error: error))
            requestAppOpenAd()
        }
        
        func adDidPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
            Logger.AppOpenAd.logEvent(.oads_imp)
            Defaults[\.appOpenAdShowTime] = Date().timeIntervalSince1970
        }
        
        func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
            Logger.AppOpenAd.logEvent(.oads_close)
            requestAppOpenAd()
        }
        
    }
    
}
