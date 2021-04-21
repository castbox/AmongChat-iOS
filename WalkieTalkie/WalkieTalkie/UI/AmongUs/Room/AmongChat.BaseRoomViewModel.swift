//
//  AmongChat.BaseRoomViewModel.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 02/04/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import SwifterSwift
import SwiftyUserDefaults
import AgoraRtcKit
import CastboxDebuger

extension AmongChat {
    
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
    
    
    class BaseRoomViewModel: SendMessageable, MessageDataSource {
        
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
        
        let source: ParentPageSource?
        //麦位声音动画
        let soundAnimationIndex = BehaviorRelay<Int?>(value: nil)
  
        var isSilentUser: Bool = false {
            didSet {
                bottomBarHideReplay.accept(isSilentUser)
            }
        }

        //hide if user is admin
        let bottomBarHideReplay = BehaviorRelay<Bool>(value: false)
        
        private var messageEventEmitter = PublishSubject<ChatRoomMessage>()
        private var messageListReloadTrigger = PublishSubject<()>()
        
        var endRoomHandler: ((_ action: EndRoomAction) -> Void)?
        //
        var messages: [ChatRoomMessage] = []
        var messageListUpdateEventHandler: CallBack?
        
        var followUserSuccess: ((LoadDataStatus, Bool) -> Void)?
        var blockUserResult: ((LoadDataStatus, BlockType, Bool) -> Void)?
        var shareEventHandler: () -> Void = { }
        var onUserJoinedHandler: ((Entity.RoomUser) -> Void)?
        var messageHandler: ((ChatRoomMessage) -> Void)?

        var imViewModel: AmongChat.Room.IMViewModel!
        
        let bag = DisposeBag()
        
        private var willShowShareEvent: ShareEvent?
        private var didShowShareEvents: [ShareEvent] = []
        //创建房间后，人数由>1人到1人时弹
        private var canShowSinglePersonShareEvent = false
        //更新房间消息的时间
        var lastestUpdateRoomMs: TimeInterval = 0
        //当前房间状态， 只有在 connected 时，才需要根据 rtc 状态来刷新直播间
        var state: ConnectState = .disconnected
        
        //存储
        var seatDataSource: [AmongChat.Room.SeatItem] = [] {
            didSet {
                seatDataSourceReplay.accept(seatDataSource)
            }
        }
        
        let seatDataSourceReplay = BehaviorRelay<[AmongChat.Room.SeatItem]>(value: [])
        
        let roomReplay: BehaviorRelay<RoomDetailable>
        
        private var roomDetail: RoomDetailable {
            roomReplay.value
        }
        
        lazy var mManager: ChatRoomManager = {
            let manager = ChatRoomManager.shared
            manager.delegate = self
            return manager
        }()
        
        var blockedUsers = [Entity.RoomUser]() {
            didSet {
                update(roomDetail)
            }
        }
        
        //登录用户主动 muted
        var mutedUser = Set<UInt>() {
            didSet {
                update(roomDetail)
            }
        }
        //其他用户自己 muted
        var otherMutedUser = Set<UInt>() {
            didSet {
                update(roomDetail)
            }
        }
        
//        private var room: Entity.Room {
//            roomReplay.value
//        }
        
        private var enteredTimestamp: TimeInterval!
        var stayDuration: Int {
            let gap = Date().timeIntervalSince1970 - enteredTimestamp
            cdPrint("now time stamp gap : \(gap.int)")
            return gap.int
        }
        
        var showRecommendUser: Bool {
            (stayDuration / 60) > 6
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
        
//        static func make(_ room: Entity.Room, _ source: ParentPageSource?) -> ViewModel {
//            guard let shared = self.shared,
//                  shared.room.roomId == room.roomId else {
//                let manager = ViewModel(room: room, source: source)
//                //退出之前房间
//                //                self.shared?.quitRoom()
//                //设置新房间
//                self.shared = manager
//                return manager
//            }
//            //            shared.createType = .restore
//            //            shared.stateType = .default
//            return shared
//
//        }
        
        deinit {
            debugPrint("[DEINIT-\(NSStringFromClass(type(of: self)))]")
        }
        
        init(room: RoomDetailable, source: ParentPageSource?) {
//            if room.loginUserIsAdmin {
//                Logger.Action.log(.admin_imp, categoryValue: room.topicId)
//            }
            self.source = source
            roomReplay = BehaviorRelay(value: room)
            blockedUsers = Defaults[\.blockedUsersV2Key]
            
            setObservableSubject()
            addSystemMessage()
            enteredTimestamp = Date().timeIntervalSince1970
//            startShowShareTimerIfNeed()
//            update(room)
//            if room.loginUserSeatNo == 0 {
//                cdPrint("****\n\n----------------------------\n Error：room 信息未包含自己 \(room)")
//            }
        }
        
        func startImService() {
            imViewModel = AmongChat.Room.IMViewModel(with: roomDetail.roomId)
            
            imViewModel.roomMessagesObservable
                .observeOn(MainScheduler.asyncInstance)
                .subscribe(onNext: { [weak self] (msg) in
                    self?.onReceiveChatRoom(crMessage: msg)
                })
                .disposed(by: bag)
            
            imViewModel.peerMessagesObservable
                .observeOn(MainScheduler.asyncInstance)
                .subscribe(onNext: { [weak self] (msg) in
                    self?.onReceivePeer(message: msg)
                })
                .disposed(by: bag)
            
            imViewModel.imReadySignal
                .filter { $0 }
                .subscribe { [weak self] _ in
                    self?.startUpdateBaseInfo()
                    
                }
                .disposed(by: bag)
        }
        
        @discardableResult
        func join(completionBlock: ((Error?) -> Void)? = nil) -> Bool {
            state = .connecting
            self.mManager.joinChannel(roomDetail) { [weak self] error in
                self?.state = .connected
                mainQueueDispatchAsync {
                    HapticFeedback.Impact.success()
                    UIApplication.shared.isIdleTimerDisabled = true
                    completionBlock?(error)
                }
            }
            startImService()
            return true
        }
        
        func quitServices() {
//            Logger.Action.log(.room_leave_clk, categoryValue: room.topicId, nil, stayDuration)
            mManager.leaveChannel()
            imViewModel.leaveChannel()
//            ViewModel.shared = nil
            state = .disconnected
            UIApplication.shared.isIdleTimerDisabled = false
//            return Request.leave(with: roomin)
        }
        
        func startUpdateBaseInfo() {
            Observable<Int>.interval(.seconds(180), scheduler: SerialDispatchQueueScheduler(qos: .default))
                .subscribe(onNext: { [weak self] _ in
                    self?.requestRoomInfo()
                })
                .disposed(by: bag)
        }
        
        func requestRoomInfo() {
            
        }
        
        func setObservableSubject() {
            
            messageEventEmitter.asObserver()
                .observeOn(SerialDispatchQueueScheduler(qos: .default))
                .map { message -> ChatRoomMessage in
                    //transfer
                    if let text = message as? ChatRoom.TextMessage {
                        //过滤
                        let (_, result) = SensitiveWordChecker.default.filter(text: text.content)
                        return ChatRoom.TextMessage(content: result, user: text.user, msgType: text.msgType, contentColor: text.contentColor, isGroupRoomHostMsg:  text.isGroupRoomHostMsg)
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
                    self?.messageListUpdateEventHandler?()
                })
                .disposed(by: bag)
        }
        
        func addSystemMessage() {
            let system = ChatRoom.SystemMessage(content: R.string.localizable.amongChatWelcomeMessage(roomDetail.topicName), textColor: "FFFFFF", contentType: nil, msgType: .system)
            addUIMessage(message: system)
        }
        
        func addJoinMessage() {
            guard let user = Settings.shared.amongChatUserProfile.value?.toRoomUser(with: roomDetail.loginUserSeatNo + 1) else {
                return
            }
            let joinRoomMsg = ChatRoom.JoinRoomMessage(user: user, msgType: .joinRoom)
            addUIMessage(message: joinRoomMsg)
            onUserJoinedHandler?(joinRoomMsg.user)
        }
        
        // 添加消息
        func addUIMessage(message: ChatRoomMessage) {
            messageEventEmitter.onNext(message)
        }
        
        func triggerMessageListReload() {
            messageListReloadTrigger.onNext(())
        }
        
        func sendText(message: String?) {
            guard
                let message = message?.trimmed,
                  !message.isEmpty,
                  let user = roomDetail.userList.first(where: { $0.uid == Settings.loginUserId }) else {
                return
            }
            //检查是否 Im 被 mute
//            guard <#condition#> else {
//                <#statements#>
//            }
            let textMessage = ChatRoom.TextMessage(content: message, user: user, msgType: .text)
            imViewModel.sendText(message: textMessage) { [weak self] in
                Logger.Action.log(.group_send_message_success, categoryValue: self?.roomDetail.topicId)
            }
            //append
            addUIMessage(message: textMessage)
        }
        
        func addImMutedMessage(user: Entity.RoomUser) {
            let textMessage = ChatRoom.TextMessage(content: R.string.localizable.messageDisableTips(), user: user, msgType: .text, contentColor: "FB5858")
            addUIMessage(message: textMessage)
        }
        
        //send emoji message
        func sendEmoji(_ emoji: Entity.EmojiItem) {
            guard let resource = emoji.resource.randomElement(),
                  let user = roomDetail.userList.first(where: { $0.uid == Settings.loginUserId }) else {
                return
            }
            let emojiMessage = ChatRoom.EmojiMessage(
                resource: resource,
                duration: emoji.duration,
                hideDelaySec: emoji.hide_delay_sec,
                emojiType: emoji.type,
                msgType: .emoji,
                user: user
            )
            imViewModel.sendText(message: emojiMessage) { [weak self] in
                self?.messageHandler?(emojiMessage)
            }
        }
        
        func updateSeatDataSource() {
            var dataSource: [AmongChat.Room.SeatItem] = []
            for index in 0 ..< 10 {
                //当前已有数据，重新填充信息
                let item: AmongChat.Room.SeatItem
                if let prevItem = seatDataSource.safe(index) {
                    item = prevItem
                } else {
                    item = AmongChat.Room.SeatItem(roomDetail.roomId)
                }
                item.user = roomDetail.userListMap[index]
                dataSource.append(item)
//                seatDataSource[index] = item
            }
            seatDataSource = dataSource
        }
        
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
        
        func roomBgImage() -> UIImage? {
            return UIImage(named: "icon_room_bg_topicId_\(roomDetail.topicId)")
        }
        
        func roomBgUrl() -> URL? {
            guard let setting = Settings.shared.globalSetting.value else {
                return nil
            }
            let topicId = roomDetail.topicId
            return setting.roomBg.first(where: { $0.topicId == topicId })
                .map { $0.bgUrl }
        }
        
        //快速切换房间
//        func nextRoom(completionHandler: ((_ room: Entity.Room?, _ errorMessage: String?) -> Void)?) {
//            //clear status
//            let topicId = room.topicId
//            requestLeaveChannel()
////                .do(onNext: { [weak self] result in
////                    cdPrint("nextRoom leave room: \(result)")
////                    let emptyRoom = Entity.Room(amongUsCode: nil, amongUsZone: nil, note: nil, roomId: "", userList: [], state: .public, topicId: topicId, topicName: "", rtcType: .agora, rtcBitRate: nil, coverUrl: nil)
////                    self?.update(emptyRoom)
////                    self?.messages = []
////                    self?.triggerMessageListReload()
////                })
//                .flatMap { result -> Single<Entity.Room?> in
//                    return Request.enterRoom(topicId: topicId, source: ParentPageSource(.room).key)
//                }
//                .subscribe(onSuccess: { [weak self] (room) in
//                    // TODO: - 进入房间
//                    guard let room = room else {
//                        return
//                    }
////                    self?.update(room)
//                    completionHandler?(room, nil)
//                }, onError: { error in
//    //                completion()
//                    cdPrint("error: \(error.localizedDescription)")
//                    var msg: String {
//                        if let error = error as? MsgError {
//                            if let codeType = error.codeType, codeType == .needUpgrade {
//                                return R.string.localizable.forceUpgradeTip()
//                            }
//                            return error.localizedDescription
//                        } else {
//                            return R.string.localizable.amongChatHomeEnterRoomFailed()
//                        }
//                    }
//                    completionHandler?(nil, msg)
//                })
//                .disposed(by: bag)
//
//        }
        
        func updateSeatUserStatus(_ user: Entity.RoomUser) -> Entity.RoomUser {
            var newUser = user
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
        
        func update(_ room: RoomDetailable) {
            var newRoom = room
            let userList = newRoom.userList
//            let blockedUsers = self.blockedUsers
            newRoom.userList = userList.map { user -> Entity.RoomUser in
                var newUser = updateSeatUserStatus(user)
                newUser.topic = room.topicType
                return newUser
            }
            roomReplay.accept(newRoom)
            
            //同步状态
            mManager.update(joinable: newRoom)
            
            updateSeatDataSource()
            
            delayToShowShareViewIfNeed()
        }
        
        //chat room message
        func onReceiveChatRoom(crMessage: ChatRoomMessage) {
            cdPrint("onReceiveChatRoom- \(crMessage)")
            guard state != .disconnected else {
                return
            }
            
            if let message = crMessage as? ChatRoom.TextMessage {
                addUIMessage(message: message)
            } else if let message = crMessage as? ChatRoom.JoinRoomMessage,
                      message.user.uid != Settings.loginUserId {
                //add to entrance queue
                onUserJoinedHandler?(message.user)
                addUIMessage(message: message)
            } else if let message = crMessage as? ChatRoom.SystemMessage {
                addUIMessage(message: message)
            } else if let message = crMessage as? ChatRoom.RoomInfoMessage {
                if message.ms > lastestUpdateRoomMs {
                    lastestUpdateRoomMs = message.ms
                    update(message.room)
                }
            } else if let message = crMessage as? ChatRoom.KickOutMessage,
                      message.user.uid == Settings.loginUserId,
                      roomDetail.rtcType == .agora {
                //自己
                endRoomHandler?(.kickout(message.opRole))
            } else if let message = crMessage as? ChatRoom.LeaveRoomMessage {
                otherMutedUser.remove(message.user.uid.uInt)
            } else if crMessage.msgType == .emoji {
                messageHandler?(crMessage)
            }
        }
        
        func onReceivePeer(message: PeerMessage) {
            //
            
        }
        
        func startShowShareTimerIfNeed() {
            guard source?.isFromCreatePage == true
                else {
                return
            }
            delayToShowShareView(event: .createdRoom)
        }
        
        func delayToShowShareViewIfNeed() {
            //人数为1时的分享控制
            if (canShowSinglePersonShareEvent || source?.isFromCreatePage == false), roomDetail.userList.count == 1,
               delayToShowShareView(event: .singlePerson, delay: 5) {
                canShowSinglePersonShareEvent = false
            }
    //
            if !didShowShareEvents.contains(.singlePerson), roomDetail.userList.count > 1 {
                canShowSinglePersonShareEvent = true
            }
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
        
    }
}

private extension AmongChat.BaseRoomViewModel {
    
    func shouldRefreshRoom(uid: UInt, isOnline: Bool) -> Bool {
        guard !isSilentUser else {
            return false
        }
        let userList = roomDetail.userList
        if isOnline, (!imViewModel.imIsReady || !userList.contains(where: { $0.uid.uInt == uid })) {
            return true
        }
        if !isOnline, userList.contains(where: { $0.uid.uInt == uid }) {
            return true
        }
        return false
    }
    
    func delayToUpdateUserList(for userId: UInt, isOnline: Bool) {
        guard state != .disconnected else {
            return
        }
        Observable.just(())
            .debounce(.seconds(1), scheduler: MainScheduler.asyncInstance)
            .subscribe { [weak self] _ in
                guard let `self` = self, self.shouldRefreshRoom(uid: userId, isOnline: isOnline) else {
                    return
                }
                Logger.Action.log(.rtc_call_roominfo)
                self.requestRoomInfo()
            }
            .disposed(by: bag)
    }
    
}

extension AmongChat.BaseRoomViewModel: ChatRoomDelegate {
    // MARK: - ChatRoomDelegate
    
    func onJoinChannelSuccess(channelId: String?) {
        
    }
    
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

    }
    
    func onConnectionChangedTo(state: ConnectState, reason: RtcConnectionChangedReason) {
        guard roomDetail.rtcType == .zego, state == .disconnected else {
            return
        }
        switch reason {
        case .kickByHost:
            endRoomHandler?(.kickout(.host))
        case .kickBySystemOfRoomInactive, .kickBySystemOfRoomFull:
            endRoomHandler?(.kickout(.system))
        default:
            ()
        }
        
    }
    
    func onSeatUpdated(position: Int) {
        
    }
    
    func onUserGivingGift(userId: String) {
        
    }
    
    func onMessageAdded(position: Int) {
    }
    
    func onMemberListUpdated(userId: String?) {
        
    }
    
    @objc func onUserStatusChanged(userId: UInt, muted: Bool) {
        let userList = roomDetail.userList
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
    }
    
    @objc func onUserOnlineStateChanged(uid: UInt, isOnline: Bool) {
        //delay to request
        guard shouldRefreshRoom(uid: uid, isOnline: isOnline) else {
            return
        }
        //delay 1 second to check if have current user
        Logger.Action.log(.rtc_call_roominfo)
        delayToUpdateUserList(for: uid, isOnline: isOnline)
    }
    
    func onAudioMixingStateChanged(isPlaying: Bool) {
        
    }
    
    @objc func onAudioVolumeIndication(userId: UInt, volume: UInt) {
//        cdPrint("userId: \(userId) volume: \(volume)")
        if let user = roomDetail.userList.first(where: { $0.uid.uInt == userId }) {
            soundAnimationIndex.accept(user.seatNo - 1)
        } else if let group = roomDetail as? Entity.Group,
                  userId.int == group.uid {
            //-1 is host
            soundAnimationIndex.accept(-1)
        }
    }
    
//    func onChannelUserChanged(users: [ChannelUser]) {
////        ChannelUserListViewModel.shared.update(users)
//    }
}

