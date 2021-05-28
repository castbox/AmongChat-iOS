//
//  FeedEmojiCollectionCell.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 26/05/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

class FeedEmojiCollectionCell: UICollectionViewCell {
    
    @IBOutlet weak var blurBackgroundView: UIVisualEffectView!
    @IBOutlet weak var button: UIButton!
    
    func config(with emote: Entity.FeedEmote) {
        
        if emote.id.isEmpty {
            button.setImage(R.image.iconAddEmotes(), for: .normal)
            button.setTitle(nil, for: .normal)
        } else {
            button.kf.setImage(with: emote.img, for: .normal)
//            button.setImage(R.image.iconAddEmotes(), for: .normal)
            button.setTitle(emote.count.string, for: .normal)
        }
        
        blurBackgroundView.isHidden = emote.isVoted
        
        if emote.isVoted {
            button.backgroundColor = "#866EEF".color()
        } else {
            button.backgroundColor = .clear
        }
    }
}
