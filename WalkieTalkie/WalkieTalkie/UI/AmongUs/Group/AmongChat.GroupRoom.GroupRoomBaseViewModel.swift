//
//  AmongChat.GroupRoom.BaseViewModel.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 09/04/21.
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
    Debug.info("[AmongChat.GroupRoom.BaseRoomViewModel]-\(message)")
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
    class BaseViewModel: AmongChat.BaseRoomViewModel {
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
        
//        override func onReceivePeer(message: PeerMessage) {
//            //当前为 host, 处理申请
//
//
//            //非 Host
//            if let applyMessage = message as? Peer.GroupApplyMessage,
//               applyMessage.gid == group.gid {
//                let status: Entity.GroupInfo.UserStatus
//                switch applyMessage.action {
//                case .accept:
//                    status = .memeber
//                case .reject:
//                    status = .none
//                case .request:
//                    status = .applied
//                }
//                var info = self.groupInfo
//                info.userStatusInt = status.rawValue
//                self.groupInfoReplay.accept(info)
//            }
//        }
        
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
        
//        func applyJoinGroup() -> Single<Bool> {
//            return Request.applyToJoinGroup(group.gid)
//                .do(onSuccess: { [weak self] _ in
//                    guard let `self` = self else { return }
//                    var info = self.groupInfo
//                    info.userStatusInt = Entity.GroupInfo.UserStatus.applied.rawValue
//                    self.groupInfoReplay.accept(info)
//                })
//        }

    }
    
}
