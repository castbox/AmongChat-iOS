//
//  FansGroup.TopicViewModel.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/3/30.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

extension FansGroup {
    
    class TopicViewModel {
        
        let topic: Entity.SummaryTopic
        
        init(with topic: Entity.SummaryTopic) {
            self.topic = topic
        }
        
        var name: String? {
            return topic.topicName
        }
        
        var coverUrl: String? {
            return topic.coverUrl
        }
        
        private(set) lazy var itemSize: CGSize = {
            
            guard let name = topic.topicName else {
                return .zero
            }
            
            return FansGroup.Views.GroupTopicView.viewSize(for: name, coverSize: CGSize(width: 32, height: 32))
        }()
    }
    
}
