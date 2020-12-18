//
//  AmongChat.Home.TopicViewModel.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/12/18.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation

extension AmongChat.Home {
    
    class TopicViewModel {
        
        let topic: Entity.SummaryTopic
        
        init(with topic: Entity.SummaryTopic) {
            self.topic = topic
        }
        
        var name: String {
            return topic.topicName ?? ""
        }
        
        var cover: String? {
            return topic.coverUrl
        }
        
        var bg: String? {
            return topic.bgUrl
        }
        
        var nowPlaying: String {
            return R.string.localizable.amongChatHomeNowplaying("\(topic.playerCount ?? 0)")
        }
        
    }
    
}
