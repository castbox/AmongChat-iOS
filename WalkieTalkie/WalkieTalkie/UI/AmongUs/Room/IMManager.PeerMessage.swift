//
//  IMManager.PeerMessage.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 07/04/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

struct Peer {
    
}

protocol PeerMessageable {
//    var user: Entity.UserProfile { get set }
    var msgType: Peer.MessageType { get }
}

typealias PeerMessage = PeerMessageable & Codable

extension Peer {
    enum MessageType: String, Codable {
        case text = "AC:Chatroom:Text"
        //上麦消息
        case groupRoomCall = "AC:PEER:Call"
        //group 申请后消息
        case groupApply = "AC:PEER:GroupApply"
        //更新 friends 消息
        case friendsInfo = "AC:PEER:FriendsInfo"
        case roomInvitation = "AC:PEER:Invite"
        case roomInvitationInviteStranger = "AC:PEER:InviteStranger"
        case unreadNotice = "AC:PEER:UnreadNotice"
        case unreadGroupApply = "AC:PEER:UnreadGroupApply"
        case dm = "AC:PEER:Dm"
    }
    
    struct UnreadNotice: PeerMessage {
        let msgType: MessageType
        private enum CodingKeys: String, CodingKey {
            case msgType = "message_type"
        }
    }
    
    struct TextMessage: PeerMessage {
        
        let content: String
        var user: Entity.UserProfile
        let msgType: MessageType
        
        private enum CodingKeys: String, CodingKey {
            case content
            case user
            case msgType = "message_type"
        }
    }

    //red color
    struct SystemMessage: PeerMessage, MessageListable {
        var isGroupRoomHostMsg: Bool = false
                
        enum ContentType: String, Codable {
            case `public`
            case `private`
        }
        
        let content: String
        let textColor: String?
        let contentType: ContentType?
        let msgType: MessageType
        var user: Entity.UserProfile
        
        var text: String {
            contentType?.text ?? content
        }
        
        private enum CodingKeys: String, CodingKey {
            case content
            case msgType = "message_type"
            case textColor = "text_color"
            case contentType = "content_type"
            case user
        }
    }
    
    struct CallMessage: PeerMessage {
        
        enum Action: Int32, Codable {
            case none = 0
            case request = 1
            case accept = 2
            case reject = 3
            case hangup = 4
            case invite = 5
            case invite_reject = 6
        }
        static let defaultExpireTime = 60
        
        var action: Action = .none// call-in状态 1request 2accept 3reject 4handup 5invite 6invite_reject
        var gid: String = ""
        var expireTime: Int64 = 0
        var extra: String = ""
        var position: Int = 0
        let msgType: MessageType = .groupRoomCall
        var user: Entity.UserProfile
        
        
        init(action: Action,
             gid: String,
             expireTime: Int64 = CallMessage.defaultExpireTime.int64,
             extra: String = "",
             position: Int,
             user: Entity.UserProfile) {
            self.action = action
            self.gid = gid
            self.expireTime = expireTime
            self.extra = extra
            self.position = position
            self.user = user
        }
        
        static func empty(gid: String) -> CallMessage {
            return CallMessage(action: .none, gid: gid, expireTime: 0, extra: "", position: 0, user: Settings.loginUserProfile!)
        }
        
        private enum CodingKeys: String, CodingKey {
            case action
            case gid
            case expireTime = "expire_time"
            case extra
            case position
            case msgType = "message_type"
            case user
        }
    }
    
    struct GroupApplyMessage: PeerMessage {
        enum Action: Int, Codable {
            case request = 1
            case accept = 2
            case reject = 3
        }
        
        var gid: String
        var action: Action
        var msgType: Peer.MessageType
        
        private enum CodingKeys: String, CodingKey {
            case action
            case gid
            case msgType = "message_type"
        }
    }
    
    struct FriendUpdatingInfo: PeerMessage {
        
        typealias Room = Entity.PlayingUser.Room
        var user: Entity.UserProfile
        private var _room: Room?
        var isOnline: Bool?
        var msgType: Peer.MessageType
        private var _group: Room?
        
        var room: Room? {
            return _room ?? _group
        }
        
        private enum CodingKeys: String, CodingKey {
            case user
            case _room = "room"
            case msgType = "message_type"
            case isOnline = "is_online"
            case _group = "group"
        }
        
        func asPlayingUser() -> Entity.PlayingUser {
            return Entity.PlayingUser(user: user, room: room)
        }
    }
}

extension Peer.MessageType {
//    static var structMap: [ChatRoom.MessageType: PeerMessageable.Type] {
//        return [
////            .baseInfo: ChatRoom.RoomBaseMessage.self,
//            .joinRoom: ChatRoom.JoinRoomMessage.self,
//            .leaveRoom: ChatRoom.LeaveRoomMessage.self,
//            .kickoutRoom: ChatRoom.KickOutMessage.self,
//            .roomInfo: ChatRoom.RoomInfoMessage.self,
//        ]
//    }
}

extension Peer.SystemMessage {
    var rawContent: String? {
        text
    }
    
    var attrString: NSAttributedString {
        let pargraph = NSMutableParagraphStyle()
        pargraph.lineBreakMode = .byTruncatingTail
        pargraph.lineHeightMultiple = 0
        
        let nameAttr: [NSAttributedString.Key: Any] = [
            .foregroundColor: textColor?.color() ?? (contentType == .public ? "8160FF" : "E64BA8").color(),
            .font: R.font.nunitoExtraBold(size: 12) ?? Font.caption1.value,
            .paragraphStyle: pargraph
        ]
        
        let mutableNormalString = NSMutableAttributedString()
        mutableNormalString.append(NSAttributedString(string: "\(rawContent ?? "")", attributes: nameAttr))
        return mutableNormalString
    }
}

//extension Peer.TextMessage: MessageListable {
//    var rawContent: String? {
//        content
//    }
//
//    var attrString: NSAttributedString {
//        let pargraph = NSMutableParagraphStyle()
//        pargraph.lineBreakMode = .byTruncatingTail
//        pargraph.lineHeightMultiple = 0
//
//        let nameAttr: [NSAttributedString.Key: Any] = [
//            .foregroundColor: "ABABAB".color(),
//            .font: R.font.nunitoExtraBold(size: 12) ?? Font.caption1.value,
//            .paragraphStyle: pargraph
////            .kern: 0.5
//        ]
//
//        let contentAttr: [NSAttributedString.Key: Any] = [
//            .foregroundColor: UIColor.white,
//            .font: R.font.nunitoSemiBold(size: 12) ?? Font.caption1.value,
//            .paragraphStyle: pargraph
////            .kern: 0.5
//        ]
//        let mutableNormalString = NSMutableAttributedString()
//        mutableNormalString.append(NSAttributedString(string: "#\(user.seatNo) \(user.name ?? "")", attributes: nameAttr))
//        if user.isVerified == true {
//            let font = R.font.nunitoExtraBold(size: 12)!
//            let image = R.image.icon_verified_13()!
//            let imageAttachment = NSTextAttachment()
//            imageAttachment.image = image
//            imageAttachment.bounds = CGRect(x: 0, y: (font.capHeight - image.size.height)/2, width: image.size.width, height: image.size.height)
//            let imageString = NSAttributedString(attachment: imageAttachment)
//            mutableNormalString.yy_appendString(" ")
//            mutableNormalString.append(imageString)
//        }
//        if user.isVip == true {
//            let font = R.font.nunitoExtraBold(size: 12)!
//            let image = R.image.icon_vip_13()!
//            let imageAttachment = NSTextAttachment()
//            imageAttachment.image = image
//            imageAttachment.bounds = CGRect(x: 0, y: (font.capHeight - image.size.height)/2, width: image.size.width, height: image.size.height)
//            let imageString = NSAttributedString(attachment: imageAttachment)
//            mutableNormalString.yy_appendString(" ")
//            mutableNormalString.append(imageString)
//        }
//
//        mutableNormalString.append(NSAttributedString(string: "  \(content)", attributes: contentAttr))
//        return mutableNormalString
//    }
//}

extension Peer.SystemMessage.ContentType {
    var text: String {
        switch self {
        case .private:
            return R.string.localizable.chatroomMessageSystemChangeToPrivate()
        case .public:
            return R.string.localizable.chatroomMessageSystemChangeToPublic()
        }
    }
    
}
