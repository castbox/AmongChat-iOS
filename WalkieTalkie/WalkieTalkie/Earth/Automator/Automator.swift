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
            .delay(.fromSeconds(0.5), scheduler: MainScheduler.asyncInstance)
            .subscribe(onNext: { (message) in
//                Routes.handle(message.uri)
                cdPrint("message: \(message.uri) \(message.userInfo)")
                AppDelegate.handle(uri: message.uri)
            })
            .disposed(by: bag)
        
        //只有登录才上报
        Observable.combineLatest(Settings.shared.loginResult.replay(), FireMessaging.shared.fcmTokenValue(), Settings.shared.isOpenSubscribeHotTopic.replay())
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
                var params = Constants.deviceInfo()
                params["deviceToken"] = token
                return Request.devices(params: params)
            }
            .subscribe(onNext: { result in
                cdPrint("[Automator]  Sync token result: \(result)")
            })
            .disposed(by: bag)
        
        _ = Request.login(deviceId: Constants.deviceID)
            .subscribe(onSuccess: { result in
                Settings.shared.loginResult.value = result
            })
        
        Settings.shared.loginResult.replay()
            .filterNil()
            .take(1)
            .subscribe(onNext: { [weak self] (result) in
                self?.startHeartbeat()
                self?.initializeProfileIfNeeded(result.uid)
            })
            .disposed(by: bag)
        
        bindProToFirestore()
    }
}
extension Automator {
    
    private func startHeartbeat() {
        #if DEBUG
        let interval: Int = 10
        #else
        let interval: Int = 30
        #endif
        Observable<Int>.interval(.seconds(interval), scheduler: MainScheduler.instance)
            .subscribe(onNext: { (_) in
                guard let loginResult = Settings.shared.loginResult.value else { return }
                FireStore.shared.updateHeartbeat(of: loginResult.uid)
            })
            .disposed(by: bag)
    }
    
    private func initializeProfileIfNeeded(_ uid: String) {
        FireStore.shared.fetchUserProfile(uid)
            .retry(2)
            .subscribe(onSuccess: { (profile) in
                if let profile = profile {
                    Settings.shared.firestoreUserProfile.value = profile
                } else {
                    let profile = FireStore.Entity.User.Profile(avatar: "",
                                                                birthday: "",
                                                                name: "User \(Constants.sUserId)",
                        premium: Settings.shared.isProValue.value,
                        uidInt: Constants.sUserId)
                    
                    FireStore.shared.updateProfile(profile, of: uid)
                }
                
            })
            .disposed(by: bag)
    }
    
    private func bindProToFirestore() {
        Observable.combineLatest(Settings.shared.isProValue.replay(), Settings.shared.firestoreUserProfile.replay())
            .filter { $0.1 != nil }
            .subscribe(onNext: { (isPro, profile) in
                guard var profile = profile,
                    let uid = Settings.shared.loginResult.value?.uid else {
                    return
                }
                profile.premium = isPro
                FireStore.shared.updateProfile(profile, of: uid)
            })
            .disposed(by: bag)
    }
}
