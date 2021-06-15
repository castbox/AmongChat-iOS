//
//  Ad.Manager.swift
//  Castbox
//
//  Created by mayue_work on 2019/5/30.
//  Copyright © 2019 Guru. All rights reserved.
//

import Foundation
import SwiftyUserDefaults
import RxSwift
import RxCocoa
//import MoPub_AdMob_Adapters
import MoPub_FacebookAudienceNetwork_Adapters
import CastboxDebuger

fileprivate func cdPrint(_ message: Any) {
    Debug.info("[Ad.NativeManager]-\(message)")
}

extension Ad {

    class NativeManager: NSObject, MPNativeAdDelegate {

        static let shared = NativeManager()

        private let bag = DisposeBag()

        private let rxAdView: BehaviorSubject<UIView?> = BehaviorSubject<UIView?>(value: nil)
        private var adView: UIView? {
            didSet {
                rxAdView.onNext(adView)
            }
        }

        private weak var hostVC: UIViewController?
        private let isLoadingAdSubject: BehaviorSubject<Bool> = BehaviorSubject<Bool>(value: false)
        private var isLoadingAd = false {
            didSet {
                isLoadingAdSubject.onNext(isLoadingAd)
            }
        }
        private var clickThroughHandler: (() -> Void)?
        /*
         * 需要持有request对象，保持custom event不被释放掉
         */
        private var adRequest: MPNativeAdRequest?

        /*
         * 需要持有ad对象，保持adapter的delegate不被释放掉
         */
        private var nativeAd: MPNativeAd?

        private var impressed = false

        private var busyWithRetrying: Bool = false
        private var retryTimerDisposable: Disposable?

        private override init() {
            super.init()
//            GADMobileAds.sharedInstance().audioVideoManager.audioSessionIsApplicationManaged = true
//            GADMobileAds.sharedInstance().audioVideoManager.delegate = self
        }

        // MARK: public
        func adViewObservable() -> Observable<UIView?> {
            return rxAdView.asObservable()
        }

        func didShow(adView: UIView?, in hostVC: UIViewController, clickHandler: (() -> Void)?) {
            self.hostVC = hostVC
            self.clickThroughHandler = clickHandler
        }

        func adViewDidClose() {
            adView = nil
            nativeAd = nil
            adRequest = nil
            loadAd()
        }

        func finishDisplaying() {
            if impressed {
                adView = nil
                adRequest = nil
                nativeAd = nil
                loadAd()
            }
            hostVC = nil
        }

        // MARK: convinient functions

        func loadAd() {
            guard (adView == nil) || impressed,
                shouldShow() else { return }
            refreshAd()
        }

        private func refreshAd() {
            cdPrint("Refresh Ad start...")

            guard isLoadingAd == false else { return }

            isLoadingAd = true

            let adRequestTimeout: Int = 60
            requestAd()
                .timeout(RxTimeInterval.seconds(adRequestTimeout), scheduler: MainScheduler.instance)
                .asSingle()
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] (e) in
                    cdPrint("Load Ad success")

                    defer {
                        self?.isLoadingAd = false
                    }

                    guard let `self` = self else { return }

                    let (request, ad, adView) = e

                    ad?.delegate = self
                    self.nativeAd = ad
                    self.adView = adView
                    self.adRequest = request
                    self.impressed = false

                    self.finishRetrying()

                }, onError: { [weak self] (error) in
                    cdPrint("Load Ad failure, error: \(error)")

                    self?.startRetrying()
                    self?.isLoadingAd = false
                })
                .disposed(by: bag)

        }

        private func requestAd() -> Observable<(MPNativeAdRequest?, MPNativeAd?, UIView?)> {

            return Observable<(MPNativeAdRequest?, MPNativeAd?, UIView?)>.create { (observer) -> Disposable in

                let settings = MPStaticNativeAdRendererSettings()
                settings.renderingViewClass = NativeFeedsAdView.self

                let mopubConfiguration = MPStaticNativeAdRenderer.rendererConfiguration(with: settings)

//                let googleConfiguration = MPGoogleAdMobNativeRenderer.rendererConfiguration(with: settings)

                let facebookConfiguration = FacebookNativeAdRenderer.rendererConfiguration(with: settings)

                let configurations = [mopubConfiguration,/* googleConfiguration,*/ facebookConfiguration]

                let unitId: String = "50b3874c60944d76af15935e40527134"

                let adRequest = MPNativeAdRequest(adUnitIdentifier: unitId, rendererConfigurations: configurations as [Any])
                let targeting = MPNativeAdRequestTargeting()

                adRequest?.targeting = targeting

                let start = Date()

                adRequest?.start{ (request, nativeAd, responseError) in
                    if let err = responseError {
                        observer.onError(err)
                        let error = err as NSError
                        Logger.NativeAds.log(.load_fail, with: error)
                        switch (error.domain, error.code) {
                        case (kNSErrorDomain, Int(MOPUBErrorNoInventory.rawValue)):
                            ()
                        case (MoPubNativeAdsSDKDomain, MPNativeAdErrorCode.noInventory.rawValue):
                            ()
                        default:
                            ()
                        }
                    } else if let ad = nativeAd {
                        do {
                            let adView = try ad.retrieveAdView()
                            observer.onNext((request, ad, adView))
                            observer.onCompleted()
                            let timespan = Int64(Date().timeIntervalSince(start) * 1000)
                            Logger.NativeAds.log(.loaded(timespan))

                        } catch {
                            observer.onError(error)
                            Logger.NativeAds.log(.load_fail, with: (error as NSError))
                        }
                    } else {
                        let error = NSError(domain: "Castbox_Mopub", code: 500, userInfo: nil)
                        observer.onError(error)
                        Logger.NativeAds.log(.load_fail, with: error)
                    }
                }

                cdPrint("Start loading Ad:\(unitId) ")
                Logger.NativeAds.log(.request)

                return Disposables.create {
                }
            }
        }

        private func onAdTouched() {
            cdPrint("Ad touched.")

            clickThroughHandler?()
            adView = nil
            loadAd()
            Logger.NativeAds.log(.click)
//            //Logger.Adjust.log(.ads_clk)
        }

        private func startRetrying() {
            guard busyWithRetrying == false,
                retryTimerDisposable == nil else { return }
            cdPrint("start retrying")
            busyWithRetrying = true
            let retryInterval: Int = 15
            retryTimerDisposable = Observable<Int>.interval(RxTimeInterval.seconds(retryInterval), scheduler: MainScheduler.instance)
                .filter({ _ in UIApplication.shared.applicationState == .active })
                .take(3)
                .subscribe(onNext: { [weak self] (_) in
                    self?.loadAd()
                    }, onCompleted: { [weak self] in
                        guard let `self` = self else { return }
                        if self.isLoadingAd {
                            self.isLoadingAdSubject
                                .skipWhile({ $0 })
                                .take(1)
                                .subscribe(onNext: { (_) in
                                    self.finishRetrying()
                                })
                                .disposed(by: self.bag)
                        } else {
                            self.finishRetrying()
                        }
                })
        }

        private func finishRetrying() {
            cdPrint("finish retrying")
            busyWithRetrying = false
            retryTimerDisposable?.dispose()
            retryTimerDisposable = nil
        }

        // MARK: MPNativeAdDelegate

        func willPresentModal(for nativeAd: MPNativeAd!) {
            onAdTouched()
        }

        func didDismissModal(for nativeAd: MPNativeAd!) {
        }

        func willLeaveApplication(from nativeAd: MPNativeAd!) {
            onAdTouched()
        }

        func viewControllerForPresentingModalView() -> UIViewController! {

            if hostVC != nil {
                return hostVC
            } else {
                return (UIApplication.shared.delegate as! AppDelegate).window?.rootViewController!
            }
        }

        func mopubAd(_ ad: MPMoPubAd, didTrackImpressionWith impressionData: MPImpressionData?) {
            cdPrint("Ad impressed. AdUnit=\(impressionData?.adUnitID ?? "")")
            Logger.NativeAds.log(.show)
            //Logger.Adjust.log(.ads_imp)
            impressed = true

//            let refreshInterval = FireRemote.shared.value.adConfig.native_refresh_s
            let refreshInterval = 60
            guard refreshInterval > 0,
                let adView = self.adView else { return }

            Observable<UIView>.just(adView)
                .delay(RxTimeInterval.seconds(Int(refreshInterval)), scheduler: MainScheduler.instance)
                .subscribe(onNext: { [weak self] (adView) in
                    guard let `self` = self,
                        adView === self.adView,
                        adView.superview != nil else { return }
                    self.refreshAd()
                })
                .disposed(by: bag)

        }

    }
}

//extension Ad.NativeManager: GADAudioVideoManagerDelegate {
//
//    func audioVideoManagerWillPlayAudio(_ audioVideoManager: GADAudioVideoManager) {
//        audioVideoManager.audioSessionIsApplicationManaged = true
//    }
//
//    func audioVideoManagerWillPlayVideo(_ audioVideoManager: GADAudioVideoManager) {
//        audioVideoManager.audioSessionIsApplicationManaged = true
//    }
//
//    func audioVideoManagerDidPauseAllVideo(_ audioVideoManager: GADAudioVideoManager) {
//        audioVideoManager.audioSessionIsApplicationManaged = true
//    }
//
//    func audioVideoManagerDidStopPlayingAudio(_ audioVideoManager: GADAudioVideoManager) {
//        audioVideoManager.audioSessionIsApplicationManaged = true
//    }
//}

extension Ad {
    static func shouldShow() -> Bool {
        let isPremium = Settings.shared.isProValue.value
//        let isInAudit = Defaults[\.useStandardFreetrialText]
//        let freeToShow: Bool = {
////            let free_m = FireRemote.shared.value.adConfig.free_m
//            let free_m: Double = 2
//            let freeFrom = Settings.shared.appInstallDate.timeIntervalSince1970
//
//            let secPerMinute: Double = 60
//            let freeDuration = Date().timeIntervalSince1970 - freeFrom
//
//            return freeDuration > (free_m * secPerMinute)
//        }()
//
//        let flag = !isInAudit && freeToShow && !isPremium
//        cdPrint("shouldShow:\(flag)")
//        return flag
        return !isPremium
    }
}
