//
//  AmongChat.Home.TopicCell.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/12/18.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift

extension AmongChat.Home {
    
    class TopicCell: UICollectionViewCell {
        
        private lazy var coverIV: UIImageView = {
            let iv = UIImageView()
            iv.contentMode = .scaleAspectFill
            iv.layer.cornerRadius = 12
            iv.layer.masksToBounds = true
            iv.layer.borderWidth = 4
            iv.layer.borderColor = UIColor.white.alpha(0.7).cgColor
            return iv
        }()
        
        private lazy var bgIV: UIImageView = {
            let iv = UIImageView()
            iv.contentMode = .scaleAspectFill
            iv.layer.cornerRadius = 12
            iv.layer.masksToBounds = true
            return iv
        }()
        
        private lazy var teamUpBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 16)
            btn.setTitleColor(UIColor.black, for: .normal)
            btn.backgroundColor = UIColor(hex6: 0xFFF000)
            btn.setTitle(R.string.localizable.amongChatHomeTeamUp(), for: .normal)
            btn.layer.cornerRadius = 18
            btn.layer.masksToBounds = true
            return btn
        }()
        
        private lazy var nameLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 24)
            lb.textColor = .white
            return lb
        }()
        
        private lazy var nowPlayingLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoSemiBold(size: 16)
            lb.textColor = .white
            return lb
        }()
                                
        override init(frame: CGRect) {
            super.init(frame: .zero)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
                        
        private func setupLayout() {
            contentView.backgroundColor = .clear
            
            contentView.addSubviews(views: bgIV, coverIV, nameLabel, nowPlayingLabel, teamUpBtn)
            
            bgIV.snp.makeConstraints { (maker) in
                maker.left.right.bottom.equalToSuperview()
                maker.top.equalToSuperview().inset(28)
            }
            
            coverIV.snp.makeConstraints { (maker) in
                maker.top.equalToSuperview()
                maker.left.equalToSuperview().inset(16)
                maker.bottom.equalToSuperview().inset(20)
                maker.width.equalTo(coverIV.snp.height).multipliedBy(1)
            }
            
            nameLabel.snp.makeConstraints { (maker) in
                maker.left.equalTo(coverIV.snp.right).offset(12)
                maker.right.equalToSuperview().inset(12)
                maker.top.equalTo(bgIV.snp.top).offset(8)
            }
            
            nowPlayingLabel.snp.makeConstraints { (maker) in
                maker.left.right.equalTo(nameLabel)
                maker.top.equalTo(nameLabel.snp.bottom).offset(1)
            }
            
            teamUpBtn.snp.makeConstraints { (maker) in
                maker.right.bottom.equalToSuperview().inset(12)
                maker.height.equalTo(36)
                maker.width.greaterThanOrEqualTo(106)
            }
            
        }
    }
    
}

extension AmongChat.Home.TopicCell {
    
    func bindViewModel(_ topic: AmongChat.Home.TopicViewModel) {
        
        nameLabel.text = topic.name
        nowPlayingLabel.text = topic.nowPlaying
        
        coverIV.setImage(with: topic.cover)
        bgIV.setImage(with: topic.bg)
    }
    
}
