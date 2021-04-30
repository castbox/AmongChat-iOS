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
    
    func onConnectionChangedTo(state: ConnectState, reason: RtcConnectionChangedReason)
    
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

    //current channel name
    private(set) var channelName: String?
    
    private let stateObservable = BehaviorSubject<ConnectState>(value: .disconnected)
    
    private var mChannelData = ChannelData()
    private var stateDispose: Disposable?
//    private var scheduleDispose: Disposable?
    private var heartBeatingRequestDispose: Disposable?

    private init() {
        startScheduleEvent()
    }
    
    func initialize() {
        AgoraRtcManager.shared.initialize()
        ZegoRtcManager.shared.initialize()
    }

    func getChannelData() -> ChannelData {
        mChannelData
    }

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
        //leave 时需要判断上一个引擎是否销毁
        if state != .disconnected {
            leaveChannel()
        }
        stateDispose?.dispose()
        stateDispose = stateObservable
            .observeOn(MainScheduler.asyncInstance)
            .filter { $0 == .disconnected } //上一个 rtc 状态必须为断开，避免异常情况
            .flatMap { [weak self] _ -> Observable<String?> in
                switch (joinable.rtcType ?? .agora) {
                case .agora:
                    self?.mRtcManager = self?.agoraRtcManager
                case .zego:
                    self?.mRtcManager = self?.zegoRtcManager
                }
                return Request.rtcToken(joinable).asObservable()
            }
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] token in
                guard let `self` = self, let token = token, let uid = Settings.loginUserId else { return }
                self.channelName = joinable.roomId
                self.mRtcManager?.joinChannel(joinable, token, uid.uInt) { [weak self] in
                    completionHandler?(nil)
                }
            }, onError: { error in
                completionHandler?(error)
                cdPrint("error: \(error)")
            })

    }
    
//    func updateRole(_ role: RtcUserRole) {
////        let joinRole: RtcUserRole
////        if (isPublisher) {
////            joinRole = .broadcaster
////        } else {
////            joinRole = .audience
////        }
//        mRtcManager.setClientRole(role)
//    }
    
    var rtcRole: RtcUserRole {
        set { mRtcManager.clientRole = newValue }
        get { mRtcManager.clientRole }
    }

//    func leaveChannel(_ block: ((String) -> Void)? = nil) {
    func leaveChannel() {
        channelName = nil
        stateDispose?.dispose()
        mRtcManager?.leaveChannel()
        mChannelData.release()
        HapticFeedback.Impact.medium()
//        block?(name)
    }
    
    func adjustUserPlaybackSignalVolume(_ uid: Int, volume: Int32 = 0) -> Bool {
        return mRtcManager.adjustUserPlaybackSignalVolume(uid.uInt, volume: volume)
    }

}

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
    
    func onConnectionChangedTo(state: ConnectState, reason: RtcConnectionChangedReason) {
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
    func startScheduleEvent() {
        _ = Observable<Int>.interval(.seconds(60), scheduler: SerialDispatchQueueScheduler(qos: .default))
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                self.requestHeartBeating()
            })
        
        _ = Settings.shared.profilePage.replay()
            .subscribe(onNext: { [weak self] result in
                guard let result = result?.profile, result.uid > 0, result.roleType == .some(.none) else {
                    self?.heartBeatingRequestDispose?.dispose()
                    //leave channel
                    self?.leaveChannel()
                    return
                }
                self?.requestHeartBeating()
            })
    }
    
    func requestHeartBeating() {
        guard let profile = Settings.shared.profilePage.value?.profile,
              profile.uid > 0,
              profile.roleType == .some(.none) else {
            heartBeatingRequestDispose?.dispose()
            return
        }
        var params: [String: Any] = [:]
        if let channelId = channelName {
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
