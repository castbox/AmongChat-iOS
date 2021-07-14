//
//  FeedNativeAdCell.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 15/06/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class FeedNativeAdCell: UITableViewCell {
    
    typealias Emote = Entity.FeedEmote
    
    weak var adView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let view = adView {
                if let nativeView = view.subviews.first(where: { $0 is NativeFeedsAdView }) as? NativeFeedsAdView,
                   nativeView.sponsoredByLabel.text?.isEmpty == true {
                    nativeView.sponsoredByLabel.isHidden = false
                    nativeView.sponsoredByLabel.text = "Sponsored"
                }
                contentView.insertSubview(view, belowSubview: emotesCollectionView)
                view.snp.makeConstraints { (maker) in
                    maker.edges.equalTo(adViewLayoutGuide)
                }
            }
        }
    }
    
    private var emotes: [Emote] = [] {
        didSet {
            //insert empty
            emotesCollectionView.reloadData()
        }
    }
    
    @IBOutlet weak var emotesCollectionView: UICollectionView!
    
    private lazy var adViewLayoutGuide = UILayoutGuide()
    
    private let bag = DisposeBag()
        
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        configureSubview()
    }
        
    func configureSubview() {
        contentView.addLayoutGuide(adViewLayoutGuide)
        emotesCollectionView.register(nibWithCellClass: FeedEmojiCollectionCell.self)

        adViewLayoutGuide.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
    }
    
    func updateEmotes(with viewModel: Feed.ListCellViewModel) {
        self.emotes = viewModel.emotes
    }
    
}

extension FeedNativeAdCell: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return emotes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withClass: FeedEmojiCollectionCell.self, for: indexPath)
        if let emote = emotes.safe(indexPath.item) {
            cell.config(with: emote)
        }
        return cell
    }
}

extension FeedNativeAdCell: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        guard let emote = emotes.safe(indexPath.item) else {
            return .zero
        }
        //notice.itemsSize
        return CGSize(width: emote.width, height: 32)
    }
    
}

extension FeedNativeAdCell: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let emote = emotes.safe(indexPath.item) else {
            return
        }
        
    }
    
}
