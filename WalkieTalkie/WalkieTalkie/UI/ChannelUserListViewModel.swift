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
    
    var dataSourceReplay = BehaviorRelay<[ChannelUserViewModel]>(value: [])
    
    private var dataSource = [ChannelUser]() {
        didSet {
//            dataSourceReplay.accept(dataSource.map { ChannelUserViewModel.init(with: $0) })
            
            let uids: [UInt] = dataSource.map { $0.uid }
            let _ = FireStore.shared.fetchUsers(uids)
                .subscribe(onSuccess: { (users) in
                    
                    let viewModelList = self.dataSource.map { (channelUser) -> ChannelUserViewModel in
                        let firestoreUser = users.first(where: { $0.profile.uidInt == channelUser.uid })
                        return ChannelUserViewModel.init(with: channelUser, firestoreUser: firestoreUser)
                    }
                    self.dataSourceReplay.accept(viewModelList)
                    self.speakingUsersRelay.accept(viewModelList.filter { $0.channelUser.status == .talking })
                })
        }
    }
    
    private let speakingUsersRelay = BehaviorRelay<[ChannelUserViewModel]>(value: [])
    
    var blockedUsers = [ChannelUser]()
    
    private var mutedUser = Set<UInt>() {
        didSet {
            update(dataSource)
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
    }
    
    func update(_ userList: [ChannelUser]) {
        let blockedUsers = self.blockedUsers
        dataSource = userList.map { item -> ChannelUser in
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
    }
    
    func updateVolumeIndication(userId: UInt, volume: UInt) {
        cdPrint("userid: \(userId) volume: \(volume)")
        dataSource = dataSource.map { item -> ChannelUser in
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
    }
    
    func blockedUser(_ user: ChannelUserViewModel) {
        blockedUsers.append(user.channelUser)
        Defaults[\.blockedUsersKey] = blockedUsers
        update(dataSource)
        if let firestoreUser = user.firestoreUser,
            let selfUid = Settings.shared.loginResult.value?.uid {
            FireStore.shared.addBlockUser(firestoreUser.uid, to: selfUid)
        }
    }
    
    func unblockedUser(_ user: ChannelUserViewModel) {
        blockedUsers.removeElement(ifExists: { $0.uid == user.channelUser.uid })
        Defaults[\.blockedUsersKey] = blockedUsers
        update(dataSource)
        if let firestoreUser = user.firestoreUser,
            let selfUid = Settings.shared.loginResult.value?.uid {
            FireStore.shared.removeBlockUser(firestoreUser.uid, from: selfUid)
        }
    }
    
    func muteUser(_ user: FireStore.Entity.User) {
        mutedUser.insert(user.profile.uidInt)
        update(dataSource)
        guard let selfUid = Settings.shared.loginResult.value?.uid else { return }
        FireStore.shared.addMuteUser(user.profile.uidInt, to: selfUid)
    }
    
    func unmuteUser(_ user: FireStore.Entity.User) {
        mutedUser.remove(user.profile.uidInt)
        update(dataSource)
        guard let selfUid = Settings.shared.loginResult.value?.uid else { return }
        FireStore.shared.removeMuteUser(user.profile.uidInt, from: selfUid)
    }
    
    func followUser(_ user: FireStore.Entity.User) {
        guard let selfUid = Settings.shared.loginResult.value?.uid else { return }
        FireStore.shared.addFollowing(user.uid, to: selfUid)
    }
    
    func unfollowUser(_ user: FireStore.Entity.User) {
        guard let selfUid = Settings.shared.loginResult.value?.uid else { return }
        FireStore.shared.removeFollowing(user.uid, from: selfUid)
    }

}
