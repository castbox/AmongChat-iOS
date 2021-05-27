//
//  Feed.SelectTopicViewController+Views.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/5/26.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

extension Feed.SelectTopicViewController {
    
    class TopicCell: UICollectionViewCell {
        
        private lazy var hashtagIcon: UIImageView = {
            let i = UIImageView(image: R.image.ac_feed_hashtag())
            return i
        }()
        
        private lazy var nameLabel: UILabel = {
            let l = UILabel()
            l.font = R.font.nunitoExtraBold(size: 18)
            l.textColor = UIColor.white
            return l
        }()
        
        private lazy var selectedIcon: UIImageView = {
            let i = UIImageView(image: R.image.ac_feed_library_unselected())
            return i
        }()
        
        override var isSelected: Bool {
            didSet {
                selectedIcon.image = isSelected ? R.image.ac_feed_library_selected() : R.image.ac_feed_library_unselected()
            }
        }
        
        override init(frame: CGRect) {
            super.init(frame: .zero)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            contentView.layoutIfNeeded()
        }
        
        private func setupLayout() {
            contentView.backgroundColor = .clear
            
            contentView.addSubviews(views: hashtagIcon, nameLabel, selectedIcon)
            
            hashtagIcon.snp.makeConstraints { (maker) in
                maker.leading.equalToSuperview().inset(Frame.horizontalBleedWidth)
                maker.centerY.equalToSuperview()
            }
            
            nameLabel.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.leading.equalTo(hashtagIcon.snp.trailing).offset(4)
                maker.trailing.lessThanOrEqualTo(selectedIcon.snp.leading).offset(-4)
            }
            
            selectedIcon.snp.makeConstraints { (maker) in
                maker.trailing.equalToSuperview().inset(Frame.horizontalBleedWidth)
                maker.centerY.equalToSuperview()
            }
        }
        
        func configCell(with topic: Entity.SummaryTopic) {
            
            nameLabel.text = topic.topicName
            
        }
        
    }
    
}

extension Feed.SelectTopicViewController {
    
    class VideoThumbnailView: UIView {
        
        private lazy var backgroundIV: UIImageView = {
            let iv = UIImageView()
            iv.contentMode = .scaleAspectFill
            iv.clipsToBounds = true
            return iv
        }()
        
        private lazy var blurView: UIVisualEffectView = {
            let b = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
            return b
        }()
        
        private lazy var thumbnailIV: UIImageView = {
            let iv = UIImageView()
            iv.contentMode = .scaleAspectFit
            return iv
        }()
        
        var image: UIImage? = nil {
            didSet {
                backgroundIV.image = image
                thumbnailIV.image = image
            }
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setUpLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setUpLayout() {
            
            addSubviews(views: backgroundIV, blurView, thumbnailIV)
            
            backgroundIV.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
            
            blurView.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
            
            thumbnailIV.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
        }
        
    }
    
}
