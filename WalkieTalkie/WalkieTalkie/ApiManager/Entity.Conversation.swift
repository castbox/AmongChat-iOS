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
        
        private enum CodingKeys: String, CodingKey {
            case uid
            case name
            case pictureUrl = "picture_url"
        }
        
//        enum CodingKeys: String, CodingTableKey {
//            typealias Root = DMProfile
//            static let objectRelationalMapping = TableBinding(CodingKeys.self)
//
//            case uid
//            case name
//            case pictureUrl = "picture_url"
//        }
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
        let unread: Bool?
        let fromUser: DMProfile
        var status: Status?
        var ms: Double?
        
        //seconds
        var timestamp: Double {
            guard let ms = ms else {
                return 0
            }
            return ms / 1000
        }
        
        var dateString: String {
            Date(timeIntervalSince1970: timestamp).dateTimeString()
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
        let url: String?
        let duration: Double?
        let text: String?
        let imageWidth: Double?
        let imageHeight: Double?
        
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
            imageWidth = message.imageWidth
            imageHeight = message.imageHeight
        }
        
        init(type: DMMsgType,
             url: String? = nil,
             duration: Double? = nil,
             text: String? = nil,
             imageWidth: Double = 0,
             imageHeight: Double = 0) {
            self.type = type.rawValue
            self.url = url
            self.duration = duration
            self.text = text
            self.imageWidth = imageWidth
            self.imageHeight = imageHeight
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
            case imageWidth = "img_width"
            case imageHeight = "img_height"
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
