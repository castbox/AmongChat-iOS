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
import AgoraRtcKit
import CastboxDebuger

fileprivate func cdPrint(_ message: Any) {
    Debug.info("[AmongChat.Room.ViewModel]-\(message)")
}

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
        
        static var shared: ViewModel?
        
        var messages: [ChatRoomMessage] = []
        let roomReplay: BehaviorRelay<Entity.Room>
        //麦位声音动画
        let soundAnimationIndex = BehaviorRelay<Int?>(value: nil)
        
        private var messageEventEmitter = PublishSubject<ChatRoomMessage>()
        private var messageListReloadTrigger = PublishSubject<()>()
        var endRoomHandler: ((_ action: EndRoomAction) -> Void)?
        var messageEventHandler: () -> Void = { }
        
        private let imViewModel: IMViewModel
        private let bag = DisposeBag()
        
        private var dataSourceReplay = BehaviorRelay<[ChannelUserViewModel]>(value: [])
        
        private lazy var mManager: ChatRoomManager = {
            let manager = ChatRoomManager.shared
            manager.delegate = self
            return manager
        }()
        
        var userObservable: Observable<[ChannelUserViewModel]> {
            return dataSourceReplay.asObservable()
        }
        
        var channelUserViewModelList: [ChannelUserViewModel] {
            return dataSourceReplay.value
        }
        
        private var cachedFUsers = [UInt : FireStore.Entity.User]()
        private var unfoundUserIds = Set<UInt>()
        
        private let dataSource = BehaviorRelay<[ChannelUser]>(value: [])
        
//        private let speakingUsersRelay = BehaviorRelay<[ChannelUserViewModel]>(value: [])
        
//        var speakingUserObservable: Observable<[ChannelUserViewModel]> {
//            return speakingUsersRelay.asObservable()
//        }
        
        var blockedUsers = [Entity.RoomUser]() {
            didSet {
                update(room)
            }
        }
        
        //登录用户主动 muted
        private(set) var mutedUser = Set<UInt>() {
            didSet {
//                update(dataSource.value)
                update(room)
            }
        }
        //其他用户自己 muted
        private(set) var otherMutedUser = Set<UInt>() {
            didSet {
                update(room)
//                                update(dataSource.value)
            }
        }
        
//        var mutedUserValue: Set<UInt> {
//            return mutedUser
//        }
        
        private var room: Entity.Room {
            roomReplay.value
        }
        
        
        let isMuteMicObservable = BehaviorRelay<Bool>(value: false)
        var isMuteMic: Bool {
            set {
                isMuteMicObservable.accept(newValue)
                //                LiveEngine.shared.mute(isMute: newValue)
                ChatRoomManager.shared.muteMyMic(muted: newValue)
                ////find
                guard let userId = Settings.loginUserId?.uInt else {
                    return
                }
                onUserStatusChanged(userId: userId, muted: newValue)
            }
            get { isMuteMicObservable.value }
        }
        
        static func make(_ room: Entity.Room) -> ViewModel {
            guard let shared = self.shared,
                  shared.room.roomId == room.roomId else {
                let manager = ViewModel(room: room)
                //退出之前房间
                //                self.shared?.quitRoom()
                //设置新房间
                self.shared = manager
                return manager
            }
            //            shared.createType = .restore
            //            shared.stateType = .default
            return shared
            
        }
        
        deinit {
            debugPrint("[DEINIT-\(NSStringFromClass(type(of: self)))]")
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
            
            imViewModel.imReadySignal
                .filter { $0 }
                .subscribe { [weak self] _ in
                    self?.startUpdateBaseInfo()
                }
                .disposed(by: bag)

            
            //            imViewModel.imReadySignal
            //                .filter({ $0 })
            //                .take(1)
            //                .subscribe(onNext: { [weak self] (_) in
            //                    self?.messageListTableView.isHidden = false
            //                self?.messageBtn.isHidden = false
            //                })
            //                .disposed(by: bag)
            
            blockedUsers = Defaults[\.blockedUsersV2Key]
            
            //            let _ = Social.Module.shared.mutedObservable
            //                .map({ Set($0) })
            //                .distinctUntilChanged()
            //                .subscribe(onNext: { [weak self] (users) in
            //                    self?.mutedUser = users
            //                })
            
            //            let _ = dataSource
            //                .throttle(.seconds(5), scheduler: MainScheduler.instance)
            //                .subscribe(onNext: { [weak self] (channelUsers) in
            //
            //                    guard let `self` = self else { return }
            //
            //                    let uids: [UInt] = channelUsers.map { $0.uid.int!.uInt }
            //
            //                    let hitUsers = uids.compactMap {
            //                        self.cachedFUsers[$0]
            //                    }
            //
            ////                    let _ = Observable.of(self.fetchFirestoreUser(uids: uids), Observable.just(hitUsers).asSingle()).merge()
            ////                        .take(2)
            ////                        .subscribe(onNext: { (users) in
            ////
            ////                            let viewModelList = channelUsers.map { (channelUser) -> ChannelUserViewModel in
            ////                                let firestoreUser = users.first(where: { $0.profile.uid == channelUser.uid })
            ////                                return ChannelUserViewModel.init(with: channelUser, firestoreUser: firestoreUser)
            ////                            }
            ////                            self.dataSourceReplay.accept(viewModelList)
            ////                            self.speakingUsersRelay.accept(viewModelList.filter { $0.channelUser.status == .talking })
            ////                        })
            //                })
            
            setObservableSubject()
            addSystemMessage()
        }
        
        @discardableResult
        func join(completionBlock: ((Error?) -> Void)? = nil) -> Bool {
            
            let name = room.topicName
            //            var channel = room
            
            //        guard !name.isEmpty else {
            //            return false
            //        }
            //
            //        if mManager.isConnectedState && mManager.channelName == name {
            //           return false
            //        }
            
            //        guard !channel.isReachMaxUser else {
            //            //离开当前房间
            //            leaveChannel()
            //            return false
            //        }
            //        SpeechRecognizer.default.requestAuthorize { [weak self] _ in
            //            guard let `self` = self else { return }
            guard let topController = UIApplication.shared.keyWindow?.topViewController() else {
                return false
            }
            topController.checkMicroPermission { [weak self] in
                guard let `self` = self else { return }
                self.mManager.joinChannel(channelId: self.room.roomId) { error in
                    //                    self.hudRemoval?()
                    //                    self.hudRemoval = nil
                    //                    channel.updateJoinInterval()
                    HapticFeedback.Impact.success()
                    UIApplication.shared.isIdleTimerDisabled = true
                    ChannelUserListViewModel.shared.didJoinedChannel(name)
                    completionBlock?(error)
                }
            }
            return true
        }
        
        func leaveChannel() -> Observable<()> {
            return Request.amongchatProvider.rx.request(.leaveRoom(["room_id": room.roomId]))
                .asObservable()
                .flatMap { [weak self] _  -> Observable<()> in
                    guard let `self` = self else { return .empty() }
                    return Observable<()>.create { [weak self] observer -> Disposable in
                        self?.mManager.leaveChannel { (name) in
                            UIApplication.shared.isIdleTimerDisabled = false
                            ChannelUserListViewModel.shared.leavChannel(name)
                            ViewModel.shared = nil
                            observer.onNext(())
                            observer.onCompleted()
                        }
                        return Disposables.create {
                            
                        }
                    }
                }
        }
        
        func startUpdateBaseInfo() {
            Observable<Int>.interval(.seconds(180), scheduler: SerialDispatchQueueScheduler(qos: .default))
                .startWith(0)
                .subscribe(onNext: { [weak self] _ in
                    self?.requestRoomInfo()
                })
                .disposed(by: bag)

        }
        
        func setObservableSubject() {
            
            messageEventEmitter.asObserver()
                .observeOn(SerialDispatchQueueScheduler(qos: .default))
                //                .map { message -> ChatRoomMessage in
                //                    //transfer
                //                    let content = message.content
                //                    if let text = content as? TextContent {
                //                        //过滤
                //                        let (_, result) = SensitiveWordChecker.default.filter(text: text.content)
                //                        text.content = result
                //                        return LVEntity.Message(content: text, sendTime: message.sendTime, receivedTime: message.receivedTime)
                //                    } else if let whisper = content as? WhisperContent {
                //                        let (_, result) = SensitiveWordChecker.default.filter(text: whisper.whisper_msg)
                //                        whisper.whisper_msg = result
                //                        return LVEntity.Message(content: whisper, sendTime: message.sendTime, receivedTime: message.receivedTime)
                //                    } else {
                //                        return message
                //                    }
                //                }
                .observeOn(MainScheduler.asyncInstance)
                .do(onNext: { [weak self] message in
                    self?.messages.append(message)
                })
                .map { _ -> Void in
                    return ()
                }
                .bind(to: messageListReloadTrigger)
                .disposed(by: bag)
            
            messageListReloadTrigger
                .asObserver()
                .debounce(.fromSeconds(0.8), scheduler: MainScheduler.asyncInstance)
                .subscribe(onNext: { [weak self] _ in
                    self?.messageEventHandler()
                })
                .disposed(by: bag)
        }
        
        func addSystemMessage() {
            let system = ChatRoom.SystemMessage(content: "Welcome to \(room.topicName) channel. Any pornography, political, religions, gambling and other inappropriate content is strictly prohibited. Channels are monitored 24/7 and users found with such content may be banned.", msgType: .system)
            addUIMessage(message: system)
        }
        
        // 添加消息
        func addUIMessage(message: ChatRoomMessage) {
            messageEventEmitter.onNext(message)
        }
        
        func triggerMessageListReload() {
            messageListReloadTrigger.onNext(())
        }
        
        func sendText(message: String?) {
            guard let message = message?.trimmed,
                  !message.isEmpty,
                  let user = room.roomUserList.first(where: { $0.uid == Settings.loginUserId }) else {
                return
            }
            let textMessage = ChatRoom.TextMessage(content: message, user: user, msgType: .text)
            imViewModel.sendText(message: textMessage)
            //append
            addUIMessage(message: textMessage)
        }
        
        func changePublicType() {
            let publicType: Entity.RoomPublicType = room.state == .private ? .public : .private
            var room = self.room
            room.state = publicType
//            roomReplay.accept(room)
            //update
            updateRoomInfo(room)
        }
        
        func update(nickName: String) {
//            var room = self.room
//            updateRoomInfo(room)
            Request.updateProfile(["nickname": nickName])
                .subscribe { profile in
                    
                } onError: { _ in
                    
                }
                .disposed(by: bag)
        }
        
        func update(notes: String) {
            var room = self.room
            room.note = notes
            updateRoomInfo(room)
        }
        
        func updateAmong(code: String, aera: Entity.AmongUsZone) {
            var room = self.room
            room.amongUsCode = code
            room.amongUsZone = aera
            updateRoomInfo(room)
        }
        
        //MARK: -- Request
        func requestRoomInfo() {
            Request.amongchatProvider.rx.request(.roomInfo(["room_id": room.roomId]))
                .mapJSON()
                .mapToDataKeyJsonValue()
                .map { item -> [String : AnyObject] in
                    guard let roomData = item["room"] as? [String : AnyObject] else {
                        return [:]
                    }
                    return roomData
                }
                .mapTo(Entity.Room.self)
                .catchErrorJustReturn(self.room)
                .asObservable()
                .filterNilAndEmpty()
                .bind(to: roomReplay)
                .disposed(by: bag)
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
        
        func requestKick(_ users: [Int]) -> Single<Bool> {
            let params: [String: Any] = [
                "room_id": room.roomId, "uids": users.map { $0.string }.joined(separator: ",")
            ]
            return Request.amongchatProvider.rx.request(.kickUsers(params))
                .mapJSON()
                .map { $0 != nil }
//                .catchErrorJustReturn(self.room)
//                .asObservable()
//                .bind(to: roomReplay)
//                .disposed(by: bag)
        }
        
//        func update(_ userList: [Entity.RoomUser]) {
//            let blockedUsers = self.blockedUsers
//            var copyOfUserList = userList
//            if let selfUser = copyOfUserList.removeFirst(where: { $0.uid.int! == Constants.sUserId }) {
//                copyOfUserList.insert(selfUser, at: 0)
//            }
//            let users = copyOfUserList.map { item -> ChannelUser in
//                var user = item
//                if blockedUsers.contains(where: { $0.uid == item.uid }) {
//                    user.isMuted = true
//                    user.status = .blocked
//                } else if mutedUser.contains(item.uid.int!.uInt) {
//                    user.isMuted = true
//                    user.status = .muted
//                } else {
//                    user.isMuted = false
//                    user.status = .connected
//                }
//                return user
//            }
//            dataSource.accept(users)
//        }
        
        func updateVolumeIndication(userId: UInt, volume: UInt) {
            //            cdPrint("userid: \(userId) volume: \(volume)")
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
        
        func blockedUser(_ user: Entity.RoomUser) {
            blockedUsers.append(user)
            Defaults[\.blockedUsersV2Key] = blockedUsers
            mManager.adjustUserPlaybackSignalVolume(user.uid, volume: 0)
//            update(dataSource.value)
//            if let firestoreUser = user.firestoreUser,
//               let selfUid = Settings.shared.loginResult.value?.uid {
                //            FireStore.shared.addBlockUser(firestoreUser.uid, to: selfUid)
//            }
        }
        
        func unblockedUser(_ user: Entity.RoomUser) {
            blockedUsers.removeElement(ifExists: { $0.uid == user.uid })
            Defaults[\.blockedUsersV2Key] = blockedUsers
            mManager.adjustUserPlaybackSignalVolume(user.uid, volume: 100)
//            update(dataSource.value)
//            if let firestoreUser = user.firestoreUser,
//               let selfUid = Settings.shared.loginResult.value?.uid {
                //            FireStore.shared.removeBlockUser(firestoreUser.uid, from: selfUid)
//            }
        }
        
        func muteUser(_ user: Entity.RoomUser) {
            mutedUser.insert(user.uid.uInt)
            mManager.adjustUserPlaybackSignalVolume(user.uid, volume: 0)
//            update(dataSource.value)
//            guard let selfUid = Settings.shared.loginResult.value?.uid else { return }
            //        FireStore.shared.addMuteUser(user.channelUser.uid, to: selfUid)
        }
        
        func unmuteUser(_ user: Entity.RoomUser) {
            mutedUser.remove(user.uid.uInt)
            mManager.adjustUserPlaybackSignalVolume(user.uid, volume: 100)
//            update(dataSource.value)
//            guard let selfUid = Settings.shared.loginResult.value?.uid else { return }
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
        
        //        func leavChannel(_ channel: String) {
        //            let _ = Request.reportLeaveRoom(channel)
        //                .subscribe()
        //            cachedFUsers.removeAll()
        //            unfoundUserIds.removeAll()
        //            dataSource.accept([])
        //            ViewModel.shared = nil
        //        }
        
    }
    
}

extension AmongChat.Room.ViewModel {
    func update(_ room: Entity.Room) {
        var newRoom = room
        let userList = newRoom.roomUserList
        
        let blockedUsers = self.blockedUsers
//        var copyOfUserList = userList
//        if let selfUser = copyOfUserList.removeFirst(where: { $0.uid.int! == Constants.sUserId }) {
//            copyOfUserList.insert(selfUser, at: 0)
//        }
//        let users = copyOfUserList.map { item -> ChannelUser in
//            var user = item
//            if blockedUsers.contains(where: { $0.uid == item.uid }) {
//                user.isMuted = true
//                user.status = .blocked
//            } else if mutedUser.contains(item.uid.int!.uInt) {
//                user.isMuted = true
//                user.status = .muted
//            } else {
//                user.isMuted = false
//                user.status = .connected
//            }
//            return user
//        }
        newRoom.roomUserList = userList.map { user -> Entity.RoomUser in
            var newUser = user
            if blockedUsers.contains(where: { $0.uid == user.uid }) {
                newUser.status = .blocked
                newUser.isMuted = true
            } else {
                if otherMutedUser.contains(user.uid.uInt) || mutedUser.contains(user.uid.uInt) {
                    newUser.isMuted = true
                    newUser.status = .muted
                    newUser.isMutedByLoginUser = mutedUser.contains(user.uid.uInt)
                } else {
                    newUser.isMuted = false
                    newUser.status = .connected
                }

            }
//            newUser.isMuted = otherMutedUser.contains(user.uid)
//            newUser.isMutedByLoginUser = mutedUser.contains(user.uid)
            return newUser
        }
        roomReplay.accept(newRoom)
    }
    
    func onReceiveChatRoom(crMessage: ChatRoomMessage) {
        cdPrint("onReceiveChatRoom- \(crMessage)")
        if let message = crMessage as? ChatRoom.TextMessage {
            addUIMessage(message: message)
        } else if let message = crMessage as? ChatRoom.SystemMessage {
            addUIMessage(message: message)
        } else if let message = crMessage as? ChatRoom.RoomInfoMessage {
            update(message.room)
        } else if let message = crMessage as? ChatRoom.KickOutMessage,
                  message.user.uid == Settings.loginUserId {
            //自己
            endRoomHandler?(.kickout)
        } else if let message = crMessage as? ChatRoom.LeaveRoomMessage {
            otherMutedUser.remove(message.user.uid.uInt)
        }
    }
    
    //    private func fetchFirestoreUser(uids: [UInt]) -> Single<[FireStore.Entity.User]> {
    //
    //        let hitUsers = uids.compactMap {
    //            cachedFUsers[$0]
    //        }
    //
    //        let missedUids = uids.filter { (uid) in
    //            !hitUsers.contains { $0.profile.uidInt == uid }
    //        }
    //        .filter { (uid) in
    //            !unfoundUserIds.contains(uid)
    //        }
    //
    //        guard missedUids.isEmpty else {
    //
    //            return Observable.create { [weak self] (subscriber) -> Disposable in
    //
    //                guard let `self` = self else {
    //                    return Disposables.create {}
    //                }
    //
    //                let _ = FireStore.shared.fetchUsers(missedUids)
    //                    .do(onSuccess: { (users) in
    //                        self.cachedFUsers.merge(users.map({ ($0.profile.uidInt, $0) })) { (_, new) in
    //                            new
    //                        }
    //
    //                        let unfoundIds = missedUids.filter { (uid) in
    //                            !users.contains { $0.profile.uidInt == uid }
    //                        }
    //
    //                        guard !unfoundIds.isEmpty else { return }
    //
    //                        self.unfoundUserIds.formUnion(Set(unfoundIds))
    //
    //                    })
    //                    .subscribe(onSuccess: { (users) in
    //
    //                        var allUsers = hitUsers
    //                        allUsers.append(contentsOf: users)
    //
    //                        allUsers.sort { (l, r) -> Bool in
    //                            guard let lIdx = uids.firstIndex(of: l.profile.uidInt),
    //                                  let rIdx = uids.firstIndex(of: r.profile.uidInt) else {
    //                                return true
    //                            }
    //
    //                            return lIdx < rIdx
    //                        }
    //
    //                        subscriber.onNext(allUsers)
    //                        subscriber.onCompleted()
    //
    //                    }) { (error) in
    //                        subscriber.onError(error)
    //                    }
    //
    //                return Disposables.create {}
    //            }
    //            .asSingle()
    //
    //        }
    //
    //        return Observable.just(hitUsers).asSingle()
    //    }
    
}

extension AmongChat.Room.ViewModel: ChatRoomDelegate {
    // MARK: - ChatRoomDelegate
    
    func onJoinChannelFailed(channelId: String?) {
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
    }
    
    func onJoinChannelTimeout(channelId: String?) {
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
    }
    
    func onConnectionChangedTo(state: ConnectState, reason: AgoraConnectionChangedReason) {
        
    }
    
    func onSeatUpdated(position: Int) {
        
    }
    
    func onUserGivingGift(userId: String) {
        
    }
    
    func onMessageAdded(position: Int) {
    }
    
    func onMemberListUpdated(userId: String?) {
        
    }
    
    func onUserStatusChanged(userId: UInt, muted: Bool) {
        if muted {
            otherMutedUser.insert(userId)
        } else {
            otherMutedUser.remove(userId)
        }
        
        //check block
        if let user = blockedUsers.first(where: { $0.uid == userId.int }) {
            mManager.adjustUserPlaybackSignalVolume(user.uid, volume: 0)
        } else if mutedUser.contains(userId) {
            mManager.adjustUserPlaybackSignalVolume(userId.int, volume: 0)
        }
    }
    
    func onAudioMixingStateChanged(isPlaying: Bool) {
        
    }
    
    func onAudioVolumeIndication(userId: UInt, volume: UInt) {
        //        cdPrint("userid: \(userId) volume: \(volume)")
        if let user = room.roomUserList.first(where: { $0.uid.uInt == userId }) {
            //            if isActive {
            self.soundAnimationIndex.accept(user.seatNo - 1)
            //            }
        }
        //        let users = dataSource.value.map { item -> ChannelUser in
        //            guard item.status != .blocked,
        //                item.status != .muted,
        //                item.status != .droped,
        //                item.uid.int!.uInt == userId,
        //                volume > 0 else {
        //                return item
        //            }
        //            var user = item
        //            user.status = .talking
        //            cdPrint("user: \(user)")
        //            return user
        //        }
        //        dataSource.accept(users)
        //        ChannelUserListViewModel.shared.updateVolumeIndication(userId: userId, volume: volume)
    }
    
    func onChannelUserChanged(users: [ChannelUser]) {
        ChannelUserListViewModel.shared.update(users)
    }
}
