//
//  AdsManager.swift
//  Scanner
//
//  Created by 江嘉睿 on 2019/9/18.
//  Copyright © 2019 江嘉睿. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
//import AppMonet_Mopub
import MoPub
//import MoPub_FacebookAudienceNetwork_Adapters
//import MoPub_AdMob_Adapters
//import DTBiOSSDK
//import FBAudienceNetwork
import CastboxDebuger
import SwifterSwift
//import GoogleMobileAds

enum AdsState: Int {
    case preparing = 0
    case nativeActive
    case bannerAutoRefreshing
    case inactive
}

enum ShowSelection: Int {
    case native = 0
    case banner = 1
}

let debugAds: Bool = false

fileprivate func cdPrint(_ message: Any) {
    Debug.info("[AdsManager]-\(message)")
}

class AdsManager: NSObject {
    static let shared = AdsManager()
    static let notificationCenter = NotificationCenter()
    private let bag = DisposeBag()
    
    var amazonRequestCount: Int = 0
    
    weak var presentingVc: UIViewController?
    
    var fallbackBannerView: MPAdView?
    
    var showSelection = ShowSelection.native
    
    var mopubInitializeSuccessSubject = BehaviorRelay<Bool>(value: false)
    
    private let isRewardVideoReadyRelay: BehaviorRelay<[String : Bool]> = {
        let map = RewardedVideoPosition.allCases.map({ (AdsManager.rewardedVideoAdUnitId(of: $0), false) }).reduce(into: [:]) { $0[$1.0] = $1.1 }
        return BehaviorRelay(value: map)
    }()
    
    var rewardedVideoAdDidDisappear = PublishSubject<Void>()
    
    var rewardVideoShouldReward = PublishSubject<Bool>()
    
    override init() {
        super.init()
        //        setupAppmonet()
        setupMopub()
        //        setupAws()
        //        setupFacebook()
        setupAdmob()
//        setupRefresh()
//        setupEventListener()

    }
    
    private let nativeRefreshEvent = PublishSubject<Observable<Void>>()
    
    //    private func setupAppmonet() {
    //        let config = AppMonetConfigurations.configuration { (builder) in
    //            builder?.applicationId = "lgau02h8"
    //        }
    //        AppMonet.initialize(config)
    //    }
    
    
    private func setupMopub() {
        let config = MPMoPubConfiguration(adUnitIdForAppInitialization: Self.rewardedVideoAdUnitId(of: .unlockAvatar))
        #if DEBUG
        config.loggingLevel = .debug
        #endif
        MoPub.sharedInstance().initializeSdk(with: config) {
            DispatchQueue.main.async { [weak self] in
                //send notification
                self?.mopubInitializeSuccessSubject.accept(true)
                //req
//                Ad.InterstitialManager.shared.loadAd()
                RewardedVideoPosition.allCases.forEach {
                    MPRewardedVideo.setDelegate(self, forAdUnitId: Self.rewardedVideoAdUnitId(of: $0))
                    self?.requestRewardVideoIfNeed(adUnitId: Self.rewardedVideoAdUnitId(of: $0))
                }
            }
        }
        
        
    }
    
    private func setupAdmob() {
//        GADMobileAds.sharedInstance().audioVideoManager.audioSessionIsApplicationManaged = true
//        GADMobileAds.sharedInstance().applicationVolume = 0
//        GADMobileAds.sharedInstance().applicationMuted = true
//        #if DEBUG
//        //        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [kGADSimulatorID as! String]
//        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = []
//        #endif
    }
    
    //    private func setupAws() {
    //        if AdsConstants.awsDTBEnabled {
    //            DTBAds.sharedInstance().setAppKey(AdsConstants.awsAppKey)
    //            DTBAds.sharedInstance().mraidPolicy = MOPUB_MRAID
    //            #if DEBUG
    ////            DTBAds.sharedInstance().testMode = true
    ////            DTBAds.sharedInstance().setLogLevel(DTBLogLevelAll)
    //            #endif
    //        }
    //    }
    
    var awsRequestCount = 0
    
    //    private func setupFacebook() {
    //        #if DEBUG
    //        FBAdSettings.setLogLevel(.log)
    //        FBAdSettings.addTestDevices(["b602d594afd2b0b327e07a06f36ca6a7e42546d0"])
    ////        FBAdSettings.clearTestDevices()
    //        #endif
    //    }
    
//    private func setupEventListener() {
//        AdsManager.notificationCenter.rx.notification(.adEvent)
//            .subscribe(onNext: { (noti) in
//                guard let object = noti.object, let info = object as? AdEventInfo else {
//                    return
//                }
//                mlog.debug(info.basicDescription(), context: "ads_event")
//            }).disposed(by: bag)
//    }
    
    func hasAdAvailableRewardsVideo(adUnitId: String) -> Bool {
         return MPRewardedVideo.hasAdAvailable(forAdUnitID: adUnitId)
    }
    
    func aviliableRewardVideo(adunitId: String) -> MPRewardedVideoReward? {
        cdPrint("aviliableRewardVideo: \(MPRewardedVideo.availableRewards(forAdUnitID: adunitId))")
        guard hasAdAvailableRewardsVideo(adUnitId: adunitId) else {
            return nil
        }
        return MPRewardedVideo.selectedReward(forAdUnitID: adunitId)
    }
    
    
    static var nativeAdsRefreshInterval: TimeInterval {
        return 120
    }
    
    
    private var nativeLastShowDate: Date = Date().addingTimeInterval(0 - AdsManager.nativeAdsRefreshInterval)
    private var nativeLastRequestDate: Date = Date()
    
//    func pause() {
//        switch self.showSelection {
//        case .native:
//            stopNativeAdRefresh()
//        case .banner:
//            fallbackBannerView?.stopAutomaticallyRefreshingContents()
//        }
//        stopNativeAdRefresh()
//    }
    
//    func resume(forceNative: Bool) {
//        if !forceNative, self.showSelection == .banner {
//            fallbackBannerView?.startAutomaticallyRefreshingContents()
//        } else {
//            self.showSelection = .native
//            if forceNative {
//                requestNativeAds()
//            } else {
//                let now = Date()
//                if now.timeIntervalSince(nativeLastShowDate) > AdsManager.nativeAdsRefreshInterval {
//                    requestNativeAds()
//                } else {
//                    let fireTime = AdsManager.nativeAdsRefreshInterval - now.timeIntervalSince(nativeLastShowDate)
//                    refreshNative(after: .milliseconds(Int(1000 * fireTime)))
//                }
//            }
//        }
//    }
    
//    private func setupRefresh() {
//        nativeRefreshEvent
//            .flatMapLatest({ $0 })
//            .subscribe(onNext: { [unowned self] (a) in
//                self.requestNativeAds()
//            })
//            .disposed(by: bag)
//    }
    
//    private func stopNativeAdRefresh() {
//        nativeRefreshEvent.onNext(.never())
//    }
    
    var onNativeRequestFailed: ()->Void = {}
    
//    var nativeAd: MPNativeAd?
    var latestNativeAdView: UIView?
    
//    func requestNativeAds() {
//        let request = MPNativeAdRequest(adUnitIdentifier: nativeAdUnitId, rendererConfigurations: nativeAdConfigurations)
//        request?.targeting = MPNativeAdRequestTargeting()
////        Logger.Ads.logNativeEvent(.request)
//        nativeLastRequestDate = Date()
//        AdsManager.notificationCenter.post(name: Notification.Name.adEvent, object: AdEventInfo(format: .native, event: .request, eventTime: nativeLastRequestDate, requestTime: nativeLastRequestDate))
//        request?.start(completionHandler: { [weak self] (req, ad, err) in
//            guard let `self` = self else {
//                return
//            }
//            guard let a = ad else {
////                Logger.Ads.logNativeEvent(.nofill)
//                AdsManager.notificationCenter.post(name: .adEvent, object: AdEventInfo(format: .native, event: .nofill, eventTime: Date(), requestTime: self.nativeLastRequestDate))
//                self.nativeRefreshEvent.onNext(.never())
//                self.rxAdView.accept(nil)
//                self.showSelection = .banner
//                self.latestNativeAdView = nil
//                self.onNativeRequestFailed()
//                return
//            }
//            AdsManager.notificationCenter.post(name: .adEvent, object: AdEventInfo(format: .native, event: .load, eventTime: Date(), requestTime: self.nativeLastRequestDate))
////            Logger.Ads.logNativeEvent(.load)
//            self.nativeAd = a
//            do {
//                a.delegate = self
//                let adView = try a.retrieveAdView()
//                self.latestNativeAdView = adView
////                Logger.Ads.logNativeEvent(.rendered)
//                AdsManager.notificationCenter.post(name: .adEvent, object: AdEventInfo(format: .native, event: .rendered, eventTime: Date(), requestTime: self.nativeLastRequestDate))
//                self.nativeLastShowDate = Date()
//                self.rxAdView.accept(adView)
//                //                self.refreshNative(after: .seconds(FireRemote.shared.value.nativeRefreshSeconds))
//            } catch {
////                Logger.Ads.logNativeEvent(.renderFail)
//                AdsManager.notificationCenter.post(name: .adEvent, object: AdEventInfo(format: .native, event: .renderFail, eventTime: Date(), requestTime: self.nativeLastRequestDate))
//                self.rxAdView.accept(nil)
//                self.showSelection = .banner
//                self.latestNativeAdView = nil
//                self.onNativeRequestFailed()
//                self.nativeRefreshEvent.onNext(.never())
//            }
//        })
//    }
    
    private func requestRewardVideoIfNeed(adUnitId: String) {
//        guard aviliableRewardVideo == nil,
//            !Settings.shared.isProValue.value else {
//            return
//        }
        cdPrint("requestRewardVideo hasLoaded: \(isRewardVideoReadyRelay.value)")
//        guard aviliableRewardVideo == nil else {
//            return
//        }
        guard let ready = isRewardVideoReadyRelay.value[adUnitId],
            !ready else {
            return
        }
        cdPrint("requestRewardVideo")
        Logger.Ads.logEvent(.rads_load)
        
        MPRewardedVideo.loadAd(withAdUnitID: adUnitId, withMediationSettings: nil)
        
    }
    
//    private func refreshNative(after interval: RxTimeInterval) {
//        nativeRefreshEvent.onNext(Observable<Int64>.timer(interval, scheduler: MainScheduler.asyncInstance).map({ _ in () }))
//    }
    
    let rxAdView = BehaviorRelay<UIView?>.init(value: nil)
    
//    var nativeAdConfigurations: [MPNativeAdRendererConfiguration] = {
//        //        let configuration = MPNativeAdRendererConfiguration()
//        let settings = MPStaticNativeAdRendererSettings()
//        settings.renderingViewClass = NativeAdView.self
//
//        let mopubSetting = MPStaticNativeAdRenderer.rendererConfiguration(with: settings)
//
//        //        let facebookSetting = FacebookNativeAdRenderer.rendererConfiguration(with: settings)
//
//        //        let facebookSetting = FacebookNativeAdRenderer.rendererConfiguration(with: MPStaticNativeAdRendererSettings())
//
//        let admobSetting = MPGoogleAdMobNativeRenderer.rendererConfiguration(with: settings)
//
//        //        return [facebookSetting]
//        //        return [admobSetting!]
//        //        return [mopubSetting!]
//        //        return []
//        //        return [facebookSetting, admobSetting!, mopubSetting!]
//        return [admobSetting!, mopubSetting!]
//    }()
    
//    var nativeAdUnitId: String {
//        return "8646296467d941ef8a01dc548508b0fc"
//        //        return "76a3fefaced247959582d2d2df6f4757"
//    }
//
//    var compactAdViewId: String {
//        #if DEBUG
//        /// debug ad id
//        //        return "0ac59b0996d947309c33f59d6676399f"
//        /// online ad id
//        return "156615c0b77140bfa9465efe32a6b39b"
//        /// adview with only appmonet
//        //        return "768726ab8d3446448a7ee4329161dcdd"
//        #else
//        return "156615c0b77140bfa9465efe32a6b39b"
//        #endif
//    }
//
//    var extendedAdViewId: String {
//        #if DEBUG
//        /// aws ad id
//        //        return "2fc098daa08643f8a632323364d8c478"
//        /// debug ad id
//        //        return "2aae44d2ab91424d9850870af33e5af7"
//        /// online ad id
//        //        return "156615c0b77140bfa9465efe32a6b39b"
//        /// adview with only appmonet
//        return "768726ab8d3446448a7ee4329161dcdd"
//        #else
//        return "156615c0b77140bfa9465efe32a6b39b"
//        #endif
//    }
//
//    var rewardedVideoId: String {
////        if Config.environment == .debug {
////            return "8f000bd5e00246de9c789eed39ff6096"
////        } else {
//            return "a545cd81a6814a4bb06a6e6055ed5e58"
////        }
////           #if DEBUG
////           /// aws ad id
////           //        return "2fc098daa08643f8a632323364d8c478"
////           /// debug ad id
////           //        return "2aae44d2ab91424d9850870af33e5af7"
////           /// online ad id
////           //        return "156615c0b77140bfa9465efe32a6b39b"
////           /// adview with only appmonet
////           return "a545cd81a6814a4bb06a6e6055ed5e58"
////           #else
////           return "a545cd81a6814a4bb06a6e6055ed5e58"
////           #endif
//       }
    
//    func shouldShowInterstitial() -> Bool {
//        guard Settings.shared.isProValue.value == false else { return false }
//        //        let rc = FireRemote.shared.value.interstitialConfig
//        //        guard rc.enable else { return false }
//        //        let now = Date()
//        //        if now.timeIntervalSince(Settings.shared.appInstallDate) < Double(rc.freeMinutes * 60) {
//        return false
//        //        }
//        //        if now.timeIntervalSince(Settings.shared.interstitalLastShowTime) < Double(rc.reloadSeconds) { return false }
//        //        return true
//    }
    
    private var hasRetryForAdLoadFailed = false
    
    enum RewardedVideoPosition: CaseIterable {
        case unlockAvatar
        case channelCard
    }
    
    private class func rewardedVideoAdUnitId(of adPostion: RewardedVideoPosition) -> String {
        switch adPostion {
        case .unlockAvatar:
            return "a545cd81a6814a4bb06a6e6055ed5e58"
        case .channelCard:
            return "bacb18c823584a5cbcd04f6768e7bf9b"
        }
    }
    
    func earnARewardOfVideo(fromVC: UIViewController, adPosition: RewardedVideoPosition) -> Observable<Void> {
        
        hasRetryForAdLoadFailed = false
        
        let adUnitId = Self.rewardedVideoAdUnitId(of: adPosition)
        
//        requestRewardVideoIfNeed(adUnitId: adUnitId)
        
        return isRewardVideoReadyRelay
            .filter { [weak self] map -> Bool in
                guard let `self` = self else { return false }
                
                let isReady = map[adUnitId] ?? false
                
                if isReady, self.aviliableRewardVideo(adunitId: adUnitId) == nil {
                    //如果 Load 成功，但拿不到 reward video， 则重新请求
                    if !self.hasRetryForAdLoadFailed {
                        self.hasRetryForAdLoadFailed = true
                        var map = map
                        map[adUnitId] = false
                        self.isRewardVideoReadyRelay.accept(map)
                        self.requestRewardVideoIfNeed(adUnitId: adUnitId)
                    }
                    return false
                }
                return isReady
            }
            .take(1)
            .timeout(.seconds(30), scheduler: MainScheduler.asyncInstance)
            .flatMap { [weak self] _ -> Observable<Void> in
                guard let `self` = self else { return  .empty() }
                self.hasRetryForAdLoadFailed = false
                guard let reward = self.aviliableRewardVideo(adunitId: adUnitId) else {
                    return Observable.error(MsgError(code: 400, msg: R.string.localizable.amongChatRewardVideoLoadFailed()))
                }
                
                MPRewardedVideo.presentAd(forAdUnitID: adUnitId, from: fromVC, with: reward)
                
                return self.rewardVideoShouldReward.asObservable()
                    .flatMap { shouldReward -> Observable<Void> in
                        guard shouldReward else {
                            return Observable.error(MsgError(code: 500, msg: R.string.localizable.amongChatRewardVideoLoadFailed()))
                        }
                        return self.rewardedVideoAdDidDisappear.asObservable()
                    }
            }
    }
}

struct AdsConstants {
    static let awsDTBEnabled = true
//    static let awsTestMopubID = "2fc098daa08643f8a632323364d8c478"
//    static fileprivate let awsTestSlotID = "5ab6a4ae-4aa5-43f4-9da4-e30755f2b295"
//    static fileprivate let awsOnlineSlotId = "a6472cb1-8f6d-4145-ae60-f2ec79d657e4"
    //    static let awsTestSlot = DTBAdSize(bannerAdSizeWithWidth: 320, height: 50, andSlotUUID: awsTestSlotID)
    //    static let awsOnlineSlot = DTBAdSize(bannerAdSizeWithWidth: 300, height: 250, andSlotUUID: awsOnlineSlotId)
    #if DEBUG
    /// test config
    //    static let awsAppKey = "a9_onboarding_app_id"
    //    static let awsSlot = awsTestSlot
    
    /// online config
    //    static let awsAppKey = "ec199a68-0570-4a0e-b9ac-1004a3e47dba"
    //    static let awsSlot = awsOnlineSlot
    #else
    //    static let awsAppKey = "ec199a68-0570-4a0e-b9ac-1004a3e47dba"
    //    static let awsSlot = awsOnlineSlot
    #endif
}

//extension AdsManager: MPNativeAdDelegate {
//    func viewControllerForPresentingModalView() -> UIViewController! {
//        return presentingVc!
//    }
//
//    func mopubAd(_ ad: MPMoPubAd, didTrackImpressionWith impressionData: MPImpressionData?) {
//        NSLog("native ad impressioned")
//        AdsManager.notificationCenter.post(name: .adEvent, object: AdEventInfo(format: .native, event: .impl, eventTime: Date(), requestTime: self.nativeLastRequestDate))
////        Logger.Ads.logNativeEvent(.impl)
//        self.refreshNative(after: .fromSeconds(AdsManager.nativeAdsRefreshInterval))
//        //        self.refreshNative(after: .seconds(FireRemote.shared.value.nativeRefreshSeconds))
//    }
//
//    func willPresentModal(for nativeAd: MPNativeAd!) {
////        Logger.Ads.logNativeEvent(.click)
//        //        PlayerController.shared.showSource = .adModal
//    }
//
//    func didDismissModal(for nativeAd: MPNativeAd!) {
//    }
//
//    func willLeaveApplication(from nativeAd: MPNativeAd!) {
//        NSLog("native ad clicked")
////        Logger.Ads.logNativeEvent(.click)
//        //        PlayerController.shared.showSource = .adLeave
//    }
//}

extension AdsManager: MPRewardedVideoDelegate {
    
    //did load
    func rewardedVideoAdDidLoad(forAdUnitID adUnitID: String!) {
        //reward did load
        var map = isRewardVideoReadyRelay.value
        map[adUnitID] = true
        isRewardVideoReadyRelay.accept(map)
        Logger.Ads.logEvent(.rads_loaded)
        cdPrint("rewardedVideoAdDidLoad")
    }
    
    func rewardedVideoAdDidExpire(forAdUnitID adUnitID: String!) {
        var map = isRewardVideoReadyRelay.value
        map[adUnitID] = false
        isRewardVideoReadyRelay.accept(map)
        cdPrint("rewardedVideoAdDidExpire")
        requestRewardVideoIfNeed(adUnitId: adUnitID)
    }
    
    func rewardedVideoAdWillAppear(forAdUnitID adUnitID: String!) {
        cdPrint("rewardedVideoAdWillAppear")
        Logger.Ads.logEvent(.rads_imp)
    }

    func rewardedVideoAdDidAppear(forAdUnitID adUnitID: String!) {
        var map = isRewardVideoReadyRelay.value
        map[adUnitID] = false
        isRewardVideoReadyRelay.accept(map)
        cdPrint("rewardedVideoAdDidAppear")
    }
    
    func rewardedVideoAdDidDisappear(forAdUnitID adUnitID: String!) {
        cdPrint("rewardedVideoAdDidDisappear")
        //request new one
        rewardedVideoAdDidDisappear.onNext(())
        Logger.Ads.logEvent(.rads_close)
        mainQueueDispatchAsync(after: 0.1) {
            self.requestRewardVideoIfNeed(adUnitId: adUnitID)
        }
    }

    func rewardedVideoAdDidFailToLoad(forAdUnitID adUnitID: String!, error: Error!) {
        var map = isRewardVideoReadyRelay.value
        map[adUnitID] = false
        isRewardVideoReadyRelay.accept(map)
        cdPrint("rewardedVideoAdDidFailToLoad: \(String(describing: error))")
        Logger.Ads.logEvent(.rads_failed)
        //did error
        mainQueueDispatchAsync(after: 15) { [weak self] in
            self?.requestRewardVideoIfNeed(adUnitId: adUnitID)
        }
    }
    
    func rewardedVideoAdShouldReward(forAdUnitID adUnitID: String!, reward: MPRewardedVideoReward!) {
        //should reward
        rewardVideoShouldReward.onNext(true)
        cdPrint("rewardedVideoAdShouldReward")
    }
    
    func rewardedVideoAdDidReceiveTapEvent(forAdUnitID adUnitID: String!) {
        cdPrint("rewardedVideoAdDidReceiveTapEvent")
        Logger.Ads.logEvent(.rads_clk)
    }
    
    func rewardedVideoAdDidFailToPlay(forAdUnitID adUnitID: String!, error: Error!) {
        cdPrint("rewardedVideoAdDidFailToPlay: \(String(describing: error))")
        rewardVideoShouldReward.onNext(false)
        mainQueueDispatchAsync(after: 15) { [weak self] in
            self?.requestRewardVideoIfNeed(adUnitId: adUnitID)
        }
    }
    
}
