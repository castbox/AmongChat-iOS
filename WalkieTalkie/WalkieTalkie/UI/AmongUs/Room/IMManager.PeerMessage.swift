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
    var msgType: Peer.MessageType { get }
}

typealias PeerMessage = PeerMessageable & Codable

extension Peer {
    enum MessageType: String, Codable {
        case text = "AC:Chatroom:Text"
        //peer
        case groupPeerCall = "AC:PEER:Call"
        case groupPeerApply = "AC:PEER:GroupApply"
        case friendsInfo = "AC:PEER:FriendsInfo"
        case roomInvitation = "AC:PEER:Invite"
        case roomInvitationInviteStranger = "AC:PEER:InviteStranger"


//        MSG_TYPE_PEER_GROUP_APPLY = 'AC:PEER:GroupApply'
//        GROUP_APPLY_REQUEST = 1
//        GROUP_APPLY_ACCEPT = 2
//        GROUP_APPLY_REJECT = 3
        
    }
    
    struct TextMessage: PeerMessage {
        
        let content: String
        let user: Entity.RoomUser
        let msgType: MessageType
        
        private enum CodingKeys: String, CodingKey {
            case content
            case user
            case msgType = "message_type"
        }
    }

    //red color
    struct SystemMessage: PeerMessage {
        
        enum ContentType: String, Codable {
            case `public`
            case `private`
        }
        
        let content: String
        let textColor: String?
        let contentType: ContentType?
        let msgType: MessageType
        
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
    
    struct GroupRoomCallMessage: PeerMessage {
        
        enum Action: Int32, Codable {
            case none = 0
            case request = 1
            case accept = 2
            case reject = 3
            case hangup = 4
            case invite = 5
            case invite_reject = 6
        }
        
        var action: Action = .none// call-in状态 1request 2accept 3reject 4handup 5invite 6invite_reject
        var gid: String = ""
        var expireTime: Int64 = 0
        var extra: String = ""
        var position: Int = 0
        let msgType: MessageType

        
        private enum CodingKeys: String, CodingKey {
            case action
            case gid
            case expireTime = "expire_time"
            case extra
            case position
            case msgType = "message_type"
        }
    }
    
    struct GroupApplyMessage: PeerMessage {
        var msgType: Peer.MessageType
        
        
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

extension Peer.SystemMessage: MessageListable {
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

extension Peer.TextMessage: MessageListable {
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
            .foregroundColor: UIColor.white,
            .font: R.font.nunitoSemiBold(size: 12) ?? Font.caption1.value,
            .paragraphStyle: pargraph
//            .kern: 0.5
        ]
        let mutableNormalString = NSMutableAttributedString()
        mutableNormalString.append(NSAttributedString(string: "#\(user.seatNo) \(user.name ?? "")", attributes: nameAttr))
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
        
        mutableNormalString.append(NSAttributedString(string: "  \(content)", attributes: contentAttr))
        return mutableNormalString
    }
}

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




