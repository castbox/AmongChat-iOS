//
//  AmongChat.GroupRoom.HostViewModel.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 08/04/21.
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
    
    
    class HostViewModel: AmongChat.BaseRoomViewModel {
        var callSwitch: Bool = true
        //host call in list
//        var callInList: [Entity.RoomUser] = []
        
        
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
        
        var callInList: [Entity.CallInItem] = []
        
        //MARK: - For host
        // MARK: - CALL - 1request 2accept 3reject 4handup 5invite 6reject
//        func hostSendCallSignal(isAccept: Bool, user: Entity.UserProfile) {
//            if isAccept { // 准备连接
//                // 判断call-in限制数量
//                var callinHostsCount = callInList.filter { $0.message.action == 2 }.count
//                // 如果callin列表数据没有值 则使用麦位数据
//                if callinHostsCount == 0 {
//                    callinHostsCount = group.userList.filter { $0.uid != 0 }.count //
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
