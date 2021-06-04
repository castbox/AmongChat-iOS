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
                          skipMs: Int64) -> Single<Entity.FeedList> {
        
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
    
    static func recommendFeeds(excludePids: [String],
                          limit: Int = 20) -> Single<[Entity.Feed]?> {
        
        let params: [String : Any] = [
            "exclude_pids": excludePids.joined(separator: ","),
            "limit" : limit,
        ]
        return amongchatProvider.rx.request(.recommendFeeds(params))
            .mapJSON()
            .mapToDataKeyListValue()
            .mapTo([Entity.Feed].self)
            .observeOn(MainScheduler.asyncInstance)
        
    }
    
    static func feedReportNotIntereasted(pid: String) -> Single<Bool> {
        
        let params: [String : Any] = [
            "pid": pid,
        ]
        return amongchatProvider.rx.request(.feedReportNotIntereasted(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapToProcessedValue()
            .observeOn(MainScheduler.asyncInstance)
        
    }
    
    static func feedDelete(_ pid: String) -> Single<Bool> {
        let params: [String : Any] = [
            "pid": pid
        ]
        return amongchatProvider.rx.request(.feedDelete(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapToProcessedValue()
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func feedReportPlay(_ pid: String) -> Single<Bool> {
        let params: [String : Any] = [
            "pid": pid
        ]
        return amongchatProvider.rx.request(.feedReportPlay(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapToProcessedValue()
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func feedReportShare(_ pid: String) -> Single<Bool> {
        let params: [String : Any] = [
            "pid": pid
        ]
        return amongchatProvider.rx.request(.feedReportShare(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapToProcessedValue()
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func feedReportPlayFinish(_ pid: String) -> Single<Bool> {
        let params: [String : Any] = [
            "pid": pid
        ]
        return amongchatProvider.rx.request(.feedReportPlayFinish(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapToProcessedValue()
            .observeOn(MainScheduler.asyncInstance)
    }
    
 
    static func feedSelectEmote(_ pid: String, emoteId: String) -> Single<Bool> {
        let params: [String : Any] = [
            "pid": pid,
            "emote_id": emoteId
        ]
        return amongchatProvider.rx.request(.feedSelectEmote(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapToProcessedValue()
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func feedUnselectEmote(_ pid: String, emoteId: String) -> Single<Bool> {
        let params: [String : Any] = [
            "pid": pid,
            "emote_id": emoteId
        ]
        return amongchatProvider.rx.request(.feedUnselectEmote(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapToProcessedValue()
            .observeOn(MainScheduler.asyncInstance)
    }
    
    static func myFeeds(limit: Int = 20,
                        skipMs: Int64) -> Single<Entity.FeedList> {
        
        let params: [String : Any] = [
            "limit" : limit,
            "skip_ms" : skipMs
        ]
        
        return amongchatProvider.rx.request(.myFeeds(params))
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
    
    static func redirectToFeed(directMessage: Entity.DMInteractiveMessage) -> Single<Entity.FeedRedirectInfo> {
        
        let params: [String : Any] = [
            "pid" : directMessage.urlId,
            "pos_id" : directMessage.posId,
            "pos_type" : directMessage.posType ?? ""
        ]
        
        return amongchatProvider.rx.request(.feedPostPage(params))
            .mapJSON()
            .mapToDataKeyJsonValue()
            .mapTo(Entity.FeedRedirectInfo.self)
            .map({
                guard let r = $0 else {
                    throw MsgError.default
                }
                return r
            })
            .observeOn(MainScheduler.asyncInstance)
        
    }
}
