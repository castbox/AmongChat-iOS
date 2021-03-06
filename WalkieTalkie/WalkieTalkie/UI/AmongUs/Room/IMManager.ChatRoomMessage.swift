//
//  IMManager.ChatRoomMessage.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 07/04/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

struct ChatRoom {
    
}

protocol ChatRoomMessageable {
    var msgType: ChatRoom.MessageType { get }
}

protocol MessageListable {
    var attrString: NSAttributedString { get }
    var rawContent: String? { get }
    var isGroupRoomHostMsg: Bool { get set }
}

typealias ChatRoomMessage = ChatRoomMessageable & Codable

extension ChatRoom {
    enum MessageType: String, Codable {
        case text = "AC:Chatroom:Text"
        case roomInfo = "AC:Chatroom:RoomInfo"
        case joinRoom = "AC:Chatroom:Join"
        case leaveRoom = "AC:Chatroom:Leave"
        ////系统踢人， 如： 用户无心跳
        case systemLeave = "AC:Chatroom:SystemLeave"
        case kickoutRoom = "AC:Chatroom:Kick"
        case system = "AC:Chatroom:SystemText"
        case emoji = "AC:Chatroom:Emoji"
        case muteMic = "AC:Chatroom:Mute"
        case muteIm = "AC:Chatroom:MuteIm"//  （文字）
        
        //group
        case groupJoinRoom = "AC:Chatroom:GroupLiveJoin"
        case groupLeaveRoom = "AC:Chatroom:GroupLiveLeave"
        case groupLiveEnd = "AC:Chatroom:GroupLiveEnd"
        case groupInfo = "AC:Chatroom:GroupInfo"
    }
    
    struct TextMessage: ChatRoomMessage, MessageListable {
        
        let content: String
        let user: Entity.RoomUser
        let msgType: MessageType
        let contentColor: String?
        
        var isGroupRoomHostMsg: Bool = false
        
        private enum CodingKeys: String, CodingKey {
            case content
            case user
            case contentColor = "content_color"
            case msgType = "message_type"
        }
        
        init(content: String,
             user: Entity.RoomUser,
             msgType: MessageType,
             contentColor: String? = nil,
             isGroupRoomHostMsg: Bool = false) {
            self.content = content
            self.user = user
            self.msgType = msgType
            self.contentColor = contentColor
            self.isGroupRoomHostMsg = isGroupRoomHostMsg
        }
    }

    struct RoomInfoMessage: ChatRoomMessage {
        let room: Entity.Room
        let msgType: MessageType
        let ms: TimeInterval//: 1611648904017
        
        private enum CodingKeys: String, CodingKey {
            case room
            case msgType = "message_type"
            case ms
        }
    }

    struct JoinRoomMessage: ChatRoomMessage, MessageListable {
        let user: Entity.RoomUser
        let msgType: MessageType
        
        var isGroupRoomHostMsg: Bool = false

        private enum CodingKeys: String, CodingKey {
            case user
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
        enum Role: String, Codable {
            case host
            case system //系统踢人
            case admin
        }
        
        let roomId: String
        //被踢
        let user: Entity.RoomUser
        //操作者
        let opUser: Entity.RoomUser
        let msgType: MessageType
        let opRole: Role
        
        private enum CodingKeys: String, CodingKey {
            case roomId = "room_id"
            case user
            case opUser = "op_user"
            case msgType = "message_type"
            case opRole = "op_role"
        }
    }
    
    //red color
    struct SystemMessage: ChatRoomMessage, MessageListable {
        
        enum ContentType: String, Codable {
            case `public`
            case `private`
        }
        
        let content: String
        let textColor: String?
        let contentType: ContentType?
        let msgType: MessageType

        var isGroupRoomHostMsg: Bool = false

        var text: String {
            contentType?.text ?? content
        }
        
        private enum CodingKeys: String, CodingKey {
            case content
            case msgType = "message_type"
            case textColor = "text_color"
            case contentType = "content_type"
        }
    }
    
    struct EmojiMessage: ChatRoomMessage {
        
        let resource: String
        let duration: Int?
        let hideDelaySec: Int?
        let emojiType: Entity.EmojiItem.EmojiType?
        let msgType: MessageType
        let user: Entity.RoomUser
        
        private enum CodingKeys: String, CodingKey {
            case resource = "resource"
            case duration = "duration"
            case hideDelaySec = "hide_delay_sec"
            case msgType = "message_type"
            case emojiType = "emoji_type"
            case user
        }
    }
    
    struct MuteMicMessage: ChatRoomMessage {
        
        let roomId: String
        let mute: Bool
        let msgType: MessageType
        let user: Entity.RoomUser
        
        private enum CodingKeys: String, CodingKey {
            case roomId = "room_id"
            case msgType = "message_type"
            case mute
            case user
        }
    }
    
    struct MuteImMessage: ChatRoomMessage {
        let roomId: String
        let mute: Bool
        let msgType: MessageType
        let user: Entity.RoomUser
        
        private enum CodingKeys: String, CodingKey {
            case roomId = "room_id"
            case msgType = "message_type"
            case mute
            case user
        }
    }
    
    //MARK: // - Group Room Message
    struct GroupInfoMessage: ChatRoomMessage {
        let group: Entity.Group
        let msgType: MessageType
        let ms: TimeInterval//: 1611648904017
        
        private enum CodingKeys: String, CodingKey {
            case group
            case msgType = "message_type"
            case ms
        }
    }
    
    struct GroupJoinRoomMessage: ChatRoomMessage, MessageListable {
        let gid: String
        let user: Entity.RoomUser
        let msgType: MessageType
        var isGroupRoomHostMsg: Bool = false
        
        private enum CodingKeys: String, CodingKey {
            case gid
            case user
            case msgType = "message_type"
        }
    }
    
    struct GroupLeaveRoomMessage: ChatRoomMessage {
        //{"gid": "hduj2zFF", "live_id": null, "message_type": "AC:Chatroom:GroupLiveEnd"}
        let groupId: String
        let user: Entity.RoomUser
        let msgType: MessageType
        private enum CodingKeys: String, CodingKey {
            case groupId = "gid"
            case user
            case msgType = "message_type"
        }
    }
    
    struct GroupRoomEndMessage: ChatRoomMessage {
        
        let gid: String
        let liveId: String?
        let msgType: MessageType
        private enum CodingKeys: String, CodingKey {
            case gid
            case liveId = "live_id"
            case msgType = "message_type"
        }
    }

//    struct GroupRoomCallMessage: ChatRoomMessage {
//        
//        enum Action: Int32, Codable {
//            case none = 0
//            case request = 1
//            case accept = 2
//            case reject = 3
//            case hangup = 4
//            case invite = 5
//            case invite_reject = 6
//        }
//        
//        var action: Action = .none// call-in状态 1request 2accept 3reject 4handup 5invite 6invite_reject
//        var gid: String = ""
//        var expireTime: Int64 = 0
//        var extra: String = ""
//        var position: Int = 0
//        let msgType: MessageType
//
//        
//        private enum CodingKeys: String, CodingKey {
//            case action
//            case gid
//            case expireTime = "expire_time"
//            case extra
//            case position
//            case msgType = "message_type"
//        }
//    }
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

extension ChatRoom.SystemMessage {
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

extension ChatRoom.TextMessage {
    var rawContent: String? {
        content
    }
    
    var attrString: NSAttributedString {
        let pargraph = NSMutableParagraphStyle()
        pargraph.lineBreakMode = .byTruncatingTail
        pargraph.lineHeightMultiple = 0
        
        let nameAttr: [NSAttributedString.Key: Any] = [
            .foregroundColor: "ABABAB".color(),
            .font: R.font.nunitoExtraBold(size: 12) ?? Font.caption1.value,
            .paragraphStyle: pargraph
//            .kern: 0.5
        ]
        
        let contentAttr: [NSAttributedString.Key: Any] = [
            .foregroundColor: contentColor?.color() ?? UIColor.white,
            .font: R.font.nunitoSemiBold(size: 12) ?? Font.caption1.value,
            .paragraphStyle: pargraph
//            .kern: 0.5
        ]
        let mutableNormalString = NSMutableAttributedString()
        if isGroupRoomHostMsg {
            mutableNormalString.append(NSAttributedString(string: "\(R.string.localizable.amongChatGroupAdmin()) \(user.name ?? "")", attributes: nameAttr))
        } else if user.seatNo >= 0 {
            mutableNormalString.append(NSAttributedString(string: "#\(user.seatNo) \(user.name ?? "")", attributes: nameAttr))
        } else {
            mutableNormalString.append(NSAttributedString(string: "\(user.name ?? "")", attributes: nameAttr))
        }
        if user.isVerified == true {
            let font = R.font.nunitoExtraBold(size: 12)!
            let image = R.image.icon_verified_13()!
            let imageAttachment = NSTextAttachment()
            imageAttachment.image = image
            imageAttachment.bounds = CGRect(x: 0, y: (font.capHeight - image.size.height)/2, width: image.size.width, height: image.size.height)
            let imageString = NSAttributedString(attachment: imageAttachment)
            mutableNormalString.yy_appendString(" ")
            mutableNormalString.append(imageString)
        }
        if user.isVip == true {
            let font = R.font.nunitoExtraBold(size: 12)!
            let image = R.image.icon_vip_13()!
            let imageAttachment = NSTextAttachment()
            imageAttachment.image = image
            imageAttachment.bounds = CGRect(x: 0, y: (font.capHeight - image.size.height)/2, width: image.size.width, height: image.size.height)
            let imageString = NSAttributedString(attachment: imageAttachment)
            mutableNormalString.yy_appendString(" ")
            mutableNormalString.append(imageString)
        }
        
        if user.isOfficial == true {
            let b = OfficialBadgeView(heightStyle: ._14)
            
            if let image = b.asImage() {
                let font = R.font.nunitoExtraBold(size: 12)!
                let imageAttachment = NSTextAttachment()
                imageAttachment.image = image
                imageAttachment.bounds = CGRect(x: 0, y: (font.capHeight - image.size.height)/2, width: image.size.width, height: image.size.height)
                
                let imageString = NSAttributedString(attachment: imageAttachment)
                mutableNormalString.yy_appendString(" ")
                mutableNormalString.append(imageString)
            }
        }

        mutableNormalString.append(NSAttributedString(string: "  \(content)", attributes: contentAttr))
        return mutableNormalString
    }
}

extension ChatRoom.JoinRoomMessage {
    var rawContent: String? {
        nil
    }
    
    var attrString: NSAttributedString {
        let pargraph = NSMutableParagraphStyle()
        pargraph.lineBreakMode = .byTruncatingTail
        pargraph.lineHeightMultiple = 0
        
        let nameAttr: [NSAttributedString.Key: Any] = [
            .foregroundColor: "ABABAB".color(),
            .font: R.font.nunitoExtraBold(size: 12) ?? Font.caption1.value,
            .paragraphStyle: pargraph
            //            .kern: 0.5
        ]
        
        let contentAttr: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white,
            .font: R.font.nunitoSemiBold(size: 12) ?? Font.caption1.value,
            .paragraphStyle: pargraph
            //            .kern: 0.5
        ]
        
        let mutableNormalString = NSMutableAttributedString()
//        mutableNormalString.append(NSAttributedString(string: "#\(user.seatNo) \(user.name ?? "")", attributes: nameAttr))
        if isGroupRoomHostMsg {
            mutableNormalString.append(NSAttributedString(string: "\(R.string.localizable.amongChatGroupAdmin()) \(user.name ?? "")", attributes: nameAttr))
        } else if user.seatNo >= 0 {
            mutableNormalString.append(NSAttributedString(string: "#\(user.seatNo) \(user.name ?? "")", attributes: nameAttr))
        } else {
            mutableNormalString.append(NSAttributedString(string: "\(user.name ?? "")", attributes: nameAttr))
        }
        //
        if user.isVerified == true {
            let font = R.font.nunitoExtraBold(size: 12)!
            let image = R.image.icon_verified_13()!
            let imageAttachment = NSTextAttachment()
            imageAttachment.image = image
            imageAttachment.bounds = CGRect(x: 0, y: (font.capHeight - image.size.height)/2, width: image.size.width, height: image.size.height)
            let imageString = NSAttributedString(attachment: imageAttachment)
            mutableNormalString.yy_appendString(" ")
            mutableNormalString.append(imageString)
        }
        
        if user.isVip == true {
            let font = R.font.nunitoExtraBold(size: 12)!
            let image = R.image.icon_vip_13()!
            let imageAttachment = NSTextAttachment()
            imageAttachment.image = image
            imageAttachment.bounds = CGRect(x: 0, y: (font.capHeight - image.size.height)/2, width: image.size.width, height: image.size.height)
            let imageString = NSAttributedString(attachment: imageAttachment)
//            if user.isVerified == false {
            mutableNormalString.yy_appendString(" ")
//            }
            mutableNormalString.append(imageString)
        }
        
        if user.isOfficial == true {
            let b = OfficialBadgeView(heightStyle: ._14)
            
            if let image = b.asImage() {
                let font = R.font.nunitoExtraBold(size: 12)!
                let imageAttachment = NSTextAttachment()
                imageAttachment.image = image
                imageAttachment.bounds = CGRect(x: 0, y: (font.capHeight - image.size.height)/2, width: image.size.width, height: image.size.height)
                
                let imageString = NSAttributedString(attachment: imageAttachment)
                mutableNormalString.yy_appendString(" ")
                mutableNormalString.append(imageString)
            }
        }
        
        mutableNormalString.append(NSAttributedString(string: "  \(R.string.localizable.chatroomMessageUserJoined())", attributes: contentAttr))
        return mutableNormalString
    }
}

extension ChatRoom.KickOutMessage.Role {
    var alertTitle: String {
        switch self {
        case .host:
            return R.string.localizable.amongChatRoomKickout()
        case .system:
            return R.string.localizable.amongChatRoomKickoutSystem()
        case .admin:
            return R.string.localizable.amongChatRoomKickout()
        }
    }
}

extension ChatRoom.SystemMessage.ContentType {
    var text: String {
        switch self {
        case .private:
            return R.string.localizable.chatroomMessageSystemChangeToPrivate()
        case .public:
            return R.string.localizable.chatroomMessageSystemChangeToPublic()
        }
    }
    
}

extension ChatRoom.GroupJoinRoomMessage {
    var rawContent: String? {
        nil
    }
    
    var attrString: NSAttributedString {
        let pargraph = NSMutableParagraphStyle()
        pargraph.lineBreakMode = .byTruncatingTail
        pargraph.lineHeightMultiple = 0
        
        let nameAttr: [NSAttributedString.Key: Any] = [
            .foregroundColor: "ABABAB".color(),
            .font: R.font.nunitoExtraBold(size: 12) ?? Font.caption1.value,
            .paragraphStyle: pargraph
            //            .kern: 0.5
        ]
        
        let contentAttr: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white,
            .font: R.font.nunitoSemiBold(size: 12) ?? Font.caption1.value,
            .paragraphStyle: pargraph
            //            .kern: 0.5
        ]
        
        let mutableNormalString = NSMutableAttributedString()
//        mutableNormalString.append(NSAttributedString(string: "#\(user.seatNo) \(user.name ?? "")", attributes: nameAttr))
        if isGroupRoomHostMsg {
            mutableNormalString.append(NSAttributedString(string: "\(R.string.localizable.amongChatGroupAdmin()) \(user.name ?? "")", attributes: nameAttr))
        } else if user.seatNo >= 0 {
            mutableNormalString.append(NSAttributedString(string: "#\(user.seatNo) \(user.name ?? "")", attributes: nameAttr))
        } else {
            mutableNormalString.append(NSAttributedString(string: "\(user.name ?? "")", attributes: nameAttr))
        }
        //
        if user.isVerified == true {
            let font = R.font.nunitoExtraBold(size: 12)!
            let image = R.image.icon_verified_13()!
            let imageAttachment = NSTextAttachment()
            imageAttachment.image = image
            imageAttachment.bounds = CGRect(x: 0, y: (font.capHeight - image.size.height)/2, width: image.size.width, height: image.size.height)
            let imageString = NSAttributedString(attachment: imageAttachment)
            mutableNormalString.yy_appendString(" ")
            mutableNormalString.append(imageString)
        }
        
        if user.isVip == true {
            let font = R.font.nunitoExtraBold(size: 12)!
            let image = R.image.icon_vip_13()!
            let imageAttachment = NSTextAttachment()
            imageAttachment.image = image
            imageAttachment.bounds = CGRect(x: 0, y: (font.capHeight - image.size.height)/2, width: image.size.width, height: image.size.height)
            let imageString = NSAttributedString(attachment: imageAttachment)
//            if user.isVerified == false {
            mutableNormalString.yy_appendString(" ")
//            }
            mutableNormalString.append(imageString)
        }
        
        if user.isOfficial == true {
            let b = OfficialBadgeView(heightStyle: ._14)
            
            if let image = b.asImage() {
                let font = R.font.nunitoExtraBold(size: 12)!
                let imageAttachment = NSTextAttachment()
                imageAttachment.image = image
                imageAttachment.bounds = CGRect(x: 0, y: (font.capHeight - image.size.height)/2, width: image.size.width, height: image.size.height)
                
                let imageString = NSAttributedString(attachment: imageAttachment)
                mutableNormalString.yy_appendString(" ")
                mutableNormalString.append(imageString)
            }
        }

        mutableNormalString.append(NSAttributedString(string: "  \(R.string.localizable.chatroomMessageUserJoined())", attributes: contentAttr))
        return mutableNormalString
    }
}
