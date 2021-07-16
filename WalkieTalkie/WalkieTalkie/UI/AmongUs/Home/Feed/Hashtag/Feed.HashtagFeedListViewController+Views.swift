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
    
    class HashTagHeader: UICollectionReusableView {
        
        private lazy var hashtagView: UIView = {
            let v = UIView()
            v.addSubviews(views: hashtagIcon, hashtagLabel)
            hashtagIcon.snp.makeConstraints { maker in
                maker.leading.centerY.equalToSuperview()
            }
            hashtagLabel.snp.makeConstraints { maker in
                maker.top.bottom.trailing.equalToSuperview()
                maker.height.equalTo(27)
                maker.leading.equalTo(hashtagIcon.snp.trailing).offset(4)
            }
            return v
        }()
        
        private lazy var hashtagIcon: UIImageView = {
            let i = UIImageView(image: R.image.iconFeedTagPrefix())
            return i
        }()
        
        private(set) lazy var hashtagLabel: UILabel = {
            let label = UILabel()
            label.font = R.font.nunitoExtraBold(size: 20)
            label.textColor = .white
            return label
        }()
        
        private(set) lazy var viewCountLabel: UILabel = {
            let label = UILabel()
            label.font = R.font.nunitoBold(size: 16)
            label.textColor = UIColor(hex6: 0xFFFFFF, alpha: 0.5)
            return label
        }()
        
        override init(frame: CGRect) {
            super.init(frame: .zero)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupLayout() {
            
            addSubviews(views: hashtagView, viewCountLabel)
            
            hashtagView.snp.makeConstraints { maker in
                maker.leading.equalToSuperview().offset(Frame.horizontalBleedWidth)
                maker.top.equalToSuperview()
                maker.trailing.lessThanOrEqualToSuperview().offset(-Frame.horizontalBleedWidth)
            }
            
            viewCountLabel.snp.makeConstraints { maker in
                maker.leading.trailing.equalToSuperview().inset(Frame.horizontalBleedWidth)
                maker.height.equalTo(22)
                maker.top.equalTo(hashtagView.snp.bottom).offset(8)
            }
            
        }
        
    }    
}
