//
//  AmongChat.Room.ViewModel.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 17/12/20.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import SwifterSwift
import SwiftyUserDefaults

extension AmongChat.Room {
    
    enum EndRoomAction {
        case accountKicked
        case disconnected
        case normalClose //true if enter a closed room for listener
        case tokenError
        case forbidden //被封
        //listener
        case enterClosedRoom
        case kickout //被踢出
        case beBlocked
    }
    
    class ViewModel {
        
        var messages: [ChatRoomMessage] = []
        let roomReplay: BehaviorRelay<Entity.Room>
        
        var endRoomHandler: ((_ action: EndRoomAction) -> Void)?

        private let imViewModel: IMViewModel
        private let bag = DisposeBag()
        
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
        
        private var room: Entity.Room {
            roomReplay.value
        }
        
        init(room: Entity.Room) {
//            self.room = room
            roomReplay = BehaviorRelay(value: room)
            imViewModel = IMViewModel(with: room.roomId)
            
            imViewModel.messagesObservable
                .subscribe(onNext: { [weak self] (msg) in
                    //处理消息
//                    self?.messageListDataSource = msgs
//                    self?.messages = msgs
                    self?.onReceiveChatRoom(crMessage: msg)
                })
                .disposed(by: bag)
            
//            imViewModel.imReadySignal
//                .filter({ $0 })
//                .take(1)
//                .subscribe(onNext: { [weak self] (_) in
//                    self?.messageListTableView.isHidden = false
    //                self?.messageBtn.isHidden = false
//                })
//                .disposed(by: bag)

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
                    
                    let uids: [UInt] = channelUsers.map { $0.uid.int!.uInt }
                    
                    let hitUsers = uids.compactMap {
                        self.cachedFUsers[$0]
                    }
                    
//                    let _ = Observable.of(self.fetchFirestoreUser(uids: uids), Observable.just(hitUsers).asSingle()).merge()
//                        .take(2)
//                        .subscribe(onNext: { (users) in
//
//                            let viewModelList = channelUsers.map { (channelUser) -> ChannelUserViewModel in
//                                let firestoreUser = users.first(where: { $0.profile.uid == channelUser.uid })
//                                return ChannelUserViewModel.init(with: channelUser, firestoreUser: firestoreUser)
//                            }
//                            self.dataSourceReplay.accept(viewModelList)
//                            self.speakingUsersRelay.accept(viewModelList.filter { $0.channelUser.status == .talking })
//                        })
                })

        }
        
        func sendText(message: String?) {
            guard let message = message?.trimmed,
                  !message.isEmpty,
                  let user = room.roomUserList.first(where: { $0.uid == Settings.loginUserId?.int }) else {
                return
            }
            let textMessage = ChatRoom.TextMessage(text: message, user: user, msgType: .text)
            imViewModel.sendText(message: textMessage)
        }
        
        func changePublicType() {
            let publicType: Entity.RoomPublicType = room.state == .private ? .public : .private
            var room = self.room
            room.state = publicType
            roomReplay.accept(room)
            //update
            updateRoomInfo(room)
        }
        
        func update(nickName: String) {
            var room = self.room
//            room.amongUsCode = code
            
            updateRoomInfo(room)
        }
        
        func update(notes: String) {
            var room = self.room
            room.note = notes
            roomReplay.accept(room)
//            room.isValidAmongConfig = publicType
            //update
            updateRoomInfo(room)
        }
        
        func updateAmong(code: String, aera: Entity.AmongUsZone) {
            var room = self.room
            room.amongUsCode = code
            room.amongUsZone = aera
            roomReplay.accept(room)
        }
        
        func updateRoomInfo(_ room: Entity.Room) {
            //update
            Request.updateRoomInfo(room: room)
                .filter { $0 }
                .map { _ -> Entity.Room in
                    return room
                }
                .catchErrorJustReturn(self.room)
                .asObservable()
                .bind(to: roomReplay)
                .disposed(by: bag)
        }
        
        func update(_ userList: [ChannelUser]) {
            let blockedUsers = self.blockedUsers
            var copyOfUserList = userList
            if let selfUser = copyOfUserList.removeFirst(where: { $0.uid.int! == Constants.sUserId }) {
                copyOfUserList.insert(selfUser, at: 0)
            }
            let users = copyOfUserList.map { item -> ChannelUser in
                var user = item
                if blockedUsers.contains(where: { $0.uid == item.uid }) {
                    user.isMuted = true
                    user.status = .blocked
                } else if mutedUser.contains(item.uid.int!.uInt) {
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
                    item.uid.int!.uInt == userId,
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
    //            FireStore.shared.addBlockUser(firestoreUser.uid, to: selfUid)
            }
        }
        
        func unblockedUser(_ user: ChannelUserViewModel) {
            blockedUsers.removeElement(ifExists: { $0.uid == user.channelUser.uid })
            Defaults[\.blockedUsersKey] = blockedUsers
            update(dataSource.value)
            if let firestoreUser = user.firestoreUser,
                let selfUid = Settings.shared.loginResult.value?.uid {
    //            FireStore.shared.removeBlockUser(firestoreUser.uid, from: selfUid)
            }
        }
        
        func muteUser(_ user: ChannelUserViewModel) {
            mutedUser.insert(user.channelUser.uid.int!.uInt)
            update(dataSource.value)
            guard let selfUid = Settings.shared.loginResult.value?.uid else { return }
    //        FireStore.shared.addMuteUser(user.channelUser.uid, to: selfUid)
        }
        
        func unmuteUser(_ user: ChannelUserViewModel) {
            mutedUser.remove(user.channelUser.uid.int!.uInt)
            update(dataSource.value)
            guard let selfUid = Settings.shared.loginResult.value?.uid else { return }
    //        FireStore.shared.removeMuteUser(user.channelUser.uid, from: selfUid)
        }
        
        func followUser(_ user: FireStore.Entity.User) {
            Social.Module.shared.follow(user.uid)
        }
        
        func unfollowUser(_ user: FireStore.Entity.User) {
            guard let selfUid = Settings.shared.loginResult.value?.uid else { return }
    //        FireStore.shared.removeFollowing(user.uid, from: selfUid)
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

}

extension AmongChat.Room.ViewModel {
    func onReceiveChatRoom(crMessage: ChatRoomMessage) {
        if let message = crMessage as? ChatRoom.TextMessage {
            
        } else if let message = crMessage as? ChatRoom.KickOutMessage {
            //自己
//            if message. {
//                <#code#>
//            }
            endRoomHandler?(.kickout)
        } else if let message = crMessage as? ChatRoom.LeaveRoomMessage {
            //
        }
    }
    
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

//extension AmongChat.Room.ViewModel: ChatRoomDelegate {
//    // MARK: - ChatRoomDelegate
//    
//    func onJoinChannelFailed(channelId: String?) {
//        self.hudRemoval?()
//        self.hudRemoval = nil
//        
//        view.raft.autoShow(.text(R.string.localizable.amongChatRoomTipTimeout()))
//        
//        Observable.just(())
//            .delay(.fromSeconds(0.6), scheduler: MainScheduler.asyncInstance)
//            .filter { [weak self] _  -> Bool in
//                guard let `self` = self else { return false }
//                return self.mManager.state != .connected
//            }
//            .subscribe(onNext: { _ in
//            })
//            .disposed(by: bag)
//    }
//    
//    func onJoinChannelTimeout(channelId: String?) {
//        self.hudRemoval?()
//        self.hudRemoval = nil
//        
//        view.raft.autoShow(.text(R.string.localizable.amongChatRoomTipTimeout()))
//        
//        Observable.just(())
//            .observeOn(MainScheduler.asyncInstance)
//            .filter { [weak self] _  -> Bool in
//                guard let `self` = self else { return false }
//                return self.mManager.state != .connected
//            }
//            .do(onNext: { [weak self] _ in
//                self?.leaveChannel()
//            })
//            .delay(.fromSeconds(0.6), scheduler: MainScheduler.asyncInstance)
//            .filter { [weak self] _  -> Bool in
//                guard let `self` = self else { return false }
//                return self.mManager.state != .connected
//            }
//            .subscribe(onNext: { _ in
//            })
//            .disposed(by: bag)
//    }
//
//    func onConnectionChangedTo(state: ConnectState, reason: AgoraConnectionChangedReason) {
//    }
//    
//    func onSeatUpdated(position: Int) {
//    }
//
//    func onUserGivingGift(userId: String) {
//    }
//
//    func onMessageAdded(position: Int) {
//    }
//
//    func onMemberListUpdated(userId: String?) {
//    }
//
//    func onUserStatusChanged(userId: UInt, muted: Bool) {
//        if Constants.isMyself(userId) {
//            
//        } else {
//            //check block
//            if let user = ChannelUserListViewModel.shared.blockedUsers.first(where: { $0.uid.uIntValue == userId }) {
//                mManager.adjustUserPlaybackSignalVolume(user, volume: 0)
//            } else if ChannelUserListViewModel.shared.mutedUserValue.contains(userId) {
//                mManager.adjustUserPlaybackSignalVolume(ChannelUser.randomUser(uid: userId), volume: 0)
//            }
//        }
//    }
//    
//    func onAudioMixingStateChanged(isPlaying: Bool) {
//
//    }
//
//    func onAudioVolumeIndication(userId: UInt, volume: UInt) {
//        ChannelUserListViewModel.shared.updateVolumeIndication(userId: userId, volume: volume)
//    }
//    
//    func onChannelUserChanged(users: [ChannelUser]) {
//        ChannelUserListViewModel.shared.update(users)
//    }
//}
