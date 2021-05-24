//
//  Social.ChooseGame.ViewModel.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/3/24.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

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


extension Entity.GameSkill.Status {
    var title: String? {
        switch self {
        case .added:
            return R.string.localizable.amongChatAdded()
        case .inreview:
            return R.string.localizable.statsPendingReview()
        case .none:
            return nil
        }
    }
    
    var image: UIImage? {
        switch self {
        case .added:
            return R.image.ac_choose_game_added()
        case .inreview:
            return R.image.ac_choose_game_inreview()
        case .none:
            return nil
        }
    }
}
