//
//  Request.AmongChatBackend.Feed.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 27/05/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation
import RxSwift


extension Request {
    
    static func interactiveMsgs(_ opType: Entity.DMInteractiveMessage.OpType?,
                                limit: Int = 20,
                                skipMs: Double) -> Single<Entity.DMInteractiveMessages> {
        
        let params: [String : Any] = [
            "op_type" : opType?.rawValue ?? "",
            "limit" : limit,
            "skip_ms" : skipMs
        ]
        
        return amongchatProvider.rx.request(.interactiveMsgs(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.DMInteractiveMessages.self)
            .map({
                
                guard let r = $0 else {
                    throw MsgError.default
                }
                
                return r
            })
            .observeOn(MainScheduler.asyncInstance)
        
    }
    
    
    static func userFeeds(_ uid: Int?,
                          topicName: String? = nil,
                          limit: Int = 20,
                          skipMs: Double) -> Single<Entity.FeedList> {
        
        let params: [String : Any] = [
            "uid": uid ?? "",
            "topic": topicName ?? "",
            "limit" : limit,
            "skip_ms" : skipMs
        ]
        return amongchatProvider.rx.request(.userFeeds(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.FeedList.self)
            .map({
                
                guard let r = $0 else {
                    throw MsgError.default
                }
                
                return r
            })
            .observeOn(MainScheduler.asyncInstance)
        
    }
    
}
