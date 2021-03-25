//
//  Social.ChooseGame.ViewModel.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/3/24.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation

extension Social.ChooseGame {
    
    class GameViewModel {
        
        let skill: Entity.GameSkill
        
        init(with skill: Entity.GameSkill) {
            self.skill = skill
        }
                
        var name: String? {
            return skill.topicName
        }
        
        var coverUrl: String? {
            return skill.coverUrl
        }
    }
    
}
