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
        
        FireMessaging.shared.anpsMessageWillShowValue()
            .delay(.fromSeconds(0.5), scheduler: MainScheduler.asyncInstance)
            .subscribe(onNext: { (message) in
                guard let roomVc = UIApplication.navigationController?.viewControllers.first as? RoomViewController else {
                    return
                }
                
                roomVc.onPushReceived()
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
        
        // 获取系统头像
        let _ = Request.defaultAvatars()
            .subscribe(onSuccess: { (_) in
                
            })
    }
}
