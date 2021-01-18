//
//  AmongChat.CreateRoom.ViewModel.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/12/17.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension AmongChat.CreateRoom {
    
    class TopicViewModel {
        
        let topic: Entity.SummaryTopic
        
        init(with topic: Entity.SummaryTopic) {
            self.topic = topic
        }
        
        lazy var roomProto: Entity.RoomProto = {
            var proto = Entity.RoomProto()
            proto.note = ""
            proto.topicId = topic.topicId
            proto.state = .public
            return proto
        }()
        
        var name: String? {
            return topic.topicName
        }
        
        var coverUrl: String? {
            return topic.coverUrl
        }
    }
    
}
