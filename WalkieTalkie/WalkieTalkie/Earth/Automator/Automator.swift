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
            .subscribe(onNext: { (message) in
//                Routes.handle(message.uri)
                cdPrint("message: \(message.uri) \(message.userInfo)")
                AppDelegate.handle(uri: message.uri)
            })
            .disposed(by: bag)
        
        FireMessaging.shared.fcmTokenValue()
            .subscribe(onNext: { (message) in
//                Routes.handle(message.uri)
                //订阅 topic
                cdPrint("[Automator]  : \(String(describing: message.fcmToken)) apnsToken: \(String(describing: message.apnsTokenString))")
            })
            .disposed(by: bag)
    }
}
