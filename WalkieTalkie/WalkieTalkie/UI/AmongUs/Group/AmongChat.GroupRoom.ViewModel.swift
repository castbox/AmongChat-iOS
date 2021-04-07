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
