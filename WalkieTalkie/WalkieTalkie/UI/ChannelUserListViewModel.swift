//
//  ChannelUserListViewModel.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/8/4.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import SwiftyUserDefaults

class ChannelUserListViewModel {
    static let shared = ChannelUserListViewModel()
    
    private var dataSourceReplay = BehaviorRelay<[ChannelUserViewModel]>(value: [])
    
    var userObservable: Observable<[ChannelUserViewModel]> {
        return dataSourceReplay.asObservable()
    }
    
    var channelUserViewModelList: [ChannelUserViewModel] {
        return dataSourceReplay.value
    }
    
    private var cachedFUsers = [UInt : FireStore.Entity.User]()
    private var unfoundUserIds = Set<UInt>()
    
    private let dataSource = BehaviorRelay<[ChannelUser]>(value: [])
    
    private let speakingUsersRelay = BehaviorRelay<[ChannelUserViewModel]>(value: [])
    
    var speakingUserObservable: Observable<[ChannelUserViewModel]> {
        return speakingUsersRelay.asObservable()
    }
    
    var blockedUsers = [ChannelUser]()
    
    private var mutedUser = Set<UInt>() {
        didSet {
            update(dataSource.value)
        }
    }
    
    var mutedUserValue: Set<UInt> {
        return mutedUser
    }
    
    init() {
        blockedUsers = Defaults[\.blockedUsersKey]
        
        let _ = Social.Module.shared.mutedObservable
            .map({ Set($0) })
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] (users) in
                self?.mutedUser = users
            })
        
        let _ = dataSource
            .throttle(.seconds(5), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (channelUsers) in
                
                guard let `self` = self else { return }
                
                let uids: [UInt] = channelUsers.map { $0.uid }
                                
                let _ = self.fetchFirestoreUser(uids: uids)
                    .subscribe(onSuccess: { (users) in
                        
                        let viewModelList = channelUsers.map { (channelUser) -> ChannelUserViewModel in
                            let firestoreUser = users.first(where: { $0.profile.uidInt == channelUser.uid })
                            return ChannelUserViewModel.init(with: channelUser, firestoreUser: firestoreUser)
                        }
                        self.dataSourceReplay.accept(viewModelList)
                        self.speakingUsersRelay.accept(viewModelList.filter { $0.channelUser.status == .talking })
                    })
            })

    }
    
    func update(_ userList: [ChannelUser]) {
        let blockedUsers = self.blockedUsers
        var copyOfUserList = userList
        if let selfUser = copyOfUserList.removeFirst(where: { $0.uid == Constants.sUserId }) {
            copyOfUserList.insert(selfUser, at: 0)
        }
        let users = copyOfUserList.map { item -> ChannelUser in
            var user = item
            if blockedUsers.contains(where: { $0.uid == item.uid }) {
                user.isMuted = true
                user.status = .blocked
            } else if mutedUser.contains(item.uid) {
                user.isMuted = true
                user.status = .muted
            } else {
                user.isMuted = false
                user.status = .connected
            }
            return user
        }
        dataSource.accept(users)
    }
    
    func updateVolumeIndication(userId: UInt, volume: UInt) {
        cdPrint("userid: \(userId) volume: \(volume)")
        let users = dataSource.value.map { item -> ChannelUser in
            guard item.status != .blocked,
                item.status != .muted,
                item.status != .droped,
                item.uid == userId,
                volume > 0 else {
                return item
            }
            var user = item
            user.status = .talking
            cdPrint("user: \(user)")
            return user
        }
        dataSource.accept(users)
    }
    
    func blockedUser(_ user: ChannelUserViewModel) {
        blockedUsers.append(user.channelUser)
        Defaults[\.blockedUsersKey] = blockedUsers
        update(dataSource.value)
        if let firestoreUser = user.firestoreUser,
            let selfUid = Settings.shared.loginResult.value?.uid {
            FireStore.shared.addBlockUser(firestoreUser.uid, to: selfUid)
        }
    }
    
    func unblockedUser(_ user: ChannelUserViewModel) {
        blockedUsers.removeElement(ifExists: { $0.uid == user.channelUser.uid })
        Defaults[\.blockedUsersKey] = blockedUsers
        update(dataSource.value)
        if let firestoreUser = user.firestoreUser,
            let selfUid = Settings.shared.loginResult.value?.uid {
            FireStore.shared.removeBlockUser(firestoreUser.uid, from: selfUid)
        }
    }
    
    func muteUser(_ user: ChannelUserViewModel) {
        mutedUser.insert(user.channelUser.uid)
        update(dataSource.value)
        guard let selfUid = Settings.shared.loginResult.value?.uid else { return }
        FireStore.shared.addMuteUser(user.channelUser.uid, to: selfUid)
    }
    
    func unmuteUser(_ user: ChannelUserViewModel) {
        mutedUser.remove(user.channelUser.uid)
        update(dataSource.value)
        guard let selfUid = Settings.shared.loginResult.value?.uid else { return }
        FireStore.shared.removeMuteUser(user.channelUser.uid, from: selfUid)
    }
    
    func followUser(_ user: FireStore.Entity.User) {
        Social.Module.shared.follow(user.uid)
    }
    
    func unfollowUser(_ user: FireStore.Entity.User) {
        guard let selfUid = Settings.shared.loginResult.value?.uid else { return }
        FireStore.shared.removeFollowing(user.uid, from: selfUid)
    }
    
    func didJoinedChannel(_ channel: String) {
        let _ = Request.reportEnterRoom(channel)
            .subscribe(onSuccess: { (_) in
            })
    }
    
    func leavChannel(_ channel: String) {
        let _ = Request.reportLeaveRoom(channel)
            .subscribe()
        cachedFUsers.removeAll()
        unfoundUserIds.removeAll()
        dataSource.accept([])
    }

}

extension ChannelUserListViewModel {
    
    private func fetchFirestoreUser(uids: [UInt]) -> Single<[FireStore.Entity.User]> {
        
        let hitUsers = uids.compactMap {
            cachedFUsers[$0]
        }
        
        let missedUids = uids.filter { (uid) in
            !hitUsers.contains { $0.profile.uidInt == uid }
        }
        .filter { (uid) in
            !unfoundUserIds.contains(uid)
        }
        
        guard missedUids.isEmpty else {
            
            return Observable.create { [weak self] (subscriber) -> Disposable in
                
                guard let `self` = self else {
                    return Disposables.create {}
                }
                
                let _ = FireStore.shared.fetchUsers(missedUids)
                    .do(onSuccess: { (users) in
                        self.cachedFUsers.merge(users.map({ ($0.profile.uidInt, $0) })) { (_, new) in
                            new
                        }
                        
                        let unfoundIds = missedUids.filter { (uid) in
                            !users.contains { $0.profile.uidInt == uid }
                        }
                        
                        guard !unfoundIds.isEmpty else { return }
                        
                        self.unfoundUserIds.formUnion(Set(unfoundIds))
                        
                    })
                    .subscribe(onSuccess: { (users) in
                        
                        var allUsers = hitUsers
                        allUsers.append(contentsOf: users)
                        
                        allUsers.sort { (l, r) -> Bool in
                            guard let lIdx = uids.firstIndex(of: l.profile.uidInt),
                                  let rIdx = uids.firstIndex(of: r.profile.uidInt) else {
                                return true
                            }
                            
                            return lIdx < rIdx
                        }
                        
                        subscriber.onNext(allUsers)
                        subscriber.onCompleted()
                        
                    }) { (error) in
                        subscriber.onError(error)
                    }
                
                return Disposables.create {}
            }
            .asSingle()
            
        }
        
        return Observable.just(hitUsers).asSingle()
    }
    
}
