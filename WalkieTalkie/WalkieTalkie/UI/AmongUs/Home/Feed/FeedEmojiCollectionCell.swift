//
//  FeedEmojiCollectionCell.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 26/05/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import Kingfisher
import RxSwift

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
    @IBOutlet weak var button: UIButton!
    private var emoteDisposable: Disposable? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        button.setImageTitleHorizontalSpace(4)
    }
    
    func config(with emote: Entity.FeedEmote) {
        
        emoteDisposable?.dispose()
        
        if emote.id.isEmpty {
            button.setImage(R.image.iconAddEmotes(), for: .normal)
            button.setTitle(nil, for: .normal)
        } else {
            button.kf.setImage(with: emote.img, for: .normal)
            if let url = emote.img {
                emoteDisposable = KingfisherManager.shared.retrieveImageObservable(with: url)
                    .subscribe(onNext: { [weak self] img in
                        self?.button.setImage(img.resize(size: CGSize(width: 32, height: 32), color: UIColor.clear), for: .normal)
                    })
            }

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
