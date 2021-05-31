//
//  FeedEmojiCollectionCell.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 26/05/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

class FeedEmoteView: UIButton {
    override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        //title
        let originRect = super.imageRect(forContentRect: contentRect)
        if let title = title(for: .normal), !title.isEmpty {
            return CGRect(x: originRect.origin.x, y: 0, width: 32, height: 32)
        } else {
            return originRect
        }
    }
    
    override func titleRect(forContentRect contentRect: CGRect) -> CGRect {
        let originRect = super.imageRect(forContentRect: contentRect)
        if let title = title(for: .normal), !title.isEmpty {
            return CGRect(x: 48, y: 0, width: originRect.width, height: 32)
        } else {
            return .zero
        }
    }
}

class FeedEmojiCollectionCell: UICollectionViewCell {
    
    @IBOutlet weak var blurBackgroundView: UIVisualEffectView!
    @IBOutlet weak var button: FeedEmoteView!
    
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
