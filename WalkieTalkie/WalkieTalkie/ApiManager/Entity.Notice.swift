//
//  Entity.Notice.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/4/27.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation
import WCDBSwift

extension Entity {
    
    struct Notice: TableCodable {
        
        var identifier: Int?
        
        var fromUid: Int
        var uid: Int?
        var ms: Int64
        var isRead: Bool?
        var message: NoticeMessage
        
        enum CodingKeys: String, CodingTableKey {
            typealias Root = Notice
            static let objectRelationalMapping = TableBinding(CodingKeys.self)
            
            static var columnConstraintBindings: [CodingKeys: ColumnConstraintBinding]? {
                return [
                    identifier: ColumnConstraintBinding(isPrimary: true, isAutoIncrement: true),
                ]
            }
            
            case identifier = "id"
            case fromUid = "from_uid"
            case uid
            case ms
            case message
            case isRead = "is_read"
        }
        
    }
    
    struct NoticeMessage: TableCodable, ColumnCodable {
        
        init?(with value: FundamentalValue) {
            guard let json = value.stringValue.jsonObject(),
                  let message = try? JSONDecoder().decodeAnyData(NoticeMessage.self, from: json) else { return nil }
            
            type = message.type
            title = message.title
            text = message.text
            img = message.img
            link = message.link
            objType = message.objType
            objId = message.objId
        }
        
        func archivedValue() -> FundamentalValue {
            return .init(asString ?? "")
        }
        
        static var columnType: ColumnType {
            return .text
        }
        
        
        var type: String
        var title: String
        var text: String
        var img: String?
        var link: String?
        var objType: String?
        var objId: String?
        var imgWidth: CGFloat?
        var imgHeight: CGFloat?
        
        enum CodingKeys: String, CodingTableKey {
            typealias Root = NoticeMessage
            static let objectRelationalMapping = TableBinding(CodingKeys.self)
                        
            static var tableConstraintBindings: [TableConstraintBinding.Name: TableConstraintBinding]? {
                let multiPrimaryBinding =
                    MultiPrimaryBinding(indexesBy: objType.asIndex(orderBy: .descending), objId)
                let multiUniqueBinding =
                    MultiUniqueBinding(indexesBy: objType.asIndex(orderBy: .descending), objId.asIndex(orderBy: .ascending))
                return [
                    "MultiPrimaryConstraint": multiPrimaryBinding,
                    "MultiUniqueConstraint": multiUniqueBinding,
                ]
            }
            
            case type
            case title
            case text
            case img
            case link
            case objType = "obj_type"
            case objId = "obj_id"
            case imgWidth = "img_width"
            case imgHeight = "img_height"
        }
        
        enum MessageType: String {
            case TxtMsg
            case ImgMsg
            case ImgTxtMsg
            case TxtImgMsg
            case SocialMsg            
        }
        
        var messageType: MessageType {
            
            guard let t = MessageType(rawValue: type) else {
                return .TxtMsg
            }
            
            return t
        }
        
        enum MessageObjType: String {
            case group
            case user
            case room
            case unknown
        }
        
        var messageObjType: MessageObjType {
            
            guard let t = MessageObjType(rawValue: objType ?? "") else {
                return .unknown
            }
            
            return t
        }
        
    }
    
}

extension Entity {
    
    struct GroupApplyStat: Codable {
        
        var uid: Int?
        var gid: String
        var topicId: String?
        var cover: String?
        var name: String?
        var description: String?
        var status: Int?
        var createTime: Double?
        var rtcType: String?
        var applyCount: Int?
        
        private enum CodingKeys: String, CodingKey {
            case uid
            case gid
            case topicId
            case cover
            case name
            case description
            case status
            case createTime
            case rtcType
            case applyCount = "apply_count"
        }
        
    }
}
