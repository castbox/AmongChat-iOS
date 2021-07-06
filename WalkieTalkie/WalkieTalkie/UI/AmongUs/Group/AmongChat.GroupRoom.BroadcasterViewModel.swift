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
        
        deinit {
            cdPrint("AmongChat.GroupRoom.BroadcasterViewModel-Deinit")
        }
        
        //MARK: - override
        override func onReceiveChatRoom(crMessage: ChatRoomMessage) {
            if let message = crMessage as? ChatRoom.KickOutMessage,
               message.user.uid != Settings.loginUserId,
               group.rtcType == .agora {
                callInList(remove: message.user.uid)
            } else if let message = crMessage as? ChatRoom.GroupLeaveRoomMessage {
                //
                callInList(remove: message.user.uid)
            }
            super.onReceiveChatRoom(crMessage: crMessage)
        }
        
        override func onReceivePeer(message: PeerMessage) {
            if message.msgType == .groupRoomCall { // Call 电话状态
                onReceiveCall(message: message as? Peer.CallMessage)
            }
        }
        
        override func onUserOnlineStateChanged(uid: UInt, isOnline: Bool) {
            super.onUserOnlineStateChanged(uid: uid, isOnline: isOnline)
//            guard !isOnline else {
//                return
//            }
//            requestSeats(remove: uid)
//                .subscribe()
//                .disposed(by: bag)
        }
        
        //MARK: -
        
        //MARK: - For host
        func callInUser(for uid: Int) -> Entity.CallInUser? {
            //
            if let user = seatDataSource.first(where: { $0.user?.uid == uid }) {
                return user.toCallInUser()
            } else if let info = callInList.first(where: { $0.user.uid == uid }) {
                return info
            }
            return nil
        }
        
        func callInList(add message: Peer.CallMessage) {
            var callInUserInfo = Entity.CallInUser(message: message)
            guard !callInList.contains(where: { $0.user.uid == callInUserInfo.user.uid }) else {
                return
            }
            //主播发起邀请后，用户接受邀请
            if message.action == .accept {
                let timeNow = Date(timeIntervalSinceNow: 0)
                callInUserInfo.startTimeStamp = timeNow.timeIntervalSince1970
            }
            callInList.insert(callInUserInfo, at: 0)
            //            append(callInUserInfo)
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
                //兼容老版本，自由麦开启时接收到callin直接上麦。
                if group.micQueueEnabled {
                    callInList(add: message)
                } else {
                    let user = Entity.CallInUser(message: message, startTimeStamp: Date().timeIntervalSince1970 * 1000)
                    requestGroupRoomSeatAdd(for: user)
                        .subscribe(onSuccess: { [weak self] _ in
                            self?.sendCallSignal(isAccept: true, user)
                        })
                        .disposed(by: bag)
                }
                
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
        
        func requestGroupRoomSeatAdd(for user: Entity.CallInUser) -> Single<Entity.Group?> {
            return Request.groupRoomSeatAdd(group.gid, uid: user.uid, in: user.message.position)
                .do(onSuccess: { [weak self] group in
                    guard let group = group else {
                        return
                    }
                    self?.update(group)
                })
        }
        
        // MARK: - CALL - 1request 2accept 3reject 4handup 5invite 6reject
        func sendCallSignal(isAccept: Bool, _ callInUser: Entity.CallInUser) {
            //            guard let callInUser = callInUser(for: user.uid) else {
            //                return
            //            }
            if isAccept { // 准备连接
                // 判断call-in限制数量
//                var callinHostsCount = callInList.filter { $0.message.action == 2 }.count
//                // 如果callin列表数据没有值 则使用麦位数据
//                if callinHostsCount == 0 {
//                    callinHostsCount = group.userList.filter { $0.uid != 0 }.count //
//                }
//                guard callinHostsCount <= 10 else {
//                    return
//                }
                //可以接受，找到 callin 列表中当前message
//                var message = callInUser.message
//                message.action = .accept
//                imViewModel.sendPeer(message: message, to: callInUser.uid)
                //remove
                callInList(remove: callInUser.uid)
                callInListHandler()
            } else {
                rejectCall(uid: callInUser.uid)
            }
        }
        
        func rejectCall(uid: Int) {
            // 直接断开
            guard let callInUser = callInUser(for: uid) else {
                return
            }
            
            var message = callInUser.message
            //未接通时为 reject，接通后为 reject
            message.action = message.action == .request ? .reject : .hangup
            imViewModel.sendPeer(message: message, to: uid)
            //remove
            callInList(remove: uid)
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
