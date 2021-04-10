//
//  AmongChat.GroupRoom.ViewModel.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 29/03/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import SwifterSwift
import SwiftyUserDefaults
import AgoraRtcKit
import CastboxDebuger

fileprivate func cdPrint(_ message: Any) {
    Debug.info("[AmongChat.GroupRoom.AudienceViewModel]-\(message)")
}

extension AmongChat.GroupRoom {
        
    class AudienceViewModel: BaseViewModel {
        
//        var callMsgHandler: ((PhoneCallRejectType, Peer.CallMessage) -> Void)?
        //MARK: -
        
        var phoneCallState = PhoneCallState.preparing

        var callinRequestTimerDispose: Disposable?
        
        var callingHandler: (PhoneCallRejectType, Peer.CallMessage) -> Void = { _, _ in }
        
        var callinInviteHandler: () -> Void = { }
        
        var callSwitch: Bool = true
        
        override var state: ConnectState {
            didSet {
                syncPhoneCallStateIfNeed()
            }
        }
        
        override func update(_ room: RoomInfoable) {
            super.update(room)
            //
            syncPhoneCallStateIfNeed()
        }
        
        func syncPhoneCallStateIfNeed() {
            //如果麦上有自己, 但自己没连麦，需要主动上麦
            guard state == .connected else {
                return
            }
//            if group.userList.contains(where: { $0.uid == Settings.loginUserId }) {
//                if mManager.rtcRole == .audience {
//                    updatePhoneCallState(.calling)
//                }
//            }
//            else if mManager.rtcRole == .broadcaster {
//                updatePhoneCallState(.readyForCall)
//            }
        }
        
        func requestOnSeat(at position: Int) {
            guard position >= 0 && position < 10,
                  let user = Settings.loginUserProfile,
                  let item = seatDataSource.safe(position) else {
                return
            }
            //拿到改位置占位 item
            //将 item 更改为 loading 状态
            item.user = user.toRoomUser(with: position)
            item.callContent = Peer.CallMessage(action: .request, gid: group.gid, expireTime: 30, position: position, user: user)
            sendCall(action: .request, position: position)
            //update state
            seatDataSource[position] = item
        }
        
        //清除当前calling麦位状态
        func clearSeatCallState() {
            if let position = seatsIndex(),
               let item = seatDataSource.safe(position) {
                item.clear()
                seatDataSource[position] = item
            }
        }
        
        //
        func updateOnSeatState(with callMessage: Peer.CallMessage) {
            if let position = seatsIndex(),
               let item = seatDataSource.safe(position) {
                // 更新call-in之后的状态
                item.callContent = callMessage
                seatDataSource[position] = item
            }
        }
        
        func seatsIndex(of uid: Int? = nil) -> Int? {
            let uid = uid ?? (Settings.loginUserId ?? 0)
            for (_, item) in seatDataSource.enumerated() {
                if item.user?.uid == uid  {
                    return item.user?.seatNo
                }
            }
            return nil
        }
        
        override func onReceiveChatRoom(crMessage: ChatRoomMessage) {
            cdPrint("onReceiveChatRoom- \(crMessage)")
            guard state != .disconnected else {
                return
            }
            
            if let message = crMessage as? ChatRoom.TextMessage {
                addUIMessage(message: message)
            } else if let message = crMessage as? ChatRoom.GroupJoinRoomMessage,
                      message.user.uid != Settings.loginUserId {
                //add to entrance queue
//                onUserJoinedHandler?(message)
                addUIMessage(message: message)
            } else if let message = crMessage as? ChatRoom.SystemMessage {
                addUIMessage(message: message)
            } else if let message = crMessage as? ChatRoom.GroupInfoMessage {
                if message.ms > lastestUpdateRoomMs {
                    lastestUpdateRoomMs = message.ms
                    update(message.group)
                }
            } else if let message = crMessage as? ChatRoom.KickOutMessage,
                      message.user.uid == Settings.loginUserId,
                      group.rtcType == .agora {
                //自己
                endRoomHandler?(.kickout(message.opRole))
            } else if let message = crMessage as? ChatRoom.GroupLeaveRoomMessage {
                otherMutedUser.remove(message.user.uid.uInt)
            } else if let message = crMessage as? ChatRoom.GroupRoomEndMessage,
                      message.gid == group.gid {
                endRoomHandler?(.normalClose)
            } else if crMessage.msgType == .emoji {
                messageHandler?(crMessage)
            }
//            else if message.messageType == .call { // Call 电话状态
//                self.onReceiveCallMessage(callContent: content as? CallContent)
//            }
        }
        
        override func onReceivePeer(message: PeerMessage) {
            //非 Host
            if let applyMessage = message as? Peer.GroupApplyMessage,
               applyMessage.gid == group.gid {
                let status: Entity.GroupInfo.UserStatus
                switch applyMessage.action {
                case .accept:
                    status = .memeber
                case .reject:
                    status = .none
                case .request:
                    status = .applied
                }
                var info = self.groupInfo
                info.userStatusInt = status.rawValue
                self.groupInfoReplay.accept(info)
            } else if let applyMessage = message as? Peer.CallMessage {
                //收到主播回复消息
                onReceiveCall(applyMessage)
            }
                 
        }
        
//        func onConnectionChangedTo(state: ConnectState, reason: RtcConnectionChangedReason) {
//            if state == .connected {
//                syncPhoneCallStateIfNeed()
//            }
//        }
        
        override func roomBgImage() -> UIImage? {
            return UIImage(named: "icon_room_bg_topicId_group")
        }
        
        override func roomBgUrl() -> URL? {
            return group.bgUrl?.url
        }
        
        //MARK: - For Auidiance
        func sendMessage(call action: Peer.CallMessage.Action, expired: Int64, extra: String, position: Int = 0) {
            //user
            let content = Peer.CallMessage(action: action, gid: group.gid, expireTime: expired, extra: extra, position: position, user: Settings.loginUserProfile!)
            imViewModel.sendPeer(message: content, to: group.broadcaster.uid)
        }
        
        // MARK: - CALL
        func sendCall(action: Peer.CallMessage.Action, position: Int = 0) {
            cdPrint("sendCall action: \(action)")
            switch action {
            case .request:
                phoneCallState = .requesting
                sendMessage(call: action, expired: 90, extra: "", position: position)
//                LiveEngine.shared.sendCallSignal(action: .request, roomInfo: roomInfo, expired: 30, extra: "", position: position)
                
                //30 秒倒计时后自动挂断
                let timer = Observable<Int>
                    .timer(.seconds(90), scheduler: MainScheduler.instance)
                callinRequestTimerDispose?.dispose()
                callinRequestTimerDispose = nil
                callinRequestTimerDispose = timer
                    .subscribe(onNext: { [weak self] _ in
                        guard let `self` = self else { return }
                        if self.phoneCallState == .requesting {
                            self.phoneCallHangUpBySelf(.timeout)
                        }
                    })
                callinRequestTimerDispose?.disposed(by: bag)
            case .invite_reject:
                callinRequestTimerDispose?.dispose()
                callinRequestTimerDispose = nil
                phoneCallState = PhoneCallState.readyForCall
                sendMessage(call: action, expired: 90, extra: "", position: position)
//                LiveEngine.shared.sendCallSignal(action: .invite_reject, roomInfo: roomInfo, expired: 30, extra: "", position: position)

            default:
                // 直接断开
                phoneCallState = PhoneCallState.readyForCall
                sendMessage(call: .hangup, expired: 90, extra: "", position: position)
//                LiveEngine.shared.sendCallSignal(action: .hangup, roomInfo: roomInfo, expired: 30, extra: "", position: position)

            }
        }
        
//        func sendPhoneCallEventIfNeed() {
//            guard createType == .restore else {
//                return
//            }
//            updatePhoneCallState(phoneCallState)
//        }
        
        func hangupCallIfNeed() {
            guard phoneCallState == .requesting else {
                return
            }
            phoneCallHangUpBySelf()
        }
        
        func onReceiveCall(_ message: Peer.CallMessage?) {
            
            guard let callContent = message else {
                return
            }
            
//            insertNewListener(callContent.userInfo)
            
            cdPrint("~~~~callcontent: \(callContent)) state: \(phoneCallState.rawValue)")
            
            if phoneCallState == .requesting { // 当前为发起通话请求
                if callContent.action == .accept { // 主播端同意接通
                    startPhoneCall(call: callContent)
//                    if Analytics.Adjust.track(event: .first_call_in) {
//                        Analytics.log(event: "first_call_in", category: nil, name: roomInfo.room_id, value: nil)
//                    }
                } else if callContent.action == .reject { // 拒绝接通
                    phoneCallReject(call: callContent)
                }
            } else if phoneCallState == .calling { // 只处理通话过程中的 handup 消息
                if callContent.action == .hangup {
                    phoneCallHandUp(call: callContent)
                }
            } else {
                if callContent.action == .accept {
//                if roomInfo.multi_host && callContent.action == .accept {
                    startPhoneCall(call: callContent)
                }
                if callContent.action == .reject {// reject
                    phoneCallReject(call: callContent)
                }
                if callContent.action == .hangup {// drop
                    phoneCallHandUp(call: callContent)
                }
                if callContent.action == .invite {// 邀请上麦
                    callinInviteHandler()
                }
            }
        }
        
        func updatePhoneCallState(_ state: PhoneCallState, rejectType: PhoneCallRejectType = .none, call: Peer.CallMessage? = nil) {
            
            phoneCallState = state
            if state == .calling {
                mManager.rtcRole = .broadcaster
            } else {
                mManager.rtcRole = .audience
            }
            callingHandler(rejectType, call ?? Peer.CallMessage.empty(gid: group.gid))
        }
        
        func startPhoneCall(call: Peer.CallMessage? = nil) {
            updatePhoneCallState(.calling, call: call)
        }
        
        func phoneCallReject(call: Peer.CallMessage? = nil) {
            updatePhoneCallState(.readyForCall, rejectType: .host, call: call)
        }
        
        func phoneCallHandUp(call: Peer.CallMessage? = nil) {
            var rejectType: PhoneCallRejectType {
                guard call != nil else {
                    return .none
                }
                return .host
            }
            updatePhoneCallState(.readyForCall, rejectType: rejectType, call: call)
            // report
//            Request.Livecast.Live.Room.reportCallOut(uid: Int(call?.userInfo?.suid ?? 0), roomID: roomInfo.room_id, roomLiveID: roomInfo.room_live_id ?? "")
//                .subscribe()
//                .disposed(by: bag)
        }
        
        func phoneCallHangUpBySelf(_ rejectType: PhoneCallRejectType = .none) {
            updatePhoneCallState(.readyForCall, rejectType: rejectType)
//            sendCallSignal(isCallRequest: false)
            sendCall(action: .hangup)
        }
        
        func applyJoinGroup() -> Single<Bool> {
//            let hudRemoval = self.view.raft.show(.loading)
            return Request.applyToJoinGroup(group.gid)
                .do(onSuccess: { [weak self] _ in
                    guard let `self` = self else { return }
                    var info = self.groupInfo
                    info.userStatusInt = Entity.GroupInfo.UserStatus.applied.rawValue
                    self.groupInfoReplay.accept(info)
                })
//                .do(onDispose: {
////                    hudRemoval()
//                })
//                .subscribe(onSuccess: { [weak self] (_) in
//                    self?.bottomGradientView.isHidden = true
//                }, onError: { [weak self] (error) in
//                    self?.view.raft.autoShow(.text(error.msgOfError ?? R.string.localizable.amongChatUnknownError()))
//                })
//                .disposed(by: bag)
        }

    }
}
