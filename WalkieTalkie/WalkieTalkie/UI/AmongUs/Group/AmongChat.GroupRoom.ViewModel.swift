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
    Debug.info("[AmongChat.GroupRoom.ViewModel]-\(message)")
}

enum PhoneCallState: Int {
    case preparing = -1
    case readyForCall
    case requesting
    case calling
    case invite
    case inviteReject
}

enum PhoneCallAction {
    case request //发起上麦请求
    case cancel //发起上麦请求后取消
    case rejectHostInvitation //主动拒绝主播邀请
}

enum PhoneCallRejectType {
    case none
    case host
    case timeout
}

extension PhoneCallRejectType {
    var message: String? {
        switch self {
//        case .host:
//            return R.string.localizable.toastCallinReject()
//        case .timeout:
//            return R.string.localizable.liveCallinBusy()
        default:
            return nil
        }
    }
}

extension AmongChat.GroupRoom {
        
    class ViewModel: AmongChat.BaseRoomViewModel {
        var callSwitch: Bool = true
        var groupInfo: Entity.GroupInfo {
            groupInfoReplay.value
        }
        
        var group: Entity.GroupRoom {
            roomReplay.value as! Entity.GroupRoom
        }
        
        let groupInfoReplay: BehaviorRelay<Entity.GroupInfo>
        
        init(groupInfo: Entity.GroupInfo, source: ParentPageSource?) {
            groupInfoReplay = BehaviorRelay(value: groupInfo)
            super.init(room: groupInfo.group, source: source)
        }
        
//        func updateSeatDataSource() {
//            for index in 0 ..< 10 {
//                //当前已有数据，重新填充信息
//                let item: AmongChat.Room.SeatItem
//                if let prevItem = seatDataSource[index] {
//                    item = prevItem
//                } else {
//                    item = AmongChat.Room.SeatItem(group.roomId)
//                }
//                if let user = group.userListMap[index] {
//                    item.user = user
//                }
//                seatDataSource[index] = item
//            }
//        }
        
        func requestOnSeat(at position: Int) {
            guard position >= 0 && position < 10,
                  let user = Settings.loginUserProfile?.toRoomUser(with: position),
                  let item = seatDataSource[position] else {
                return
            }
            //拿到改位置占位 item
            //将 item 更改为 loading 状态
            item.user = user
            item.callContent = Peer.CallMessage(action: .request, gid: group.gid, expireTime: 30, position: position, user: user)
            sendCall(action: .request, position: position)
            //update state
            seatDataSource[position] = item
        }
        
        //MARK: - override
        override func update(_ room: RoomInfoable) {
            super.update(room)
            //
            updateSeatDataSource()
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
            } else if crMessage.msgType == .emoji {
                messageHandler?(crMessage)
            }
//            else if message.messageType == .call { // Call 电话状态
//                self.callMessageHandler(callContent: content as? CallContent)
//            }
        }
        
        override func onReceivePeer(message: PeerMessage) {
            //当前为 host, 处理申请
            
            
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
            }
        }
        
        //MARK: -- Request
        override func requestRoomInfo() {
//            let roomId = room.roomId
//            Request.roomInfo(with: roomId)
//                .asObservable()
//                .filterNilAndEmpty()
//                .subscribe(onNext: { [weak self] room in
//                    guard let `self` = self, self.state != .disconnected, roomId == self.room.roomId else {
//                        return
//                    }
//                    self.update(room)
//                })
//                .disposed(by: bag)
        }
        
        override func roomBgImage() -> UIImage? {
            return UIImage(named: "icon_room_bg_topicId_group")
        }
        
        override func roomBgUrl() -> URL? {
            return group.bgUrl?.url
        }
        
        //MARK: -
        
        var phoneCallState = PhoneCallState.preparing

        var callinRequestTimerDispose: Disposable?
        
        var callingHandler: (PhoneCallRejectType, Peer.CallMessage) -> Void = { _, _ in }
        
        var callinInviteHandler: () -> Void = { }
        
        //MARK: - For Auidiance
        func sendMessage(call action: Peer.CallMessage.Action, expired: Int64, extra: String, position: Int = 0) {
            //user
            let content = Peer.CallMessage(action: action, gid: group.gid, expireTime: expired, extra: extra, position: position ?? 0, user: Settings.loginUserProfile!.toRoomUser(with: position))
            imViewModel.sendPeer(message: content, to: group.broadcaster.uid)
        }
        
        // MARK: - CALL
        func sendCall(action: Peer.CallMessage.Action, position: Int = 0) {
            cdPrint("sendCall action: \(action)")
            switch action {
            case .request:
                phoneCallState = .requesting
                sendMessage(call: action, expired: 30, extra: "", position: position)
//                LiveEngine.shared.sendCallSignal(action: .request, roomInfo: roomInfo, expired: 30, extra: "", position: position)
                
                //30 秒倒计时后自动挂断
                let timer = Observable<Int>
                    .timer(.seconds(30), scheduler: MainScheduler.instance)
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
                sendMessage(call: action, expired: 30, extra: "", position: position)
//                LiveEngine.shared.sendCallSignal(action: .invite_reject, roomInfo: roomInfo, expired: 30, extra: "", position: position)

            default:
                // 直接断开
                phoneCallState = PhoneCallState.readyForCall
                sendMessage(call: .hangup, expired: 30, extra: "", position: position)
//                LiveEngine.shared.sendCallSignal(action: .hangup, roomInfo: roomInfo, expired: 30, extra: "", position: position)

            }
//            if isCallRequest { // 准备连接
//                cdPrint("sendSingnal:listener:dataManager")
//                phoneCallState = .requesting
//                LiveEngine.shared.sendCallSignal(action: .request, roomInfo: roomInfo, expired: 30, extra: "", position: position)
//                let timer = Observable<Int>
//                    .timer(.seconds(30), scheduler: MainScheduler.instance)
//                callinRequestTimerDispose?.dispose()
//                callinRequestTimerDispose = nil
//                callinRequestTimerDispose = timer
//                    .subscribe(onNext: { [weak self] _ in
//                        guard let `self` = self else { return }
//                        if self.phoneCallState == .requesting {
//                            self.phoneCallHangUpBySelf(.timeout)
//                        }
//                    })
//                callinRequestTimerDispose?.disposed(by: bag)
//            } else {
//                // invite reject
//                if isInviteReject {
//                    callinRequestTimerDispose?.dispose()
//                    callinRequestTimerDispose = nil
//                    phoneCallState = PhoneCallState.readyForCall
//                    LiveEngine.shared.sendCallSignal(action: .invite_reject, roomInfo: roomInfo, expired: 30, extra: "", position: position)
//                    return
//                }
//                // 直接断开
//                phoneCallState = PhoneCallState.readyForCall
//                LiveEngine.shared.sendCallSignal(action: .hangup, roomInfo: roomInfo, expired: 30, extra: "", position: position)
//            }
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
        
        func callMessageHandler(callContent: Peer.CallMessage?) {
            
            guard let callContent = callContent else {
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
                mManager.updateRole(.broadcaster)
//                mManager.updateRole(isPublisher: true)
            } else {
                mManager.updateRole(.audience)
//                mManager.updateRole(isPublisher: false)
            }
//            callingHandler(rejectType, call ?? Peer.CallMessage())
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

        
        func updateAmong(code: String, aera: Entity.AmongUsZone) {
            var room = group
            room.amongUsCode = code
            room.amongUsZone = aera
            updateInfo(group: room)
        }
        
        func update(topicId: String) {
            var room = self.group
            room.topicId = topicId
            updateInfo(group: room)
        }
        
        func update(notes: String) {
            var room = self.group
            room.note = notes
            updateInfo(group: room)
        }
        
        func update(nickName: String) {
            Request.updateNickName(nickName, groupId: group.gid, topic: group.topicType)
                .subscribe { _ in
                    //refresh nick name
                    Settings.shared.updateProfile()
                } onError: { _ in
                    
                }
                .disposed(by: bag)
        }
        
        func updateInfo(group: Entity.GroupRoom, _ completionHandler: CallBack? = nil) {
            //update
            Request.update(group)
                .catchErrorJustReturn(self.group)
                .asObservable()
                .subscribe(onNext: { [weak self] group in
                    completionHandler?()
                    guard let room = group else {
                        return
                    }
                    self?.update(room)
                })
                .disposed(by: bag)
        }

                
        func requestLeaveChannel() -> Single<Bool> {
//            Logger.Action.log(.room_leave_clk, categoryValue: room.topicId, nil, stayDuration)
//            mManager.leaveChannel()
//            imViewModel.leaveChannel()
            quitServices()
//            ViewModel.shared = nil
//            state = .disconnected
//            UIApplication.shared.isIdleTimerDisabled = false
            //
            if group.loginUserIsAdmin {
                return Request.stopChannel(groupId: group.gid)
            }
            return Request.leaveChannel(groupId: group.gid)
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
