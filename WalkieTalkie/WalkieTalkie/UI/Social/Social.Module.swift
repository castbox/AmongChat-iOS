//
//  Social.Module.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/8/31.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

extension Social {
    
    class Module {
        
        static let shared = Module()
        
        private let bag = DisposeBag()
        
        private let followingListRelay = BehaviorRelay<[FireStore.Entity.User.FriendMeta]>(value: [])
        
        private let followerListRelay = BehaviorRelay<[FireStore.Entity.User.FriendMeta]>(value: [])
        
        private let blockedListRelay = BehaviorRelay<[String]>(value: [])
        
        private let muteListRelay = BehaviorRelay<[UInt]>(value: [])
        
        private typealias CommonMessge = FireStore.Entity.User.CommonMessage
        
        // 受邀人接受邀请，进入房间
        private let enterRoomMsgSubject = ReplaySubject<CommonMessge>.create(bufferSize: 1)
        // 他人申请进入房间
        private let joinChannelRequestedSubject = ReplaySubject<CommonMessge>.create(bufferSize: 1)
        // 申请进入他人房间被接受
        private let joinChannelAcceptedSubject = ReplaySubject<CommonMessge>.create(bufferSize: 1)
        // 申请进入他人房间被拒绝
        private let joinChannelRefusedSubject = ReplaySubject<CommonMessge>.create(bufferSize: 1)
        
        private var currentChannel: String = ""
        
        private init() {
            
            Observable.combineLatest(Settings.shared.loginResult.replay().filterNil(), FireStore.shared.firebaseSignedInObservable)
                .take(1)
                .subscribe(onNext: { [weak self] (t) in
                    let (result, _) = t
                    self?.startHeartbeat(result.uid)
                    self?.initializeProfileIfNeeded(result.uid)
                    self?.observeRelations(result.uid)
                    self?.observeCommonMsg(result.uid)
                    self?.bindProToProfile(result.uid)
                    self?.bindProfileToFirestore(result.uid)
                })
                .disposed(by: bag)
            
        }
        
        private func startHeartbeat(_ uid: String) {
            #if DEBUG
            let interval: Int = 10
            #else
            let interval: Int = 60
            #endif
            Observable<Int>.interval(.seconds(interval), scheduler: MainScheduler.instance)
                .subscribe(onNext: { (_) in
                    FireStore.shared.updateHeartbeat(of: uid)
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
                        let profile = FireStore.Entity.User.Profile(avatar: "\(FireStore.Entity.User.Profile.randomDefaultAvatar().1)",
                                                                    birthday: "",
                                                                    name: Constants.defaultUsername,
                            premium: Settings.shared.isProValue.value,
                            uidInt: Constants.sUserId,
                            uid: uid)
                        Settings.shared.firestoreUserProfile.value = profile
                    }
                    
                })
                .disposed(by: bag)
        }
        
        private func bindProToProfile(_ uid: String) {
            Settings.shared.isProValue.replay()
                .subscribe(onNext: { (isPro) in
                    let _ = Settings.shared.firestoreUserProfile.replay().filterNil()
                        .take(1)
                        .subscribe(onNext: { (p) in
                            var profile = p
                            profile.premium = isPro
                            Settings.shared.firestoreUserProfile.value = profile
                        })
                })
                .disposed(by: bag)
        }
        
        private func bindProfileToFirestore(_ uid: String) {
            Settings.shared.firestoreUserProfile.replay()
                .filterNil()
                .distinctUntilChanged()
                .subscribe(onNext: { (profile) in
                    FireStore.shared.updateProfile(profile, of: uid)
                })
                .disposed(by: bag)
        }
        
        private func observeRelations(_ uid: String) {
            
            FireStore.shared.followingObservable(of: uid)
                .bind(to: followingListRelay)
                .disposed(by: bag)
            
            FireStore.shared.followersObservable(of: uid)
                .bind(to: followerListRelay)
                .disposed(by: bag)
            
            FireStore.shared.userObservable(uid)
                .subscribe(onNext: { [weak self] (user) in
                    
                    guard let `self` = self else { return }
                    
                    self.blockedListRelay.accept(user.blockList)
                    self.muteListRelay.accept(user.muteList)
                    self.currentChannel = user.status.currentChannel
                })
                .disposed(by: bag)
            
        }
        
        private func observeCommonMsg(_ uid: String) {
            
            FireStore.shared.newCommonMsgObservable(of: uid)
                .subscribe(onNext: { [weak self] (msg) in
                    
                    switch msg.msgType {
                    case .channelEntryRequest:
                        self?.joinChannelRequestedSubject.onNext(msg)
                    case .channelEntryAccept:
                        self?.joinChannelAcceptedSubject.onNext(msg)
                    case .channelEntryRefuse:
                        self?.joinChannelRefusedSubject.onNext(msg)
                    case .enterRoom:
                        self?.enterRoomMsgSubject.onNext(msg)
                    }
                    
                })
                .disposed(by: bag)
            
            joinChannelRequestedSubject
                .subscribe(onNext: { (msg) in
                    guard let topVC = UIApplication.topViewController(UIApplication.navigationController) else { return }
                    let modal = Social.JoinChannelRequestModal(with: msg)
                    modal.showModal(in: topVC)
                    FireStore.shared.deleteCommonMsg(msg, from: uid)
                })
                .disposed(by: bag)
            
            joinChannelAcceptedSubject
                .subscribe(onNext: { (msg) in
                    
                    guard let channel = msg.channel,
                        let roomVC = UIApplication.navigationController?.viewControllers.first as? RoomViewController else {
                        return
                    }
                    // join channel directly
                    roomVC.joinChannel(channel)
                    
                    let _ = roomVC.joinedChannelObservable
                        .skipWhile({ $0 != channel })
                        .take(1)
                        .subscribe(onNext: { (channelName) in
                            guard let profile = Settings.shared.firestoreUserProfile.value else { return }
                            FireStore.shared.sendJoinedChannelMsg(to: msg.uid, from: profile)
                        })
                })
                .disposed(by: bag)
            
            joinChannelRefusedSubject
                .subscribe(onNext: { (msg) in
                    guard let topVC = UIApplication.topViewController() else { return }
                    let modal = Social.TopToastModal(with: msg)
                    topVC.present(modal, animated: false)
                })
                .disposed(by: bag)
            
            enterRoomMsgSubject
                .subscribe(onNext: { (msg) in
                    guard let topVC = UIApplication.topViewController() else { return }
                    let modal = Social.TopToastModal(with: msg)
                    topVC.present(modal, animated: false)
                })
                .disposed(by: bag)
            
        }
        
    }
}

extension Social.Module {
    
    var followingObservable: Observable<[FireStore.Entity.User.FriendMeta]> {
        return followingListRelay.asObservable()
    }
    
    var followingValue: [FireStore.Entity.User.FriendMeta] {
        return followingListRelay.value
    }
    
    var followerObservable: Observable<[FireStore.Entity.User.FriendMeta]> {
        return followerListRelay.asObservable()
    }
    
    var followerValue: [FireStore.Entity.User.FriendMeta] {
        return followerListRelay.value
    }
    
    var blockedValue: [String] {
        return blockedListRelay.value
    }
    
    var currentChannelValue: String {
        return currentChannel
    }
    
    var mutedValue: [UInt] {
        return muteListRelay.value
    }
    
    var mutedObservable: Observable<[UInt]> {
        return muteListRelay.asObservable()
    }
}
