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
    
//    enum EndRoomAction {
//        case accountKicked
//        case disconnected
//        case normalClose //true if enter a closed room for listener
//        case tokenError
//        case forbidden //被封
//        //listener
//        case enterClosedRoom
//        case kickout(ChatRoom.KickOutMessage.Role) //被踢出
//        case beBlocked
//    }
    
    
    class ViewModel: AmongChat.BaseRoomViewModel {
        var callSwitch: Bool = true
        //host call in list
        var callInList: [Entity.RoomUser] = []
        
        
        var group: Entity.GroupRoom {
            roomReplay.value as! Entity.GroupRoom
        }
        
        
//        override init(room: RoomInfoable, source: ParentPageSource?) {
//            
//        }
        
//        init(room: RoomInfoable, source: ParentPageSource?) {
//
//        }
        
        //MARK: - override
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
        
        override func roomBgUrl() -> URL? {
            return group.bgUrl?.url
        }
        
        //MARK: -
        
        var phoneCallState = PhoneCallState.preparing

        var callinRequestTimerDispose: Disposable?
        
        var callingHandler: (PhoneCallRejectType, Peer.CallMessage) -> Void = { _, _ in }
        
        var callinInviteHandler: () -> Void = { }
        //MARK: - For host
        // MARK: - CALL - 1request 2accept 3reject 4handup 5invite 6reject
//        func sendCallSignal(isAccept: Bool, userInfo: LVEntity.CallInUserInfo) {
//            if isAccept { // 准备连接
//                // 判断call-in限制数量
//                var callinHostsCount = callInList.filter { $0.action == 2 }.count
//                // 如果callin列表数据没有值 则使用麦位数据
//                if callinHostsCount == 0 {
//                    callinHostsCount = seats.itemsRelay.value.filter { $0.userInfo.suid != 0 }.count
//                }
//                guard callinHostsCount <= 5 || (roomInfo.type == .dating && callinHostsCount <= 6) else {
//                    return
//                }
//
//                self.seats.callin(userInfo)
//
//                /// FIXME: - 逻辑全部移到seat里面
//                if let targetUserInfo = LVEntity.BaseUserInfo.copyFrom(userInfo: userInfo) {
//
//                    let content = CallContent()
//                    content.action = .accept
//                    content.room_id = roomInfo.room_id
//                    content.expire_time = Int64(userInfo.expired ?? 30)
//                    content.extra = userInfo.extra ?? ""
//                    content.position = userInfo.position
//                    LiveEngine.shared.sendSignal(dest: targetUserInfo, content: content)
//                    // report
//                    Request.Livecast.Live.Room.reportCallIn(uid: userInfo.suid, roomID: roomInfo.room_id, roomLiveID: roomInfo.room_live_id ?? "")
//                        .subscribe(onNext: {}).disposed(by: bag)
//                    // 更新action状态
//                    userInfo.action = CallContent.Action.accept.rawValue
//                    callInListHandler()
//                }
//            } else if let targetUserInfo = LVEntity.BaseUserInfo.copyFrom(userInfo: userInfo) {
//                let content = CallContent()
//                content.action = .hangup
//                content.room_id = roomInfo.room_id
//                content.expire_time = Int64(userInfo.expired ?? 30)
//                content.extra = userInfo.extra ?? ""
//                content.position = userInfo.position
//                LiveEngine.shared.sendSignal(dest: targetUserInfo, content: content)
//                // report
//                Request.Livecast.Live.Room.reportCallOut(uid: userInfo.suid, roomID: roomInfo.room_id, roomLiveID: roomInfo.room_live_id ?? "")
//                    .observeOn(MainScheduler.asyncInstance)
//                    .subscribe()
//                    .disposed(by: bag)
//                // 直接断开
//                deleteCallInList(userInfo.suid)
//            } else {
//
//            }
//        }
//
//        func rejestCall(userInfo: LVEntity.CallInUserInfo) {
//            // 直接断开
//            deleteCallInList(userInfo.suid)
//
//            if let targetUserInfo = LVEntity.BaseUserInfo.copyFrom(userInfo: userInfo) {
//                let content = CallContent()
//                /// FIXME: 通话成功之后挂断还是action 3 吗
//                content.action = .reject
//                content.room_id = roomInfo.room_id
//                content.expire_time = Int64(userInfo.expired ?? 30)
//                content.extra = userInfo.extra ?? ""
//                LiveEngine.shared.sendSignal(dest: targetUserInfo, content: content)
//                /// FIXED: - 操作原子性问题
//                callInListHandler()
//            } else {
//                cdAssertFailure("targetUserInfo == nil")
//            }
//        }
        
        //MARK: - For Auidiance
        func sendMessage(call action: Peer.CallMessage.Action, expired: Int64, extra: String, position: Int? = nil) {
            //user
            let content = Peer.CallMessage(action: action, gid: group.gid, expireTime: expired, extra: extra, position: position ?? 0, user: Settings.loginUserProfile!)
            imViewModel.sendPeer(message: content, to: group.broadcaster.uid)
        }
        
        // MARK: - CALL
        func sendCall(action: Peer.CallMessage.Action, position: Int? = nil) {
            switch action {
            case .request:
                cdPrint("sendSingnal:listener:dataManager")
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

    }
}
