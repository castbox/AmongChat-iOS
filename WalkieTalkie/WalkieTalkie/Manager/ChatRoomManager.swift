//
//  ChatRoomManager.swift
//  AgoraChatRoom
//
//  Created by LXH on 2019/11/25.
//  Copyright © 2019 CavanSu. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import AgoraRtcKit
//import AgoraRtmKit

protocol ChatRoomDelegate: class {
    func onSeatUpdated(position: Int)

    func onUserGivingGift(userId: String)

    func onMessageAdded(position: Int)

    func onMemberListUpdated(userId: String?)

    func onUserStatusChanged(userId: UInt, muted: Bool)
    
    func onUserOnlineStateChanged(uid: UInt, isOnline: Bool)

    func onAudioMixingStateChanged(isPlaying: Bool)

    func onAudioVolumeIndication(userId: UInt, volume: UInt)
    
    func onConnectionChangedTo(state: ConnectState, reason: AgoraConnectionChangedReason)
    
    func onJoinChannelFailed(channelId: String?)
    
    func onJoinChannelTimeout(channelId: String?)
    
    func onJoinChannelSuccess(channelId: String?)
    
//    func onChannelUserChanged(users: [ChannelUser])
}

class ChatRoomManager {
    static let shared = ChatRoomManager()

    //join 前必需指定类型
    private var mRtcManager: RtcManageable!
        
    private lazy var agoraRtcManager: AgoraRtcManager = {
        let manager = AgoraRtcManager.shared
        manager.delegate = self
        return manager
    }()
    
    private lazy var zegoRtcManager: ZegoRtcManager = {
        let manager = ZegoRtcManager.shared
        manager.delegate = self
        return manager
    }()
//    private lazy var mRtmManager: RtmManager = {
//        let manager = RtmManager.shared
//        manager.delegate = self
//        return manager
//    }()
    weak var delegate: ChatRoomDelegate?
    
    private(set) var state: ConnectState = .disconnected {
        didSet {
            stateObservable.onNext(state)
        }
    }
    
    var isConnectingState: Bool {
        state.isConnectingState
    }
    
    var isConnectedState: Bool {
        state.isConnectedState
    }
    
//    var role: RtcUserRole? {
//        mRtcManager.role
//    }
    
//    var isReachMaxUnmuteUserCount: Bool {
//        guard let name = channelName,
//            !Settings.shared.isProValue.value else { //非会员
//            return false
//        }
////        if name.isPrivate {
////            return mRtcManager.unMuteUsers.count >= FireStore.channelConfig.sSpeakerLimit
////        } else {
////            return mRtcManager.unMuteUsers.count >= FireStore.channelConfig.gSpeakerLimit
////        }
//        return false
//    }

    //current channel name
    private(set) var channelName: String?
    
    private let stateObservable = BehaviorSubject<ConnectState>(value: .disconnected)
    
    private var mChannelData = ChannelData()
    private var scheduleDispose: Disposable?
    private var heartBeatingRequestDispose: Disposable?

    private init() {
        _ = Settings.shared.loginResult.replay()
            .subscribe(onNext: { [weak self] result in
                guard let result = result, result.uid > 0 else {
                    self?.scheduleDispose?.dispose()
                    self?.heartBeatingRequestDispose?.dispose()
                    return
                }
                self?.startHeartBeating()
            })
    }
    
    func initialize() {
        AgoraRtcManager.shared.initialize()
        ZegoRtcManager.shared.initialize()
    }

    func getChannelData() -> ChannelData {
        mChannelData
    }

//    func getMessageManager() -> MessageManager {
//        self
//    }

//    func getRtcManager() -> AgoraRtcManager {
//        mRtcManager
//    }

//    func getRtmManager() -> RtmManager {
//        mRtmManager
//    }

    func muteMyMic(muted: Bool) {
        mRtcManager.mic(muted: muted)
    }
    
    func update(joinable: RTCJoinable) {
        mRtcManager?.update(joinable: joinable)
    }
    
    func onSeatUpdated(position: Int) {
        delegate?.onSeatUpdated(position: position)
    }

    func joinChannel(_ joinable: RTCJoinable, completionHandler: ((Error?) -> Void)?) {
        switch (joinable.rtcType ?? .agora) {
        case .agora:
            mRtcManager = agoraRtcManager
        case .zego:
            mRtcManager = zegoRtcManager
        }
        //判断 channel 类型
        if state == .connected {
            leaveChannel()
        }
        
        _ = Request.rtcToken(joinable)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onSuccess: { [weak self] token in
                guard let `self` = self, let token = token, let uid = Settings.loginUserId else { return }
                if joinable.rtcType == .agora {
                    self.updateRole(true)
                }
                self.mRtcManager?.joinChannel(joinable, token, uid.uInt) { [weak self] in
                    self?.channelName = joinable.roomId
                    completionHandler?(nil)
                }
            }, onError: { error in
                completionHandler?(error)
                cdPrint("error: \(error)")
            })
    }
    
    func updateRole(_ isPublisher: Bool) {
        let joinRole: RtcUserRole
        if (isPublisher) {
            joinRole = .broadcaster
        } else {
            joinRole = .audience
        }
        mRtcManager.setClientRole(joinRole)
    }

//    func leaveChannel(_ block: ((String) -> Void)? = nil) {
    func leaveChannel() {
        channelName = nil
        mRtcManager.leaveChannel()
        mChannelData.release()
        HapticFeedback.Impact.medium()
//        block?(name)
    }
    
//    func adjustUserPlaybackSignalVolume(_ user: ChannelUser, volume: Int32 = 0) {
//        mRtcManager.adjustUserPlaybackSignalVolume(user, volume: volume)
//    }
    func adjustUserPlaybackSignalVolume(_ uid: Int, volume: Int32 = 0) -> Bool {
        return mRtcManager.adjustUserPlaybackSignalVolume(uid.uInt, volume: volume)
    }

}

//extension ChatRoomManager: MessageManager {
//    func sendOrder(userId: String, orderType: String, content: String?, callback: AgoraRtmSendPeerMessageBlock?) {
//        if !mChannelData.isAnchorMyself() {
//            return
//        }
//        let message = Message(orderType: orderType, content: content, sendId: Constants.sUserId)
//        mRtmManager.sendMessageToPeer(userId, message.toJsonString(), callback)
//    }
//
//    func sendMessage(text: String) {
//        let message = Message(content: text, sendId: Constants.sUserId)
//        mRtmManager.sendMessage(message.toJsonString(), { [weak self] (code) in
//            if code == .errorOk {
//                self?.addMessage(message: message)
//            }
//        })
//    }
//
//    func processMessage(rtmMessage: AgoraRtmMessage) {
//        if let message = Message.fromJsonString(rtmMessage.text) {
//            switch message.messageType {
//            case Message.MESSAGE_TYPE_TEXT:
//                fallthrough
//            case Message.MESSAGE_TYPE_IMAGE:
//                addMessage(message: message)
//            case Message.MESSAGE_TYPE_GIFT:
//                delegate?.onUserGivingGift(userId: message.sendId)
//            case Message.MESSAGE_TYPE_ORDER:
//                let myUserId = String(Constants.sUserId)
//                switch message.orderType {
//                case Message.ORDER_TYPE_AUDIENCE:
//                    toAudience(myUserId, nil)
//                case Message.ORDER_TYPE_BROADCASTER:
//                    if let content = message.content, let position = Int(content) {
//                        toBroadcaster(myUserId, position)
//                    }
//                case Message.ORDER_TYPE_MUTE:
//                    if let content = message.content, let muted = Bool(content) {
//                        muteMic(myUserId, muted)
//                    }
//                default: break
//                }
//            default: break
//            }
//        }
//    }
//
//    func addMessage(message: Message) {
//        let position = mChannelData.addMessage(message: message)
//        delegate?.onMessageAdded(position: position)
//    }
//}

extension ChatRoomManager: RtcDelegate {
    func onJoinChannelSuccess(channelId: String) {
//        mRtmManager.joinChannel(channelId, nil)
        delegate?.onJoinChannelSuccess(channelId: channelId)
    }
    
    func onJoinChannelFailed(channelId: String?) {
        delegate?.onJoinChannelFailed(channelId: channelId)
    }
    
    func onJoinChannelTimeout(channelId: String?) {
        delegate?.onJoinChannelTimeout(channelId: channelId)
    }
    
    func onConnectionChangedTo(state: ConnectState, reason: AgoraConnectionChangedReason) {
        self.state = state
        delegate?.onConnectionChangedTo(state: state, reason: reason)
    }

    func onUserOnlineStateChanged(uid: UInt, isOnline: Bool) {
        if isOnline {
            mChannelData.addOrUpdateUserStatus(uid, false)
//            delegate?.onUserStatusChanged(userId: uid, muted: false)
        } else {
            mChannelData.removeUserStatus(uid)

//            delegate?.onUserStatusChanged(userId: uid, muted: true)
        }
        delegate?.onUserOnlineStateChanged(uid: uid, isOnline: isOnline)
    }

    func onUserMuteAudio(uid: UInt, muted: Bool) {
        mChannelData.addOrUpdateUserStatus(uid, muted)

        delegate?.onUserStatusChanged(userId: uid, muted: muted)
    }

    func onAudioMixingStateChanged(isPlaying: Bool) {
        delegate?.onAudioMixingStateChanged(isPlaying: isPlaying)
    }

    func onAudioVolumeIndication(uid: UInt, volume: UInt) {
        delegate?.onAudioVolumeIndication(userId: uid, volume: volume)
    }
    
//    func onChannelUserChanged(users: [ChannelUser]) {
//        delegate?.onChannelUserChanged(users: users)
//    }
}

//extension ChatRoomManager: RtmDelegate {
//    func onChannelAttributesLoaded() {
//        checkAndBeAnchor()
//    }
//
//    func onChannelAttributesUpdated(attributes: [String: String]) {
//        for attribute in attributes {
//            let key = attribute.key
//            switch key {
//            case AttributeKey.KEY_ANCHOR_ID:
//                let userId = attribute.value
//                if mChannelData.setAnchorId(userId) {
//                    cdPrint("onChannelAttributesUpdated \(key) \(userId)")
//                }
//            default:
//                let index = AttributeKey.indexOfSeatKey(key)
//                if index != NSNotFound {
//                    let value = attribute.value
//                    if updateSeatArray(index, value) {
//                        cdPrint("onChannelAttributesUpdated \(key) \(value)")
//
//                        delegate?.onSeatUpdated(position: index)
//                    }
//                }
//            }
//        }
//    }
//
//    func onInitMembers(members: [AgoraRtmMember]) {
//        for member in members {
//            mChannelData.addOrUpdateMember(Member(userId: member.userId))
//        }
//
//        delegate?.onMemberListUpdated(userId: nil)
//    }
//
//    func onMemberJoined(userId: String, attributes: [String: String]) {
//        cdPrint("onMemberJoined: \(userId) attributes: \(attributes)")
//        for attribute in attributes {
//            if AttributeKey.KEY_USER_INFO == attribute.key {
//                if let member = Member.fromJsonString(attribute.value) {
//                    mChannelData.addOrUpdateMember(member)
//
//                    delegate?.onMemberListUpdated(userId: userId)
//                }
//                break
//            }
//        }
//    }
//
//    func onMemberLeft(userId: String) {
//        mChannelData.removeMember(userId)
//
//        delegate?.onMemberListUpdated(userId: userId)
//    }
//
//    func onMessageReceived(message: AgoraRtmMessage) {
//        processMessage(rtmMessage: message)
//    }
//}

extension ChatRoomManager {
    func startHeartBeating() {
        scheduleDispose?.dispose()
        scheduleDispose = nil
        scheduleDispose = Observable<Int>.interval(.seconds(60), scheduler: SerialDispatchQueueScheduler(qos: .default))
            .startWith(0)
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                self.requestHeartBeating()
            }, onDisposed: {
                cdPrint("heart beating onDisposed")
            })
    }
    
    func requestHeartBeating() {
        var params: [String: Any] = [:]
        if let channelId = mRtcManager?.channelId {
            params["room_id"] = channelId
        }
        cancelHeartBeatingRequest()
        heartBeatingRequestDispose =
            Request.amongchatProvider.rx.request(.heartBeating(params))
            .subscribe()
        
    }
    
    func cancelHeartBeatingRequest() {
        heartBeatingRequestDispose?.dispose()
        heartBeatingRequestDispose = nil
    }
}
