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
            if group.userList.contains(where: { $0.uid == Settings.loginUserId }) {
                if mManager.rtcRole == .audience {
                    //update message
                    var message = seatDataSource.first(where: { $0.callContent.user.uid == Settings.loginUserId })?.callContent ?? Peer.CallMessage.empty(gid: group.gid)
                    message.action = .accept
                    updatePhoneCallState(.calling, rejectType: .none, call: message)
                }
            }
            else if mManager.rtcRole == .broadcaster { //
                updatePhoneCallState(.readyForCall)
            }
        }
        
        override func onReceiveChatRoom(crMessage: ChatRoomMessage) {
            cdPrint("onReceiveChatRoom- \(crMessage)")
            guard state != .disconnected else {
                return
            }
            if let message = crMessage as? ChatRoom.GroupRoomEndMessage,
                      message.gid == group.gid {
                endRoomHandler?(.normalClose)
            } else {
                super.onReceiveChatRoom(crMessage: crMessage)
            }
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
                    //show toast
                    UIApplication.topViewController()?.view.raft.autoShow(.text(R.string.localizable.groupApplyRejectTips()))
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
        
        override func roomBgImage() -> UIImage? {
            return UIImage(named: "icon_room_bg_topicId_group")
        }
        
        override func roomBgUrl() -> URL? {
            return group.bgUrl?.url
        }
        
        //MARK: - For Auidiance
        
        func requestOnSeat(at position: Int) {
            guard position >= 0 && position < 10,
                  let user = Settings.loginUserProfile,
                  let item = seatDataSource.safe(position) else {
                return
            }
            //拿到改位置占位 item
            //转化为 服务端 index
            //将 item 更改为 loading 状态
            item.callContent = Peer.CallMessage(action: .request, gid: group.gid, expireTime: 30, position: position + 1, user: user)
            item.user = user.toRoomUser(with: item.callContent.position)
            sendCall(action: .request, position: item.callContent.position)
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
            for (index, item) in seatDataSource.enumerated() {
                if item.user?.uid == uid  {
                    return index
                }
            }
            return nil
        }
        
        func sendMessage(call action: Peer.CallMessage.Action, position: Int = 0) {
            //user
            let content = Peer.CallMessage(action: action, gid: group.gid, position: position, user: Settings.loginUserProfile!)
            imViewModel.sendPeer(message: content, to: group.broadcaster.uid)
        }
        
        // MARK: - CALL
        func sendCall(action: Peer.CallMessage.Action, position: Int = 0) {
            cdPrint("sendCall action: \(action)")
            switch action {
            case .request:
                phoneCallState = .requesting
                sendMessage(call: action, position: position)
                //30 秒倒计时后自动挂断
                let timer = Observable<Int>
                    .timer(.seconds(Peer.CallMessage.defaultExpireTime), scheduler: MainScheduler.instance)
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
                sendMessage(call: action, position: position)
//                LiveEngine.shared.sendCallSignal(action: .invite_reject, roomInfo: roomInfo, expired: 30, extra: "", position: position)

            default:
                // 直接断开
                phoneCallState = PhoneCallState.readyForCall
                sendMessage(call: .hangup, position: position)
//                LiveEngine.shared.sendCallSignal(action: .hangup, roomInfo: roomInfo, expired: 30, extra: "", position: position)

            }
        }
        
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
            cdPrint("callcontent: \(callContent)) state: \(phoneCallState.rawValue)")
            
            if phoneCallState == .requesting { // 当前为发起通话请求
                if callContent.action == .accept { // 主播端同意接通
                    startPhoneCall(call: callContent)
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
            updatePhoneCallState(.readyForCall, rejectType: .hostReject, call: call)
        }
        
        func phoneCallHandUp(call: Peer.CallMessage? = nil) {
            var rejectType: PhoneCallRejectType {
                guard let call = call else {
                    return .none
                }
                if call.action == .hangup {
                    return .hostHungup
                }
                return .hostReject
            }
            updatePhoneCallState(.readyForCall, rejectType: rejectType, call: call)
        }
        
        func phoneCallHangUpBySelf(_ rejectType: PhoneCallRejectType = .none) {
            updatePhoneCallState(.readyForCall, rejectType: rejectType)
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
        }

    }
}
