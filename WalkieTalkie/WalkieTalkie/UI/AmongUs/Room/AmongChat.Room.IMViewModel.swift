//
//  AmongChat.Room.IMViewModel.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/12/8.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import AgoraRtmKit
import CastboxDebuger

fileprivate func cdPrint(_ message: Any) {
    Debug.info("[IMViewModel]-\(message)")
}


extension AmongChat.Room {
    
    class IMViewModel {
        
        private typealias MessageViewModel = AmongChat.Room.MessageViewModel
        
        private let channelId: String
        private let imManager: IMManager
        private let messageRelay = BehaviorRelay<ChatRoomMessage?>(value: nil)
        
        private let bag = DisposeBag()
        
        var messagesObservable: Observable<ChatRoomMessage> {
            return messageRelay.asObservable()
                .filterNilAndEmpty()
        }
        
        var imReadySignal: Observable<Bool> {
            return imManager.joinedChannelSignal
        }
        
        init(with channelId: String) {
            self.channelId = channelId
            self.imManager = AmongChat.Room.IMManager(with: channelId)
            bindEvents()
        }
                
    }
    
}

extension AmongChat.Room.IMViewModel {
        
//    private func appendNewMessage(_ message: ChatRoomMessage) {
//
////        let userViewModel: ChannelUserViewModel
////
////        if let user = ChannelUserListViewModel.shared.channelUserViewModelList.first(where: { "\($0.channelUser.uid)" == user.userId }) {
////            userViewModel = user
////        } else {
////            userViewModel = ChannelUserViewModel(with: ChannelUser.randomUser(uid: UInt(user.userId) ?? 0), firestoreUser: nil)
////        }
////
////        let messageVM = MessageViewModel(user: userViewModel, text: message.text)
//
//        var messages = messageRelay.value
//        messages.append(message)
//        messageRelay.accept(messages)
//    }
    
    private func bindEvents() {
        
        imManager.newMessageObservable
            .observeOn(SerialDispatchQueueScheduler(qos: .default))
            .map { (message, member) -> ChatRoomMessage? in
                cdPrint("member: \(member.channelId) \(member.userId) \ntext: \(message.text)")
                guard message.type == .text,
                      let json = message.text.jsonObject(),
                      let messageType = json["message_type"] as? String,
                      let type = ChatRoom.MessageType(rawValue: messageType) else {
//                    let structType = ChatRoom.MessageType.structMap[type]
                    return nil
                }
//                let item = try JSONDecoder().decodeAnyData(structType, from: json)
                var item: ChatRoomMessage?
                decoderCatcher {
                    switch type {
                    case .text:
                        item = try JSONDecoder().decodeAnyData(ChatRoom.TextMessage.self, from: json) as ChatRoomMessage
//                    case .baseInfo:
//                        item = try JSONDecoder().decodeAnyData(ChatRoom.RoomBaseMessage.self, from: json) as ChatRoomMessage
                    case .joinRoom:
                        item = try JSONDecoder().decodeAnyData(ChatRoom.JoinRoomMessage.self, from: json) as ChatRoomMessage
                    case .leaveRoom:
                        item = try JSONDecoder().decodeAnyData(ChatRoom.LeaveRoomMessage.self, from: json) as ChatRoomMessage
                    case .kickoutRoom:
                        item = try JSONDecoder().decodeAnyData(ChatRoom.KickOutMessage.self, from: json) as ChatRoomMessage
                    case .roomInfo:
                        item = try JSONDecoder().decodeAnyData(ChatRoom.RoomInfoMessage.self, from: json) as ChatRoomMessage
                    case .system:
                        item = try JSONDecoder().decodeAnyData(ChatRoom.SystemMessage.self, from: json) as ChatRoomMessage
                        
                    }
                }
                return item
            }
            .filterNil()
            .debug("[newMessageObservable]", trimOutput: false)
            .observeOn(MainScheduler.asyncInstance)
//            .subscribe(onNext: { [weak self] message in
//                self?.appendNewMessage(message)
//            })
            .bind(to: messageRelay)
            .disposed(by: bag)
    }
    
//    func sendText(message: String, roomUser: Entity.Roo) {
//        //find current user
//        let textMessage = ChatRoom.TextMessage(text: message, user: Entity.RoomUser(uid: <#T##String?#>, name: <#T##String?#>, pictureUrl: <#T##String#>, seatNo: <#T##Int#>, status: <#T##Entity.RoomUser.Status?#>, isMuted: <#T##Bool?#>, robloxName: <#T##String?#>), messageType: <#T##ChatRoom.MessageType#>)
//    }
    
    func sendText(message: ChatRoomMessage) {
        guard let string = message.asString else {
            return
        }
        imManager.send(message: string)
            .catchErrorJustReturn(false)
            .filter { _ -> Bool in
                return message.msgType == .text
            }
            .subscribe(onSuccess: { [weak self] (success) in
                guard let `self` = self,
                    success else { return }
                
//                let msg = AgoraRtmMessage(text: text)
//                let user = AgoraRtmMember()
//                user.userId = "\(Constants.sUserId)"
//                user.channelId = self.channelId
//
//                self.appendNewMessage(message)
            })
            .disposed(by: bag)
        
    }
        
}

extension AmongChat.Room {
    
    struct MessageViewModel {
        let user: ChannelUserViewModel
        let text: String
    }
    
}

struct ChatRoom {
    
}

protocol ChatRoomMessageable {
    var msgType: ChatRoom.MessageType { get }
}

typealias ChatRoomMessage = ChatRoomMessageable & Codable

extension ChatRoom {
    enum MessageType: String, Codable {
        case text = "AC:Chatroom:Text"
        case roomInfo = "AC:Chatroom:RoomInfo"
        case joinRoom = "AC:Chatroom:Join"
        case leaveRoom = "AC:Chatroom:Leave"
        case kickoutRoom = "AC:Chatroom:Kick"
        case system = "AC:Chatroom:SystemText"
    }
    
    struct TextMessage: ChatRoomMessage {
        let content: String
        let user: Entity.RoomUser
        let msgType: MessageType
        
        private enum CodingKeys: String, CodingKey {
            case content
            case user
            case msgType = "message_type"
        }
    }

    struct RoomInfoMessage: ChatRoomMessage {
        let room: Entity.Room
        let msgType: MessageType
        
        private enum CodingKeys: String, CodingKey {
            case room
            case msgType = "message_type"
        }
    }

    struct JoinRoomMessage: ChatRoomMessage {
        let room: Entity.Room
        let msgType: MessageType
        
        private enum CodingKeys: String, CodingKey {
            case room
            case msgType = "message_type"
        }
    }
    
    struct LeaveRoomMessage: ChatRoomMessage {
        let roomId: String
        let user: Entity.RoomUser
        let msgType: MessageType
        private enum CodingKeys: String, CodingKey {
            case roomId = "room_id"
            case user
            case msgType = "message_type"
        }
    }
    
    struct KickOutMessage: ChatRoomMessage {
        let roomId: String
        //被踢
        let user: Entity.RoomUser
        //操作者
        let opUser: Entity.RoomUser
        let msgType: MessageType
        
        private enum CodingKeys: String, CodingKey {
            case roomId = "room_id"
            case user
            case opUser = "op_user"
            case msgType = "message_type"
        }
    }
    
    //red color
    struct SystemMessage: ChatRoomMessage {
        let content: String
        let textColor: String?
        let msgType: MessageType
        
        private enum CodingKeys: String, CodingKey {
            case content
            case msgType = "message_type"
            case textColor = "text_color"
        }
    }
}

extension ChatRoom.MessageType {
    static var structMap: [ChatRoom.MessageType: ChatRoomMessage.Type] {
        return [
//            .baseInfo: ChatRoom.RoomBaseMessage.self,
            .joinRoom: ChatRoom.JoinRoomMessage.self,
            .leaveRoom: ChatRoom.LeaveRoomMessage.self,
            .kickoutRoom: ChatRoom.KickOutMessage.self,
            .roomInfo: ChatRoom.RoomInfoMessage.self,
        ]
    }
}
