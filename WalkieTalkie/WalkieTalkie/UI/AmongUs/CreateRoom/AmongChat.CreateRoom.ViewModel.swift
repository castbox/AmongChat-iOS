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
        
        let topic: AmongChat.Topic
        
        init(with topic: AmongChat.Topic) {
            self.topic = topic
        }
        
        lazy var roomProto: Entity.RoomProto = {
            var proto = Entity.RoomProto()
            proto.note = ""
            proto.topicId = topic.rawValue
            proto.state = .public
            return proto
        }()
        
        var name: String {
            
            switch topic {
            case .amongus:
                return "# Among Us"
            case .roblox:
                return "# Roblox"
            case .chilling:
                return "# Just Chatting"
            }
        }
        
        var icon: UIImage? {
            switch topic {
            case .amongus:
                return R.image.ac_trophy()
            case .roblox:
                return R.image.ac_medal_silver()
            case .chilling:
                return R.image.ac_medal_bronze()
            }
        }
    }
    
}

