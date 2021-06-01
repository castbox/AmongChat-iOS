//
//  Entity+Feed.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/5/26.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation

extension Entity {
    
    struct FeedCommentList: Codable {
        var list: [FeedComment]
        var more: Bool
    }
    
    struct CommentReplyList: Codable {
        var list: [FeedCommentReply]
        var more: Bool
    }
    
    struct FeedComment: Codable {
        var cid: String
        var uid: Int
        var pid: String
        var text: String
        var status: Int
        var likeCount: Int
        var replyCount: Int
        var replyIds: [String]
        var createTime: Int64
        var user: UserProfile
        var isLiked: Bool
        var replyList: [FeedCommentReply]?
        
        private enum CodingKeys: String, CodingKey {
            case cid
            case uid
            case pid
            case text
            case status
            case likeCount = "like_count"
            case replyCount = "reply_count"
            case replyIds = "reply_ids"
            case createTime = "create_time"
            case user
            case isLiked = "is_liked"
            case replyList = "reply_list"
        }
    }
    
    struct FeedCommentReply: Codable {
        var rid: String
        var uid: Int
        var toUid: Int
        var cid: String
        var text: String
        var likeCount: Int
        var createTime: Int64
        var user: UserProfile
        var toUser: UserProfile?
        
        private enum CodingKeys: String, CodingKey {
            case rid
            case uid
            case toUid = "to_uid"
            case cid
            case text
            case likeCount = "like_count"
            case createTime = "create_time"
            case user
            case toUser = "to_user"
        }
    }
}
