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
        
        typealias OuterBorderdImageView = Social.Widgets.OuterBorderdImageView
        private lazy var coverIV: OuterBorderdImageView = {
            let iv = OuterBorderdImageView()
            iv.contentMode = .scaleAspectFill
            iv.a_cornerRadius = 12
            iv.a_borderWidth = 4
            iv.a_borderColor = UIColor.white.alpha(0.7)
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
            btn.titleLabel?.adjustsFontSizeToFitWidth = true
            btn.setTitleColor(UIColor.black, for: .normal)
            btn.backgroundColor = UIColor(hex6: 0xFFF000)
            btn.setTitle(R.string.localizable.amongChatHomeTeamUp(), for: .normal)
            btn.layer.masksToBounds = true
            btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
            btn.isUserInteractionEnabled = false
            btn.titleLabel?.adjustsFontSizeToFitWidth = true
            return btn
        }()
        
        private lazy var nameLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.bungeeRegular(size: 20)
            lb.textColor = .white
            lb.numberOfLines = 2
            lb.adjustsFontSizeToFitWidth = true
            return lb
        }()
        
        private lazy var nowPlayingLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoSemiBold(size: 16)
            lb.textColor = .white
            lb.adjustsFontSizeToFitWidth = true
            return lb
        }()
                
        override var isHighlighted: Bool {
            didSet {
                if isHighlighted {
                    UIView.animate(withDuration: 0.2, delay: 0, options: .transitionCurlUp, animations: {
                        self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                    }, completion: nil)
                } else {
                    UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
                        self.transform = .identity
                    }, completion: nil)
                }
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
            teamUpBtn.layer.cornerRadius = teamUpBtn.bounds.height / 2
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
                maker.leading.equalToSuperview().inset(16)
                maker.bottom.equalToSuperview().inset(20)
                maker.width.equalTo(coverIV.snp.height).multipliedBy(1)
            }
            
            nameLabel.snp.makeConstraints { (maker) in
                maker.leading.equalTo(coverIV.snp.trailing).offset(12)
                maker.trailing.equalToSuperview().inset(12)
                maker.top.equalTo(bgIV.snp.top).offset(14)
            }
            
            nowPlayingLabel.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalTo(nameLabel)
                maker.top.equalTo(nameLabel.snp.bottom).offset(1)
            }
            
            teamUpBtn.snp.makeConstraints { (maker) in
                maker.trailing.bottom.equalToSuperview().inset(12)
                maker.leading.greaterThanOrEqualTo(nameLabel.snp.leading)
                maker.height.equalTo(36)
            }
            
            if UIScreen.main.bounds.width < 375 {
                
                nameLabel.font = R.font.bungeeRegular(size: 16)
                nowPlayingLabel.font = R.font.nunitoSemiBold(size: 12)
                teamUpBtn.titleLabel?.font = R.font.nunitoExtraBold(size: 14)
                teamUpBtn.snp.remakeConstraints { (maker) in
                    maker.trailing.bottom.equalToSuperview().inset(12)
                    maker.leading.greaterThanOrEqualTo(nameLabel.snp.leading)
                    maker.height.equalTo(30)
                }
            }
            
        }
    }
    
}

extension AmongChat.Home.TopicCell {
    
    func bindViewModel(_ topic: AmongChat.Home.TopicViewModel) {
        
        nameLabel.text = topic.name
        nowPlayingLabel.text = topic.nowPlaying
        
        coverIV.setImage(with: topic.coverUrl)
        bgIV.setImage(with: topic.bgUrl)        
    }
    
}
