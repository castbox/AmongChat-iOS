//
//  Automator.Device.swift
//  Castbox
//
//  Created by ChenDong on 2018/4/27.
//  Copyright © 2018年 Guru. All rights reserved.
//

import Foundation
import RxSwift
import FirebaseInstanceID

extension Automator {
    
    class Device {
        
        private let bag = DisposeBag()
        
        init() {
            /// 用户即将登出时候，从 DB 中移除 Device
//            Knife.Auth.shared
//                .loginResult
//                .willSet()
//                .filter({ $0.new == nil })
//                .subscribe(onNext: { (auth) in
//                    guard let deviceID = Constant.deviceID else {
//                        assert(false, "userRef should not be nil here")
//                        return
//                    }
//                    DB.Device.remove(device: deviceID)
//                })
//                .disposed(by: bag)
//            
//            /// 用户登录后，往 DB 写入 Device
//            let userValue = Knife.Auth.shared.loginResult.replay()
//            let tokenValue = FireMessaging.shared.fcmTokenValue().map({ $0.fcmToken })
//            let followingPushValue = Settings.shared.isFollowingPushOpen.replay()
//            let momentPushValue = Settings.shared.isMomentsPushOpen.replay()
//            let isSystemPushValue = Settings.shared.isSystemPushOpen.replay()
//            let messagePushValue = Settings.shared.isMessagePushOpen.replay()
//            
//            Observable.combineLatest(userValue,
//                                     tokenValue,
//                                     followingPushValue,
//                                     momentPushValue,
//                                     isSystemPushValue,
//                                     messagePushValue,
//                                     resultSelector: {
//                                        return (user: $0, token: $1, followingPush: $2, momentPush: $3, systemPush: $4, messagePush: $5) })
//                .subscribe(onNext: { (tuple) in
//                    guard let _ = Knife.Auth.shared.loginResult.value,
//                        let token = tuple.token,
//                        let deviceID = Constant.deviceID else { return}
//                    DB.Device.add(device: deviceID, token: token)
//                    _ = Request.device(fcmToken: token, followingPush: tuple.followingPush, momentPush: tuple.momentPush, systemPush: tuple.systemPush, messagePush: tuple.messagePush)
//                        .subscribe(onNext: { (success) in
//                            cdPrint("synchronize device info \(success)")
//                        })
//                    
//                })
//                .disposed(by: bag)
            
//            /// 上面 5 个变量变化时，更新设置到服务器
//            Observable.combineLatest(userValue,
//                                     tokenValue,
//                                     episodePushValue,
//                                     recommendationPushValue,
//                                     newsletterValue,
//                                     resultSelector: {
//                                        return (user: $0, token: $1, episodePush: $2, recommendationPush: $3, newsletter: $4) })
//                .subscribe(onNext: { tuple in
//                    /// 同时通过 HTTP Api 传递给 Server，以防万一
//                    guard let _ = Knife.Auth.shared.loginResult.value,
//                        let token = tuple.token,
//                        let deviceID = Constant.deviceID else {
//                            return
//                    }
//
//                    DB.Device.add(device: deviceID, token: token)
//
//                    _ = Request.synchronize(fcmToken: token,
//                                            receiveSubscriptionPush: tuple.episodePush,
//                                            receiveRecommendationPush: tuple.recommendationPush,
//                                            receiveNewsletter: tuple.newsletter)
//                        .subscribe(onNext: { (succeed) in
//                            cdPrint("synchronize fcm token \(succeed)")
//                        })
//                })
//                .disposed(by: bag)
        }
    }
}


