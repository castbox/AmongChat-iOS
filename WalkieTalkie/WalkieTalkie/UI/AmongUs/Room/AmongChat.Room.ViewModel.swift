//
//  AmongChat.Room.ViewModel.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 17/12/20.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import SwifterSwift
import SwiftyUserDefaults
import AgoraRtcKit
import CastboxDebuger

fileprivate func cdPrint(_ message: Any) {
    Debug.info("[AmongChat.Room.ViewModel]-\(message)")
}

protocol SendMessageable {
    func sendText(message: String?)
}

protocol MessageDataSource: class {
    var messages: [ChatRoomMessage] { get set }
    var messageListUpdateEventHandler: CallBack? { get set }
}

extension AmongChat.Room {
    
    class ViewModel: AmongChat.BaseRoomViewModel {
        
        private var room: Entity.Room {
            roomReplay.value as! Entity.Room
        }
        
//        let roomInfoReplay: BehaviorRelay<Entity.RoomInfo>
//
//        private var roomInfo: Entity.RoomInfo {
//            roomInfoReplay.value
//        }
        
        let muteInfoReplay: BehaviorRelay<Entity.UserMuteInfo>
        
        var muteInfo: Entity.UserMuteInfo {
            set { muteInfoReplay.accept(newValue) }
            get { muteInfoReplay.value }
        }
        
        deinit {
            debugPrint("[DEINIT-\(NSStringFromClass(type(of: self)))]")
        }
        
        init(roomInfo: Entity.RoomInfo, source: ParentPageSource?) {
            if roomInfo.room.loginUserIsAdmin {
                Logger.Action.log(.admin_imp, categoryValue: roomInfo.room.topicId)
            }
            muteInfoReplay = BehaviorRelay(value: roomInfo.muteInfo ?? Entity.UserMuteInfo.empty())
            super.init(room: roomInfo.room, source: source)
            self.isSilentUser = roomInfo.isSilentValue
            startShowShareTimerIfNeed()
            update(roomInfo.room)
        }
        
        func requestLeaveChannel() -> Single<Bool> {
            Logger.Action.log(.room_leave_clk, categoryValue: room.topicId, nil, stayDuration)
            quitServices()
//            mManager.leaveChannel()
//            imViewModel.leaveChannel()
//            ViewModel.shared = nil
//            state = .disconnected
//            UIApplication.shared.isIdleTimerDisabled = false
            return Request.leave(with: room.roomId)
        }
        
        func changePublicType(_ completionHandler: CallBack? = nil) {
            let publicType: Entity.RoomPublicType = room.state == .private ? .public : .private
            var room = self.room
            room.state = publicType
            updateRoomInfo(room, completionHandler)
        }
        
        func update(nickName: String) {
            Request.updateRoom(topic: room.topicType, nickName: nickName, with: room.roomId)
                .subscribe { _ in
                    //refresh nick name
                    Settings.shared.updateProfile()
                } onError: { _ in
                    
                }
                .disposed(by: bag)
        }
        
        func update(notes: String) {
            var room = self.room
            room.note = notes
            updateRoomInfo(room)
        }
        
        func updateAmong(code: String, aera: Entity.AmongUsZone) {
            var room = self.room
            room.amongUsCode = code
            room.amongUsZone = aera
            updateRoomInfo(room)
        }
        
        //MARK: -- Override
        override func sendEmoji(_ emoji: Entity.EmojiItem) {
            guard let user = room.userList.first(where: { $0.uid == Settings.loginUserId }) else {
                return
            }
            super.sendEmoji(emoji)
        }
        
        override func addJoinMessage() {
            guard !isSilentUser else {
                return
            }
            super.addJoinMessage()
        }
        
        override func startShowShareTimerIfNeed() {
            guard !isSilentUser else {
                return
            }
            super.startShowShareTimerIfNeed()
        }
        
        override func delayToShowShareViewIfNeed() {
            guard !isSilentUser else {
                return
            }
            super.delayToShowShareViewIfNeed()
        }
        
        override func onReceiveChatRoom(crMessage: ChatRoomMessage) {
            
            if let message = crMessage as? ChatRoom.MuteMicMessage,
               message.user.uid == Settings.loginUserId {
                var muteInfo = self.muteInfo
                muteInfo.isMute = message.mute
                self.muteInfo = muteInfo
            } else if let message = crMessage as? ChatRoom.MuteImMessage,
                      message.user.uid == Settings.loginUserId {
                var muteInfo = self.muteInfo
                muteInfo.isMuteIm = message.mute
                self.muteInfo = muteInfo
            } else {
                super.onReceiveChatRoom(crMessage: crMessage)
            }
        }
        
        override func sendText(message: String?) {
            guard
                let message = message?.trimmed,
                !message.isEmpty,
                let user = room.userList.first(where: { $0.uid == Settings.loginUserId }) else {
                return
            }
            //检查是否 Im 被 mute
            guard !muteInfo.isMuteIm else {
                addImMutedMessage(user: user)
                return
            }
            super.sendText(message: message)
        }
        
        override func requestRoomInfo() {
            let roomId = room.roomId
            Request.roomInfo(with: roomId)
                .asObservable()
                .filterNilAndEmpty()
                .subscribe(onNext: { [weak self] room in
                    guard let `self` = self, self.state != .disconnected, roomId == self.room.roomId else {
                        return
                    }
                    self.update(room)
                })
                .disposed(by: bag)
        }
        
        func updateRoomInfo(_ room: Entity.Room, _ completionHandler: CallBack? = nil) {
            //update
            Request.updateRoomInfo(room: room)
                .catchErrorJustReturn(self.room)
                .asObservable()
                .subscribe(onNext: { [weak self] room in
                    completionHandler?()
                    guard let room = room else {
                        return
                    }
                    self?.update(room)
                })
                .disposed(by: bag)
        }
        
        func requestKick(_ users: [Int]) -> Single<Bool> {
            return Request.kick(users, roomId: room.roomId)
        }
        
        //快速切换房间
        func nextRoom(completionHandler: ((_ room: Entity.RoomInfo?, _ errorMessage: String?) -> Void)?) {
            //clear status
            let topicId = room.topicId
            requestLeaveChannel()
//                .do(onNext: { [weak self] result in
//                    cdPrint("nextRoom leave room: \(result)")
//                    let emptyRoom = Entity.Room(amongUsCode: nil, amongUsZone: nil, note: nil, roomId: "", userList: [], state: .public, topicId: topicId, topicName: "", rtcType: .agora, rtcBitRate: nil, coverUrl: nil)
//                    self?.update(emptyRoom)
//                    self?.messages = []
//                    self?.triggerMessageListReload()
//                })
                .flatMap { result -> Single<Entity.RoomInfo?> in
                    return Request.enterRoom(topicId: topicId, source: ParentPageSource(.room).key)
                }
                .subscribe(onSuccess: { [weak self] (room) in
                    // TODO: - 进入房间
                    guard let room = room else {
                        return
                    }
//                    self?.update(room)
                    completionHandler?(room, nil)
                }, onError: { error in
    //                completion()
                    cdPrint("error: \(error.localizedDescription)")
                    var msg: String {
                        if let error = error as? MsgError {
                            if let codeType = error.codeType, codeType == .needUpgrade {
                                return R.string.localizable.forceUpgradeTip()
                            }
                            return error.localizedDescription
                        } else {
                            return R.string.localizable.amongChatHomeEnterRoomFailed()
                        }
                    }
                    completionHandler?(nil, msg)
                })
                .disposed(by: bag)

        }
        
        func adminUnmuteMic(user uid: String) -> Single<Bool> {
            return Request.adminUnmuteMic(user: uid, roomId: room.roomId)
        }
        
        func adminUnmuteIm(user uid: String) -> Single<Bool> {
            return Request.adminUnmuteIm(user: uid, roomId: room.roomId)
        }
    }
    
}
