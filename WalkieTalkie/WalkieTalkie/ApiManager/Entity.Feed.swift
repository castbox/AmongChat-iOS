//
//  Entity+Feed.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/5/26.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation

extension Entity {
    
    struct Feed: Codable {
        let pid: String
        let uid: Int
        let topic: String
        let img: URL
        let url: URL
        let duration: Int
        let width: Int?
        let height: Int?
        let status: Int
        let cmtCount: Int
        let createTime: Date
        let user: UserProfile
        let topicName: String
        let playCount: Int?
        let shareCount: Int?
        
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
