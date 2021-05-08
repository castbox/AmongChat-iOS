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
    struct DMProfile: Codable, ColumnCodable {
        
        let uid: Int64
        let name: String
        let pictureUrl: String
        
        init?(with value: FundamentalValue) {
            guard let json = value.stringValue.jsonObject(),
                  let profile = try? JSONDecoder().decodeAnyData(DMProfile.self, from: json) else { return nil }
            uid = profile.uid
            name = profile.name
            pictureUrl = profile.pictureUrl
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
        
        let message: DMMessageBody
        let relation: Int
        let fromUid: String
        var msgType: Peer.MessageType
        let unread: Bool?
        let fromUser: DMProfile
        var ms: Double?
        
        var dateString: String {
            Date(timeIntervalSince1970: ms ?? 0).dateTimeString()
        }
        
        init?(with value: FundamentalValue) {
            guard let json = value.stringValue.jsonObject(),
                  let msg = try? JSONDecoder().decodeAnyData(DMMessage.self, from: json) else { return nil }
            message = msg.message
            relation = msg.relation
            fromUid = msg.fromUid
            msgType = msg.msgType
            unread = msg.unread
            fromUser = msg.fromUser
            ms = msg.ms
        }
        
        func toConversation() -> DMConversation {
            return DMConversation(message: self, fromUid: self.fromUid, unreadCount: 1, lastMsgMs: Date().timeIntervalSince1970)
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
//                return [
//                    fromUid: ColumnConstraintBinding(isPrimary: true),
//                ]
//            }
            case message
            case relation
            case unread
            case fromUser = "from_user"
            case fromUid = "from_uid"
            case msgType = "message_type"
            case ms = "ms"
        }
    }
    
    struct DMMessageBody: TableCodable, ColumnCodable {
        let type: String
        let url: URL?
        let duration: Double?
        let text: String?
        
        init?(with value: FundamentalValue) {
            guard let json = value.stringValue.jsonObject(),
                  let message = try? JSONDecoder().decodeAnyData(DMMessageBody.self, from: json) else { return nil }
            type = message.type
            url = message.url
            duration = message.duration
            text = message.text
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
