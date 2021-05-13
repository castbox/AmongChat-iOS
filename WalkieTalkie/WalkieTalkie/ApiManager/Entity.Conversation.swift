//
//  Entity.DMConversation.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 07/05/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation
import WCDBSwift

extension Entity {
    enum DMMsgType: String {
        case text = "TxtMsg"
        case gif = "GifMsg"
        case voice = "VcMsg"
    }
    
    struct DMProfile: Codable, ColumnCodable {
        
        let uid: Int64
        let name: String?
        let pictureUrl: String?
        
        var isLoginUser: Bool {
            Settings.loginUserId?.int64 == uid
        }
        
        init?(with value: FundamentalValue) {
            guard let json = value.stringValue.jsonObject(),
                  let profile = try? JSONDecoder().decodeAnyData(DMProfile.self, from: json) else { return nil }
            uid = profile.uid
            name = profile.name
            pictureUrl = profile.pictureUrl
        }
        
        init(uid: Int64,
             name: String?,
             pictureUrl: String?) {
            self.uid = uid
            self.name = name
            self.pictureUrl = pictureUrl
        }
        
        
        func archivedValue() -> FundamentalValue {
            return .init(asString ?? "")
        }
        
        static var columnType: ColumnType {
            return .text
        }
        
//        enum CodingKeys: String, CodingTableKey {
//            typealias Root = DMProfile
//            static let objectRelationalMapping = TableBinding(CodingKeys.self)
//
//            case uid
//            case name
//            case pictureUrl = "picture_url"
//        }
        
        private enum CodingKeys: String, CodingKey {
            case uid
            case name
            case pictureUrl = "picture_url"
        }
    }
    
    struct DMConversation: TableCodable {
        var message: DMMessage
        let fromUid: String
        var unreadCount: Int
        //更新时间
        var lastMsgMs: Double
        
        enum CodingKeys: String, CodingTableKey {
            typealias Root = DMConversation
            static let objectRelationalMapping = TableBinding(CodingKeys.self)
            
            static var columnConstraintBindings: [CodingKeys: ColumnConstraintBinding]? {
                return [
                    fromUid: ColumnConstraintBinding(isPrimary: true),
                ]
            }
            case message
            case fromUid = "from_uid"
            case unreadCount = "unread_count"
            case lastMsgMs = "last_msg_ms"
        }
    }
    
    struct DMMessage: PeerMessage, TableCodable, ColumnCodable {
        enum Status: String, ColumnCodable {
            case success
            case sending
            case downloading
            case failed
            case empty //空消息
            
            init?(with value: FundamentalValue) {
                guard let type = Status(rawValue: value.stringValue) else { return nil }
                self = type
            }
            
            func archivedValue() -> FundamentalValue {
                return .init(rawValue)
            }
            
            static var columnType: ColumnType {
                return .text
            }
        }
        
        var body: DMMessageBody
        let relation: Int
        let fromUid: String
        var msgType: Peer.MessageType
        var unread: Bool?
        let fromUser: DMProfile
        var status: Status?
        var ms: Double?
        
        var isUnread: Bool {
            unread ?? false
        }
        
        var isNeedDownloadSource: Bool {
            // 时间小余7天
            guard !fromUser.isLoginUser,
                  body.msgType != .text,
                  body.url.isValid,
                  !body.localRelativePath.isValid,
                  (Date().timeIntervalSince1970 - (ms ?? 0) / 1000) < 604800 else {//7 * 24 * 60 * 60
                return false
            }
            return true
        }
        
        //seconds
        var timestamp: Double {
            guard let ms = ms else {
                return 0
            }
            return ms / 1000
        }
        
        var date: Date {
            Date(timeIntervalSince1970: timestamp)
        }
        
        init?(with value: FundamentalValue) {
            guard let json = value.stringValue.jsonObject(),
                  let msg = try? JSONDecoder().decodeAnyData(DMMessage.self, from: json) else { return nil }
            body = msg.body
            relation = msg.relation
            fromUid = msg.fromUid
            msgType = msg.msgType
            unread = msg.unread
            fromUser = msg.fromUser
            status = msg.status
            ms = msg.ms
        }
        
        init(body: DMMessageBody,
             relation: Int,
             fromUid: String,
             msgType: Peer.MessageType = .dm,
             unread: Bool? = false,
             fromUser: DMProfile,
             status: Status? = .sending,
             ms: Double? = Date().timeIntervalSince1970 * 1000) {
            self.body = body
            self.relation = relation
            self.fromUid = fromUid
            self.msgType = msgType
            self.unread = unread
            self.fromUser = fromUser
            self.status = status
            self.ms = ms
        }
        
        func toConversation() -> DMConversation {
            return DMConversation(message: self, fromUid: self.fromUid, unreadCount: status == .empty ? 0 : 1, lastMsgMs: Date().timeIntervalSince1970)
        }
        
        static func emptyMessage(for uid: String) -> Entity.DMMessage {
            let body = Entity.DMMessageBody(type: .text, url: nil, duration: 0, text: "")
            return Entity.DMMessage(body: body, relation: 1, fromUid: uid, fromUser: DMProfile(uid: 0, name: nil, pictureUrl: nil), status: .empty)
        }
        
        static func emptyMessage(for profile: DMProfile) -> Entity.DMMessage {
            let body = Entity.DMMessageBody(type: .text, url: nil, duration: 0, text: "")
            return Entity.DMMessage(body: body, relation: 1, fromUid: profile.uid.string, fromUser: profile, status: .empty)
        }
        
        func update(profile: DMProfile) -> Entity.DMMessage {
            return Entity.DMMessage(body: body, relation: relation, fromUid: fromUid, msgType: msgType, unread: unread, fromUser: profile, status: status, ms: ms)
        }
        
        func archivedValue() -> FundamentalValue {
            return .init(asString ?? "")
        }
        
        static var columnType: ColumnType {
            return .text
        }
        
        
        enum CodingKeys: String, CodingTableKey {
            typealias Root = DMMessage
            static let objectRelationalMapping = TableBinding(CodingKeys.self)
            
//            static var columnConstraintBindings: [CodingKeys: ColumnConstraintBinding]? {
//                let multiPrimaryBinding =
//                    MultiPrimaryBinding(indexesBy: objType.asIndex(orderBy: .descending), objId)
//                return [
//                    fromUid: ColumnConstraintBinding(isPrimary: true),
//                ]
//            }
            
            static var tableConstraintBindings: [TableConstraintBinding.Name: TableConstraintBinding]? {
                let multiPrimaryBinding =
                    MultiPrimaryBinding(indexesBy: fromUid, ms)
                return [
                    "MultiPrimaryConstraint": multiPrimaryBinding,
                ]
            }

            case body = "message"
            case relation
            case unread
            case fromUser = "from_user"
            case fromUid = "from_uid"
            case msgType = "message_type"
            case ms = "ms"
            case status
        }
    }
    
    struct DMMessageBody: TableCodable, ColumnCodable {
        let type: String
        var url: String?
        let duration: Double?
        let text: String?
        var img: String?
        let imageWidth: Double?
        let imageHeight: Double?
        
        //relative path
        var localRelativePath: String?
        
        var localAbsolutePath: String? {
            guard let path = localRelativePath else {
                return nil
            }
            return FileManager.absolutePath(for: path)
        }
        
        var isVoiceMsg: Bool {
            msgType == .voice
        }
        
        var isGifMsg: Bool {
            msgType == .gif
        }
        
        var localFileName: String? {
            switch msgType {
            case .gif:
                guard let url = url else {
                    return nil
                }
                return url+".gif"
            case .voice:
                guard let url = url else {
                    return nil
                }
                return url+".aac"
            default:
                return nil
            }
        }
        
        var msgType: DMMsgType? {
            DMMsgType(rawValue: type)
        }
        
        init?(with value: FundamentalValue) {
            guard let json = value.stringValue.jsonObject(),
                  let message = try? JSONDecoder().decodeAnyData(DMMessageBody.self, from: json) else { return nil }
            type = message.type
            url = message.url
            duration = message.duration
            text = message.text
            img = message.img
            imageWidth = message.imageWidth
            imageHeight = message.imageHeight
            localRelativePath = message.localRelativePath
        }
        
        init(type: DMMsgType,
             url: String? = nil,
             duration: Double? = nil,
             text: String? = nil,
             img: String? = nil,
             imageWidth: Double? = 0,
             imageHeight: Double? = 0,
             localRelativePath: String? = nil) {
            self.type = type.rawValue
            self.url = url
            self.duration = duration
            self.text = text
            self.img = img
            self.imageWidth = imageWidth
            self.imageHeight = imageHeight
            self.localRelativePath = localRelativePath
        }
        
        func archivedValue() -> FundamentalValue {
            return .init(asString ?? "")
        }
        
        static var columnType: ColumnType {
            return .text
        }
        
        
        enum CodingKeys: String, CodingTableKey {
            typealias Root = DMMessageBody
            static let objectRelationalMapping = TableBinding(CodingKeys.self)
            case type
            case url
            case duration
            case text
            case img
            case imageWidth = "img_width"
            case imageHeight = "img_height"
            case localRelativePath = "local_relative_path"
        }
        
        
    }
}

extension Peer.MessageType: ColumnCodable {
    init?(with value: FundamentalValue) {
        guard let type = Peer.MessageType(rawValue: value.stringValue) else { return nil }
        self = type
    }

    func archivedValue() -> FundamentalValue {
        return .init(rawValue)
    }
    
    static var columnType: ColumnType {
        return .text
    }

}
