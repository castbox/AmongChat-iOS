//
//  Social.ProfileViewController+Feed.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/6/1.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import Photos
import RxSwift

extension Social.ProfileViewController {
    
    class FeedCell: UICollectionViewCell {
                
        private lazy var imageView: UIImageView = {
            let i = UIImageView()
            i.contentMode = .scaleAspectFill
            return i
        }()
        
        private lazy var playIcon: UIImageView = {
            let i = UIImageView(image: R.image.ac_profile_feed_play_count())
            return i
        }()
                
        private lazy var playCountLabel: UILabel = {
            let l = UILabel()
            l.font = R.font.nunitoExtraBold(size: 14)
            l.textColor = .white
            return l
        }()
        
        private lazy var gradientMusk: CAGradientLayer = {
            let l = CAGradientLayer()
            l.colors = [UIColor(hex6: 0x000000, alpha: 0).cgColor, UIColor(hex6: 0x000000, alpha: 1).cgColor]
            l.startPoint = CGPoint(x: 0.5, y: 0.5)
            l.endPoint = CGPoint(x: 0.5, y: 1)
            l.locations = [0, 1]
            l.opacity = 0.5
            return l
        }()
                        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setUpLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            contentView.layoutIfNeeded()
            gradientMusk.frame = contentView.bounds
        }
        
        private func setUpLayout() {
            
            backgroundColor = .clear
            contentView.backgroundColor = .clear
            contentView.clipsToBounds = true
            contentView.layer.cornerRadius = 12
            
            contentView.addSubviews(views: imageView, playIcon, playCountLabel)
            
            contentView.layer.insertSublayer(gradientMusk, above: imageView.layer)
            
            imageView.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
                        
            playIcon.snp.makeConstraints { (maker) in
                maker.leading.equalToSuperview().offset(7)
                maker.bottom.equalToSuperview().offset(-6)
            }
            
            playCountLabel.snp.makeConstraints { (maker) in
                maker.leading.equalTo(playIcon.snp.trailing).offset(2)
                maker.trailing.lessThanOrEqualToSuperview().offset(-7)
                maker.centerY.equalTo(playIcon)
            }
            
        }
        
        func configCell(with feed: Entity.Feed) {
            playCountLabel.text = "\(feed.playCountValue)"
            imageView.setImage(with: feed.img)
        }
        
    }

}

extension Social.ProfileViewController {
    class SegmentedContainerCell: UICollectionViewCell {}
}
