//
//  Feed.HashtagFeedListViewController+Views.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/7/13.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

extension Feed.HashtagFeedListViewController {
    
    class FeedCell: UICollectionViewCell {
        
        private lazy var imageView: UIImageView = {
            let i = UIImageView()
            i.contentMode = .scaleAspectFill
            return i
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setUpLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setUpLayout() {
            
            backgroundColor = .clear
            contentView.backgroundColor = .clear
            contentView.clipsToBounds = true
            contentView.layer.cornerRadius = 12
            
            contentView.addSubviews(views: imageView)
            
            imageView.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
            
        }
        
        func bindData(with feed: Feed.ListCellViewModel) {
            imageView.setImage(with: feed.feed.gif ?? feed.feed.img)
        }
        
    }
    
}
