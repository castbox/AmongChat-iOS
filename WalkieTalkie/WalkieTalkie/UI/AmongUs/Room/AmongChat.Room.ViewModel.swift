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
        case kickout(ChatRoom.KickOutMessage.Role) //被踢出
        case beBlocked
    }
    
    
    class ViewModel {
        
        enum ShareEvent {
            case createdRoom //创建时弹出
            case singlePerson // 单人时弹出
        }
        
        enum BlockType {
            case block
            case unblock
        }
        enum LoadDataStatus {
            case begin
            case end
        }
        static var shared: ViewModel?
        
        var messages: [ChatRoomMessage] = []
        let source: ParentPageSource?
        let roomReplay: BehaviorRelay<Entity.Room>
        //麦位声音动画
        let soundAnimationIndex = BehaviorRelay<Int?>(value: nil)
        
        private var messageEventEmitter = PublishSubject<ChatRoomMessage>()
        private var messageListReloadTrigger = PublishSubject<()>()
        var endRoomHandler: ((_ action: EndRoomAction) -> Void)?
        var messageEventHandler: () -> Void = { }
        var followUserSuccess: ((LoadDataStatus, Bool) -> Void)?
        var blockUserResult: ((LoadDataStatus, BlockType, Bool) -> Void)?
        var shareEventHandler: () -> Void = { }


        private let imViewModel: IMViewModel
        private let bag = DisposeBag()
        private var willShowShareEvent: ShareEvent?
        private var didShowShareEvents: [ShareEvent] = []
        //创建房间后，人数由>1人到1人时弹
        private var canShowSinglePersonShareEvent = false
        //更新房间消息的时间
        private var lastestUpdateRoomMs: TimeInterval = 0
                
        private lazy var mManager: ChatRoomManager = {
            let manager = ChatRoomManager.shared
            manager.delegate = self
            return manager
        }()
        
        var blockedUsers = [Entity.RoomUser]() {
            didSet {
                update(room)
            }
        }
        
        //登录用户主动 muted
        private(set) var mutedUser = Set<UInt>() {
            didSet {
                update(room)
            }
        }
        //其他用户自己 muted
        private(set) var otherMutedUser = Set<UInt>() {
            didSet {
                update(room)
            }
        }
        
        private var room: Entity.Room {
            roomReplay.value
        }
        private var enteredTimestamp: TimeInterval!
        var showRecommendUser: Bool {
            let gap = Date().timeIntervalSince1970 - enteredTimestamp
            cdPrint("now time stamp gap : \(gap.int)")
            return (gap.int / 60) > 6
        }
        
        let isMuteMicObservable = BehaviorRelay<Bool>(value: false)
        var isMuteMic: Bool {
            set {
                isMuteMicObservable.accept(newValue)
                ChatRoomManager.shared.muteMyMic(muted: newValue)
                ////find
                guard let userId = Settings.loginUserId?.uInt else {
                    return
                }
                onUserStatusChanged(userId: userId, muted: newValue)
            }
            get { isMuteMicObservable.value }
        }
        
        static func make(_ room: Entity.Room, _ source: ParentPageSource?) -> ViewModel {
            guard let shared = self.shared,
                  shared.room.roomId == room.roomId else {
                let manager = ViewModel(room: room, source: source)
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
        
        init(room: Entity.Room, source: ParentPageSource?) {
            if room.loginUserIsAdmin {
                Logger.Action.log(.admin_imp, categoryValue: room.topicId)
            }
            self.source = source
            roomReplay = BehaviorRelay(value: room)
            imViewModel = IMViewModel(with: room.roomId)
            
            imViewModel.messagesObservable
                .observeOn(MainScheduler.asyncInstance)
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

            
            blockedUsers = Defaults[\.blockedUsersV2Key]
            
            setObservableSubject()
            addSystemMessage()
            enteredTimestamp = Date().timeIntervalSince1970
            startShowShareTimerIfNeed()
        }
        
        @discardableResult
        func join(completionBlock: ((Error?) -> Void)? = nil) -> Bool {
            self.mManager.joinChannel(channelId: self.room.roomId) { error in
                mainQueueDispatchAsync {
                    HapticFeedback.Impact.success()
                    UIApplication.shared.isIdleTimerDisabled = true
                    completionBlock?(error)
                }
            }
            return true
        }
        
        func requestLeaveChannel() -> Single<Bool> {
            mManager.leaveChannel()
            ViewModel.shared = nil
            UIApplication.shared.isIdleTimerDisabled = false
            return Request.leave(with: room.roomId)
        }
        
        func startUpdateBaseInfo() {
            Observable<Int>.interval(.seconds(180), scheduler: SerialDispatchQueueScheduler(qos: .default))
                .subscribe(onNext: { [weak self] _ in
                    self?.requestRoomInfo()
                })
                .disposed(by: bag)

        }
        
        func setObservableSubject() {
            
            messageEventEmitter.asObserver()
                .observeOn(SerialDispatchQueueScheduler(qos: .default))
                .map { message -> ChatRoomMessage in
                    //transfer
                    if let text = message as? ChatRoom.TextMessage {
                        //过滤
                        let (_, result) = SensitiveWordChecker.default.filter(text: text.content)
                        return ChatRoom.TextMessage(content: result, user: text.user, msgType: text.msgType)
                    } else {
                        return message
                    }
                }
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
            let system = ChatRoom.SystemMessage(content: R.string.localizable.amongChatWelcomeMessage(room.topicName), textColor: "FFFFFF", contentType: nil, msgType: .system)
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
            updateRoomInfo(room)
        }
        
        func update(nickName: String) {
            Request.updateRoom(topic: room.topicType, nickName: nickName, with: room.roomId)
                .subscribe { _ in
                    //refresh nick name
                    Settings.shared.updateProfile()
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
            Request.roomInfo(with: room.roomId)
                .asObservable()
                .filterNilAndEmpty()
                .subscribe(onNext: { [weak self] room in
                    self?.update(room)
                })
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
                .subscribe(onNext: { [weak self] room in
                    self?.update(room)
                })
                .disposed(by: bag)
        }
        
        func requestKick(_ users: [Int]) -> Single<Bool> {
            return Request.kick(users, roomId: room.roomId)
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
        
//        func updateVolumeIndication(userId: UInt, volume: UInt) {
//            //            cdPrint("userid: \(userId) volume: \(volume)")
//            let users = dataSource.value.map { item -> ChannelUser in
//                guard item.status != .blocked,
//                      item.status != .muted,
//                      item.status != .droped,
//                      item.uid.int!.uInt == userId,
//                      volume > 0 else {
//                    return item
//                }
//                var user = item
//                user.status = .talking
//                cdPrint("user: \(user)")
//                return user
//            }
//            dataSource.accept(users)
//        }
        
        func followUser(_ user: Entity.RoomUser) {
            followUserSuccess?(.begin, false)
            Request.follow(uid: user.uid, type: "follow")
                .subscribe(onSuccess: { [weak self](success) in
                    if success {
                        self?.followUserSuccess?(.end, true)
                    } else {
                        self?.followUserSuccess?(.end, false)
                    }
                }, onError: { [weak self](error) in
                    self?.followUserSuccess?(.end, false)
                    cdPrint("room follow error:\(error.localizedDescription)")
                }).disposed(by: bag)
        }
        
        func blockedUser(_ user: Entity.RoomUser) {
            if mutedUser.contains(user.uid.uInt) || mManager.adjustUserPlaybackSignalVolume(user.uid, volume: 0) {
                requestBlock(user: user)
            }
        }
        
        func unblockedUser(_ user: Entity.RoomUser) {
            if mutedUser.contains(user.uid.uInt) || mManager.adjustUserPlaybackSignalVolume(user.uid, volume: 100) {
                requestUnblock(user: user)
            }
        }
        private func requestBlock(user: Entity.RoomUser) {
            blockUserResult?(.begin, .block, false)
            Request.follow(uid: user.uid, type: "block")
                .subscribe(onSuccess: { [weak self](success) in
                    if success {
                        self?.blockUserResult?(.end, .block, true)
                        self?.blockedUsers.append(user)
                        Defaults[\.blockedUsersV2Key] = self?.blockedUsers ?? []
                    } else {
                        self?.blockUserResult?(.end,.block, false)
                    }
                }, onError: { [weak self](error) in
                    self?.blockUserResult?(.end, .block, false)
                    cdPrint("room block error :\(error.localizedDescription)")
                }).disposed(by: bag)
        }
        
        private func requestUnblock(user: Entity.RoomUser) {
            blockUserResult?(.begin, .unblock, false)
            Request.unFollow(uid: user.uid, type: "block")
                .subscribe(onSuccess: { [weak self](success) in
                    if success {
                        self?.blockUserResult?(.end, .unblock, true)
                        self?.removeBlocked(user)
                    } else {
                        self?.blockUserResult?(.end, .unblock, false)
                    }
                }, onError: { [weak self](error) in
                    self?.blockUserResult?(.end, .unblock, false)
                    cdPrint("room Unblock error :\(error.localizedDescription)")
                }).disposed(by: bag)
        }
        
        func removeBlocked(_ user: Entity.RoomUser) {
            blockedUsers.removeElement(ifExists: { $0.uid == user.uid })
            Defaults[\.blockedUsersV2Key] = blockedUsers
        }
        
        func muteUser(_ user: Entity.RoomUser) {
            if mManager.adjustUserPlaybackSignalVolume(user.uid, volume: 0) {
                mutedUser.insert(user.uid.uInt)
            }
        }
        
        func unmuteUser(_ user: Entity.RoomUser) {
            if !blockedUsers.contains(where: { $0.uid == user.uid }),
               mManager.adjustUserPlaybackSignalVolume(user.uid, volume: 100) {
                mutedUser.remove(user.uid.uInt)
            }
        }
                        
        func didJoinedChannel(_ channel: String) {
            let _ = Request.reportEnterRoom(channel)
                .subscribe(onSuccess: { (_) in
                })
        }
         
        func didShowShareView() {
            guard let event = willShowShareEvent else {
                return
            }
            didShowShareEvents.append(event)
        }
    }
    
}

private extension AmongChat.Room.ViewModel {
    func startShowShareTimerIfNeed() {
        guard source?.isFromCreatePage == true else {
            return
        }
        delayToShowShareView(event: .createdRoom)
    }
    
    func delayToShowShareView(event: ShareEvent, delay duration: Int = 3) -> Bool {
        guard !didShowShareEvents.contains(event), willShowShareEvent == nil else {
            return false
        }
        willShowShareEvent = event
        Observable.just(())
            .delay(.seconds(duration), scheduler: MainScheduler.asyncInstance)
            .subscribe { [weak self] _ in
                guard let `self` = self else { return }
                self.willShowShareEvent = nil
                if !self.didShowShareEvents.contains(event) {
                    self.didShowShareEvents.append(event)
                    self.shareEventHandler()
                }
            }
            .disposed(by: bag)
        return true
    }
    
    func update(_ room: Entity.Room) {
        
        //when first to admin logger
        if room.loginUserIsAdmin,
           self.room.loginUserIsAdmin != room.loginUserIsAdmin {
            Logger.Action.log(.admin_imp, categoryValue: room.topicId)
        }
        
        var newRoom = room
        let userList = newRoom.roomUserList
        let blockedUsers = self.blockedUsers
        newRoom.roomUserList = userList.map { user -> Entity.RoomUser in
            var newUser = user
            newUser.topic = room.topicType
            if blockedUsers.contains(where: { $0.uid == user.uid }) {
                newUser.status = .blocked
                newUser.isMuted = true
                newUser.isMutedByLoginUser = true
            } else {
                if otherMutedUser.contains(user.uid.uInt) || mutedUser.contains(user.uid.uInt) {
                    newUser.isMuted = true
                    newUser.status = .muted
                    newUser.isMutedByLoginUser = mutedUser.contains(user.uid.uInt)
                } else {
                    newUser.isMuted = false
                    newUser.status = .connected
                    newUser.isMutedByLoginUser = false
                }

            }
            return newUser
        }
        roomReplay.accept(newRoom)
        
        //人数为1时的分享控制
        if (canShowSinglePersonShareEvent || source?.isFromCreatePage == false), userList.count == 1,
           delayToShowShareView(event: .singlePerson, delay: 5) {
            canShowSinglePersonShareEvent = false
        }
//
        if !didShowShareEvents.contains(.singlePerson), userList.count > 1 {
            canShowSinglePersonShareEvent = true
        }
    }
    
    func onReceiveChatRoom(crMessage: ChatRoomMessage) {
        cdPrint("onReceiveChatRoom- \(crMessage)")
        if let message = crMessage as? ChatRoom.TextMessage {
            addUIMessage(message: message)
        } else if let message = crMessage as? ChatRoom.JoinRoomMessage {
            addUIMessage(message: message)
        } else if let message = crMessage as? ChatRoom.SystemMessage {
            addUIMessage(message: message)
        } else if let message = crMessage as? ChatRoom.RoomInfoMessage {
            if message.ms > lastestUpdateRoomMs {
                lastestUpdateRoomMs = message.ms
                update(message.room)
            }
        } else if let message = crMessage as? ChatRoom.KickOutMessage,
                  message.user.uid == Settings.loginUserId {
            //自己
            endRoomHandler?(.kickout(message.opRole))
        } else if let message = crMessage as? ChatRoom.LeaveRoomMessage {
            otherMutedUser.remove(message.user.uid.uInt)
        }
    }
    
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
        let userList = room.roomUserList
        if userList.contains(where: { $0.uid.uInt == userId }), muted {
            otherMutedUser.insert(userId)
        } else {
            otherMutedUser.remove(userId)
        }
//        cdPrint("-onUserStatusChanged uid: \(userId) muted: \(muted) otherMutedUser: \(otherMutedUser)")

        //check block
        if let user = blockedUsers.first(where: { $0.uid == userId.int }) {
            mManager.adjustUserPlaybackSignalVolume(user.uid, volume: 0)
        } else if mutedUser.contains(userId) {
            mManager.adjustUserPlaybackSignalVolume(userId.int, volume: 0)
        }
        
        //delay to request
        if !imViewModel.imIsReady || !userList.contains(where: { $0.uid.uInt == userId }) {
            //delay 1 second to check if have current user
            Logger.Action.log(.rtc_call_roominfo)
            delayToUpdateUserList(for: userId)
        }
    }
    
    func delayToUpdateUserList(for userId: UInt) {
        //
        Observable.just(())
            .delay(.seconds(1), scheduler: MainScheduler.asyncInstance)
            .subscribe { [weak self] _ in
                guard let `self` = self,
                      !self.room.roomUserList.contains(where: { $0.uid.uInt == userId }) else {
                    return
                }
                Logger.Action.log(.rtc_call_roominfo)
                self.requestRoomInfo()
            }
            .disposed(by: bag)
    }
    
    func onAudioMixingStateChanged(isPlaying: Bool) {
        
    }
    
    func onAudioVolumeIndication(userId: UInt, volume: UInt) {
//        cdPrint("userId: \(userId) volume: \(volume)")
        if let user = room.roomUserList.first(where: { $0.uid.uInt == userId }) {
            self.soundAnimationIndex.accept(user.seatNo - 1)
        }
    }
    
//    func onChannelUserChanged(users: [ChannelUser]) {
////        ChannelUserListViewModel.shared.update(users)
//    }
}
