//
//  Entity+Feed.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/5/26.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation

extension Entity {
    
    struct FeedProto: Codable {
        var img: String
        var url: String
        var duration: Int64
        var topic: String
    }
    
}
