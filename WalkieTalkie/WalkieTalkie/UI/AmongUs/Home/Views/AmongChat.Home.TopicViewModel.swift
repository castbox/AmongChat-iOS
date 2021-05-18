//
//  AmongChat.Home.TopicViewModel.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/12/18.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation
import RxSwift
import Kingfisher

extension AmongChat.Home {
    
    class TopicViewModel: Equatable {
        static func == (lhs: AmongChat.Home.TopicViewModel, rhs: AmongChat.Home.TopicViewModel) -> Bool {
            lhs.topic.topicId == rhs.topic.topicId
        }
        
                
        let topic: Entity.SummaryTopic
        
        init(with topic: Entity.SummaryTopic) {
            self.topic = topic
        }
        
        var name: String {
            return topic.topicName ?? ""
        }
                
        var coverUrl: String? {
            return topic.coverUrl
        }
                
        var bgUrl: String? {
            return topic.bgUrl
        }
        
        var nowPlaying: String {
            return R.string.localizable.amongChatHomeNowplaying("\(topic.playerCount ?? 0)")
        }
                
    }
    
}
