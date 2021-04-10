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
    Debug.info("[AmongChat.GroupRoom.BroadcasterViewModel]-\(message)")
}

extension AmongChat.GroupRoom {
    
    class BroadcasterViewModel: BaseViewModel {
        var callSwitch: Bool = true
        
        var phoneCallState = PhoneCallState.preparing
        
        var callinRequestTimerDispose: Disposable?
        
        private var callInList: [Entity.CallInUser] = [] {
            didSet {
                callInListReplay.accept(callInList)
            }
        }
        
        let callInListReplay = BehaviorRelay<[Entity.CallInUser]>(value: [])
        
        var callInListHandler: () -> Void = {}
        
        var callInTipHandler: (Entity.CallInUser, Bool) -> Void = { _, _ in }
        
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
                callInList(remove: message.user.uid)
            } else if let message = crMessage as? ChatRoom.GroupLeaveRoomMessage {
                otherMutedUser.remove(message.user.uid.uInt)
                callInList(remove: message.user.uid)
            } else if crMessage.msgType == .emoji {
                messageHandler?(crMessage)
            }
            //            else if message.messageType == .call { // Call 电话状态
            //                self.callMessageHandler(callContent: content as? CallContent)
            //            }
        }
        
        override func onReceivePeer(message: PeerMessage) {
            if message.msgType == .groupRoomCall { // Call 电话状态
                onReceiveCall(message: message as? Peer.CallMessage)
            }
        }
        
        override func onUserOnlineStateChanged(uid: UInt, isOnline: Bool) {
            //用户下线，并且在麦上 通知服务端
            if !isOnline, callInUser(for: uid.int) != nil {
                //
                Request.groupRoomSeatRemove(group.gid, uid: uid.int)
                callInList(remove: uid.int)
            }
        }
        
        //MARK: -
        
        //MARK: - For host
        func callInUser(for uid: Int) -> Entity.CallInUser? {
            guard let info = callInList.first(where: { $0.user.uid == uid }) else {
                return nil
            }
            return info
        }
        
        //        func callInList(add userInfo: LiveUserInfo?, action: Peer.CallMessage.Action, extra: String, expire_time: Int64, position: Int, autoShowTips: Bool = true) {
        func callInList(add message: Peer.CallMessage) {
            var callInUserInfo = Entity.CallInUser(message: message)
            
//            if callInList.contains(where: { item -> Bool in
//                if item.user.uid == callInUserInfo.user.uid {
//                    //同步 extra 信息
//                    item.message.extra = callInUserInfo.message.extra
//                    return true
//                }
//                return false
//            }) {
//                return
//            }
            guard !callInList.contains(where: { $0.user.uid == callInUserInfo.user.uid }) else {
                return
            }
            //主播发起邀请后，用户接受邀请
            if message.action == .accept {
                let timeNow = Date(timeIntervalSinceNow: 0)
                callInUserInfo.startTimeStamp = timeNow.timeIntervalSince1970
            }
            callInList.append(callInUserInfo)
            callInListHandler()
//            if autoShowTips {
//                callInTipHandler(userInfo, true)
//            }
        }
        
        func onReceiveCall(message: Peer.CallMessage?) {
            
            guard let message = message else {
                return
            }
            if message.action == .request { // 请求接通
                callInList(add: message)
            } else if message.action == .hangup { // 挂断
                //用户主动取消
                if callInList.count > 0 {
                    callInList(remove: message.user.uid)
                    return
                }
            } else if message.action == .invite_reject {
//                let message = NSLocalizedString("%@ can't join right now", comment: "").replacingOccurrences(of: "%@", with: callContent.userInfo?.name ?? "")
//                DispatchQueue.main.async {
//                    Toast.showToast(alertType: .operationComplete, message: message)
//                }
                return
            } else {
                cdPrint("other action: \(message)")
            }
        }
        
        func requestGroupRoomSeatAdd(for user: Entity.CallInUser) -> Single<Bool> {
            return Request.groupRoomSeatAdd(group.gid, uid: user.uid, in: user.message.position)
        }
        
        // MARK: - CALL - 1request 2accept 3reject 4handup 5invite 6reject
        func sendCallSignal(isAccept: Bool, _ callInUser: Entity.CallInUser) {
//            guard let callInUser = callInUser(for: user.uid) else {
//                return
//            }
            if isAccept { // 准备连接
                // 判断call-in限制数量
                var callinHostsCount = callInList.filter { $0.message.action == 2 }.count
                // 如果callin列表数据没有值 则使用麦位数据
                if callinHostsCount == 0 {
                    callinHostsCount = group.userList.filter { $0.uid != 0 }.count //
                }
                guard callinHostsCount <= 10 else {
                    return
                }
                //可以接受，找到 callin 列表中当前message
                
                var message = callInUser.message
                message.action = .accept
                imViewModel.sendPeer(message: message, to: callInUser.uid)
                //remove
                callInList(remove: callInUser.uid)
                callInListHandler()
            } else {
//                var message = callInUser.message
//                message.action = .reject
//                imViewModel.sendPeer(message: message, to: user.uid)
//                //remove
//                callInList(remove: user.uid)
//                callInListHandler()
                rejectCall(user: callInUser)
            }
        }
        
        //
        func rejectCall(user: Entity.CallInUser) {
            // 直接断开
            guard let callInUser = callInUser(for: user.uid) else {
                return
            }
            
            var message = callInUser.message
            message.action = .reject
            imViewModel.sendPeer(message: message, to: user.uid)
            //remove
            callInList(remove: user.uid)
            callInListHandler()
        }
        
        func callInList(remove uid: Int?) {
            guard let uid = uid else {
                return
            }
            callInList.removeElement { (user) -> Bool in
                if user.uid == uid {
                    return true
                }
                return false
            }
            //移除麦位信息
//            seats.dropSeat(by: uid)
            callInListHandler()
        }
        
    }
}
