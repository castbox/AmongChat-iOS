//
//  Social.Module.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/8/31.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation
import RxSwift

extension Social {
    
    class Module {
        
        static let shared = Module()
        
        private let bag = DisposeBag()
        
        private init() {
            
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
                                                                    name: Constants.defaultUsername,
                            premium: Settings.shared.isProValue.value,
                            uidInt: Constants.sUserId)
                        Settings.shared.firestoreUserProfile.value = profile
                    }
                    
                })
                .disposed(by: bag)
        }
        
        private func bindProToFirestore() {
            // 更新firestore profile都通过Settings.shared.firestoreUserProfile流
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
}
