//
//  Automator.swift
//  Castbox
//
//  Created by ChenDong on 2017/10/17.
//  Copyright © 2017年 Guru. All rights reserved.
//

import Foundation
import RxSwift

class Automator {

    static let shared = Automator()
    private let device = Automator.Device()
//    private let analytics = Automator.Analytics()

    private let bag = DisposeBag()

    private init() {
        // FireMessage -> Routes
        // 监听通知，启动路由
        FireMessaging.shared.anpsMessageValue()
            .delay(.fromSeconds(0.2), scheduler: MainScheduler.asyncInstance)
            .subscribe(onNext: { (message) in
                cdPrint("message: \(message.uri) \(message.userInfo)")
                //version
                if let version = message.version, compareAppVersions(v1: version, v2: Constants.appVersion) {
                    //有新版本
                    NewVersionAlertController.show()
                    return
                }
                //
                if message.uri.contains("/web"),
                   let urlString = message.userInfo["url"] as? String,
                   let url = URL(string: urlString) {
                    UIApplication.topViewController()?.open(url: url)
                } else {
                    AppDelegate.handle(uri: message.uri)
                }
            })
            .disposed(by: bag)
        
        FireMessaging.shared.anpsMessageWillShowValue()
            .delay(.fromSeconds(0.5), scheduler: MainScheduler.asyncInstance)
            .subscribe(onNext: { (message) in
//                guard let roomVc = UIApplication.navigationController?.viewControllers.first as? RoomViewController else {
//                    return
//                }
//
//                roomVc.onPushReceived()
            })
            .disposed(by: bag)
        
        //只有登录才上报
        Observable.combineLatest(Settings.shared.loginResult.replay(), FireMessaging.shared.fcmTokenValue()) //, Settings.shared.isOpenSubscribeHotTopic.replay()
            .filter { $0.0 != nil }
            .map { $0.1 }
            .do(onNext: { (message) in
                //订阅 topic
                cdPrint("[Automator]  : \(String(describing: message.fcmToken)) apnsToken: \(String(describing: message.apnsTokenString))")
            })
            .flatMap { message -> Single<Bool> in
                guard let token = message.fcmToken else {
                    return .just(false)
                }
                return Request.devices(fcmToken: token)
            }
            .subscribe(onNext: { result in
                cdPrint("[Automator]  Sync token result: \(result)")
            })
            .disposed(by: bag)
        
//        FireRemote.shared.remoteValue()
//            .subscribe(onNext: { (cfg) in
//                Settings.shared.isInReview.value = (cfg.value.auditVersion == Config.appVersion)
//            })
//            .disposed(by: bag)
        
        Settings.shared.loginResult.replay()
            .filterNil()
            .flatMap({ (_) -> Single<Void> in
                Request.uploadReceipt()
            })
            .subscribe(onNext: { (_) in
            })
            .disposed(by: bag)
        
        Settings.shared.loginResult.replay()
            .filterNil()
            .take(1)
            .flatMap { (_) in
                Request.defaultProfileDecorations()
            }
            .subscribe(onNext: { (_) in
                
            })
            .disposed(by: bag)
        
        Settings.shared.defaultProfileDecorationCategoryList.replay()
            .subscribe(onNext: { (decoCateList) in
                
                let iapProductIds = decoCateList.compactMap({ $0.list.compactMap { (deco) in
                    deco.product?.products.safe(0)?.productId }
                })
                .flatMap({ $0 })
                
                guard iapProductIds.count > 0 else {
                    return
                }
                
                IAP.refreshConsumableProducts(iapProductIds)
            })
            .disposed(by: bag)
        
        Settings.shared.loginResult.replay()
            .filterNil()
            .flatMap { _ in
                NoticeManager.shared.latestNotice()
            }
            .flatMap {
                Request.noticeCheck(lastCheckMs: $0?.ms ?? 0)
            }
            .catchErrorJustReturn(false)
            .bind(to: Settings.shared.hasUnreadNoticeRelay)
            .disposed(by: bag)
        
        //
        InstalledChecker.default.installedAppReplay
            .filter { !$0.isEmpty }
            .map { $0.map { $0.bundleId } }
            .flatMap { games -> Single<Bool> in
                return Request.updateInstalled(games)
            }
            .subscribe(onNext: { result in
                cdPrint("[InstalledChecker]- update result: \(result)")
            }, onError: { error in
                cdPrint("[InstalledChecker]- update error: \(error)")
            })
            .disposed(by: bag)

    }
}
