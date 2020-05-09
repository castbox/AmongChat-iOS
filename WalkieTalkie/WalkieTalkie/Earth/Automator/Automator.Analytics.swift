//
//  Automator.Analytics.swift
//  Castbox
//
//  Created by ChenDong on 2018/5/11.
//  Copyright © 2018年 Guru. All rights reserved.
//

import Foundation
import RxSwift
import Crashlytics

extension Automator {
    
//    class Analytics {
//        
//        private let bag = DisposeBag()
//        
//        init() {
//            Knife.Auth.shared
//                .loginResult
//                .replay()
//                .subscribe(onNext: { (ret) in
//                    guard let uid = ret?.uid else { return }
//                    Runner.Analytics.log(userID: uid)
//
//                    guard let pro = ret?.provider, let p = Logger.UserProperty.Node.Start.AccountProvider(rawValue: pro) else { return }
//                    Logger.UserProperty.start(with: .start(.accountProvider(p))).log()
//                })
//                .disposed(by: bag)
//            
//            Settings.shared.selectedCountry
//                .replay()
//                .subscribe(onNext: { (cn) in
//                    guard let cn = cn else { return }
//                    Logger.UserProperty.start(with: .start(.country(cn))).log()
//                })
//                .disposed(by: bag)
//
//            Settings.shared.isMomentsPushOpen
//                .replay()
//                .subscribe(onNext: { (isOpen) in
//                    Logger.UserProperty.start(with: .start(.openRecommendationPush(isOpen))).log()
//                })
//                .disposed(by: bag)
//            
//            Settings.shared.isFollowingPushOpen
//                .replay()
//                .subscribe(onNext: { (isOpen) in
//                    Logger.UserProperty.start(with: .start(.openSubscriptionPush(isOpen))).log()
//                })
//                .disposed(by: bag)
//            
//            Settings.shared.isSystemPushOpen
//                .replay()
//                .subscribe(onNext: { (isOpen) in
//                    Logger.UserProperty.start(with: .start(.receiveEmail(isOpen))).log()
//                })
//                .disposed(by: bag)
//        }
//    }
}
