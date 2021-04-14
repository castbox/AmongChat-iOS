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
    case hostReject
    case hostHungup
    case timeout
}

extension PhoneCallRejectType {
    var message: String? {
        switch self {
        case .hostReject:
            return R.string.localizable.groupRoomApplySeatRejectedTips()
        case .hostHungup:
            return R.string.localizable.groupRoomAudienceDropedTips()
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
        
        var group: Entity.Group {
            roomReplay.value as! Entity.Group
        }
        
        let groupInfoReplay: BehaviorRelay<Entity.GroupInfo>

        //听众列表
        let listenerListReplay = BehaviorRelay<[Entity.UserProfile]>(value: [])
        var listenerList = [Entity.UserProfile]() {
            didSet {
                listenerListReplay.accept(listenerList)
            }
        }
        
        let listenerCountReplay = BehaviorRelay<Int>(value: 0)
        var listenerCount: Int = 0 {
            didSet {
                listenerCountReplay.accept(listenerCount)
            }
        }
        
        var broadcaster: Entity.RoomUser {
            broadcasterReplay.value
        }
        
        let broadcasterReplay: BehaviorRelay<Entity.RoomUser>
        var updateListenerInfoHandler: () -> Void = { }
        
        init(groupInfo: Entity.GroupInfo, source: ParentPageSource?) {
            groupInfoReplay = BehaviorRelay(value: groupInfo)
            broadcasterReplay = BehaviorRelay(value: groupInfo.group.broadcaster.toRoomUser(with: -1))
            super.init(room: groupInfo.group, source: source)
            startScheduleEvent()
        }
        
        override func addJoinMessage() {
            guard !group.loginUserIsAdmin,
                  let user = Settings.shared.amongChatUserProfile.value?.toRoomUser(with: -1) else {
                return
            }
            let joinRoomMsg = ChatRoom.JoinRoomMessage(user: user, msgType: .joinRoom, isGroupRoomHostMsg: group.loginUserIsAdmin)
            addUIMessage(message: joinRoomMsg)
            onUserJoinedHandler?(joinRoomMsg.user)
        }

        
        override func sendText(message: String?) {
            guard
                let message = message?.trimmed,
                  !message.isEmpty else {
                return
            }
            let user: Entity.RoomUser
            if let seatUser = group.userList.first(where: { $0.uid == Settings.loginUserId })  {
                user = seatUser
            } else  {
                user = Settings.loginUserProfile!.toRoomUser(with: -1)
            }
//            Logger.Action.log(.room_send_message_success, categoryValue: room.topicId)
            let textMessage = ChatRoom.TextMessage(content: message, user: user, msgType: .text, isGroupRoomHostMsg: group.loginUserIsAdmin)
            imViewModel.sendText(message: textMessage)
            //append
            addUIMessage(message: textMessage)
        }
        
        override func update(_ room: RoomInfoable) {
            super.update(room)
            //同步
            let user = updateSeatUserStatus(broadcaster)
            if user != broadcaster {
                broadcasterReplay.accept(user)
            }
        }
        
        override func onReceiveChatRoom(crMessage: ChatRoomMessage) {
            cdPrint("onReceiveChatRoom- \(crMessage)")
//            guard state != .disconnected else {
//                return
//            }
            
            if var message = crMessage as? ChatRoom.TextMessage {
                message.isGroupRoomHostMsg = message.user.uid == group.uid
                addUIMessage(message: message)
            } else if var message = crMessage as? ChatRoom.GroupJoinRoomMessage,
                      message.user.uid != Settings.loginUserId {
                message.isGroupRoomHostMsg = message.user.uid == group.uid
                //add to entrance queue
                onUserJoinedHandler?(message.user)
                addUIMessage(message: message)
                if listenerList.count < 3 {
                    updateListenerList()
                } else {
                    listenerCount += 1
                }
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
                //remove
                listenerList(remove: message.user.uid)
                listenerCount -= 1
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
        
        override func roomBgImage() -> UIImage? {
            return UIImage(named: "icon_room_bg_topicId_group")
        }
        
        override func roomBgUrl() -> URL? {
            return group.bgUrl?.url
        }
        
        //MARK - Listener User list
        // 新听众进入
        func insertNewListener(_ userInfo: Entity.UserProfile?, forceRefresh: Bool = false) {
            
            guard let newListener = userInfo,
                newListener.uid != Int(group.uid) else { //不能将主播添加进
                    if forceRefresh {
                        updateRoomListenerInfoDisplay()
                    }
                    return
            }
            
//            if Knife.Auth.shared.isAnonymUser(Int64(newListener.suid)) {
//                return
//            }
            
            // ignore hose 去重 如果已经在队列里, 不用处理
            if listenerList.contains(where: { listener -> Bool in
                return listener.uid == newListener.uid
            }) {
                if forceRefresh {
                    updateRoomListenerInfoDisplay()
                }
                return
            }
            listenerList.append(newListener)
            updateRoomListenerInfoDisplay()
        }
        
        // 听众退出
        func listenerList(remove user: Entity.UserProfile?) {
            guard let newListener = user else {
                return
            }
            
            _ = listenerList.removeElement { listener -> Bool in
                return listener.uid == newListener.uid
            }
            updateRoomListenerInfoDisplay()
        }
        
        func listenerList(remove uid: Int?) {
            guard let suid = uid else { return }
            listenerList.removeElement { listener -> Bool in
                return listener.uid == suid
            }
            updateRoomListenerInfoDisplay()
        }
        
        func updateRoomListenerInfoDisplay() {
            // 刷新页面
            updateListenerInfoHandler()
        }
        
        func startScheduleEvent() {
            Observable<Int>.interval(.seconds(60), scheduler: SerialDispatchQueueScheduler(qos: .default))
                .startWith(0)
                .subscribe(onNext: { [weak self] _ in
                    self?.updateListenerList()
                })
                .disposed(by: bag)
        }
        
        func updateListenerList() {
            Request.groupLiveUserList(group.gid, skipMs: 0)
                .subscribe(onSuccess: { [weak self] data in
                    self?.listenerList = data.list
                    self?.listenerCount = data.count ?? data.list.count
                }, onError: { (error) in
                    cdPrint("followingList error: \(error.localizedDescription)")
                }).disposed(by: bag)
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
            room.note = nil
            room.robloxLink = nil
            updateInfo(group: room)
        }
        
        func update(notes: String) {
            var room = self.group
            if group.topicType == .roblox {
                room.robloxLink = notes
            } else {
                room.note = notes
            }
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
        
        func updateInfo(group: Entity.Group, _ completionHandler: CallBack? = nil) {
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
        
        func requestSeats(remove uid: Int) -> Single<Entity.Group?> {
            //用户下线，并且在麦上 通知服务端
            guard seatDataSource.contains(where: { $0.user?.uid == uid}) else {
                return Single.just(nil)
            }
            return Request.groupRoomSeatRemove(group.gid, uid: uid)
                .do(onSuccess: { [weak self] group in
                    guard let group = group else {
                        return
                    }
                    self?.update(group)
//                    self?.callInList(remove: uid)
                })
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

        override func onUserOnlineStateChanged(uid: UInt, isOnline: Bool) {
            //当主播
            if otherMutedUser.contains(uid) {
                otherMutedUser.remove(uid)
            }
            if mutedUser.contains(uid) {
                mutedUser.remove(uid)
            }
        }
        
        override func onUserStatusChanged(userId: UInt, muted: Bool) {
            //host mute
            if userId == group.uid {
                if muted {
                    otherMutedUser.insert(userId)
                } else {
                    otherMutedUser.remove(userId)
                }
                soundAnimationIndex.accept(-1)
            } else {
                super.onUserStatusChanged(userId: userId, muted: muted)
            }
        }
        
//        func onUserStatusChanged(userId: UInt, muted: Bool) {
        override func onAudioVolumeIndication(userId: UInt, volume: UInt) {
    //        cdPrint("userId: \(userId) volume: \(volume)")
            if group.loginUserIsAdmin, userId.int == group.uid {
                //-1 is host
                soundAnimationIndex.accept(-1)
            } else {
                super.onAudioVolumeIndication(userId: userId, volume: volume)
            }
        }
    }
    
}
