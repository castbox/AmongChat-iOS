//
//  Entity+Feed.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/5/26.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

extension Entity {
    
    class FeedEmote: Codable {
        let id: String
        var count: Int
        var isVoted: Bool
        var img: URL?
        var url: URL?
        
        var width: CGFloat = 0
        
        init(id: String,
             count: Int,
             isVoted: Bool,
             img: URL? = nil,
             url: URL? = nil,
             width: CGFloat = 0) {
            self.id = id
            self.count = count
            self.isVoted = isVoted
            self.img = img
            self.url = url
            self.width = width
        }
        
        private enum CodingKeys: String, CodingKey {
            case id
            case count
            case isVoted = "is_voted"
        }
    }
    
    struct Feed: Codable {
        
        enum StatusType: Int, Codable {
            case inreview
            case live
        }

        let pid: String
        let uid: Int
        let topic: String
        let img: URL
        let url: URL
        let duration: Int
        let width: Int?
        let height: Int?
        let status: Int // 0审核中
        
        var statusType: StatusType {
            return StatusType(rawValue: status) ?? .inreview
        }
        
        //comment count
        var cmtCount: Int
        let createTime: Int64
        let user: UserProfile
        let topicName: String
        //播放数
        let playCount: Int?
        //分享数
        let shareCount: Int?
        var emotes: [FeedEmote]
        
        var playCountValue: Int {
            playCount ?? 0
        }
        
        var shareCountValue: Int {
            shareCount ?? 0
        }
        
        private enum CodingKeys: String, CodingKey {
            case pid
            case uid
            case topic
            case img
            case url
            case duration
            case width
            case height
            case status
            case cmtCount = "cmt_count"
            case createTime = "create_time"
            case user
            case topicName = "topic_name"
            case playCount = "play_count"
            case shareCount = "share_count"
            case emotes
        }
    }
    
    struct FeedList: Codable {
        var list: [Feed]
        var more: Bool
        var count: Int?
    }
    
    struct FeedProto: Codable {
        var img: String
        var url: String
        var duration: Int64
        var topic: String
    }
    
}
