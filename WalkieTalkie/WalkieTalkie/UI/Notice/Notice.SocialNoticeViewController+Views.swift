//
//  Notice.SocialNoticeViewController+Views.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/4/27.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

extension Notice.SocialNoticeViewController {
    
    class GroupMessageCell: UICollectionViewCell {
        
        private lazy var messageImageView: UIImageView = {
            let i = UIImageView()
            i.layer.cornerRadius = 12
            i.clipsToBounds = true
            i.contentMode = .scaleAspectFill
            return i
        }()
        
        private lazy var messageTitleLabel: UILabel = {
            let l = UILabel()
            l.font = R.font.nunitoExtraBold(size: 20)
            l.textColor = UIColor(hex6: 0xFFFFFF)
            return l
        }()
        
        private lazy var messageTextLabel: UILabel = {
            let l = UILabel()
            l.font = R.font.nunitoBold(size: 14)
            l.textColor = UIColor(hex6: 0x898989)
            l.numberOfLines = 2
            l.adjustsFontSizeToFitWidth = true
            return l
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
            
            contentView.addSubviews(views: messageImageView, messageTitleLabel, messageTextLabel)
            
            messageImageView.snp.makeConstraints { (maker) in
                maker.leading.top.bottom.equalToSuperview()
                maker.width.equalTo(messageImageView.snp.height)
            }
            
            messageTitleLabel.snp.makeConstraints { (maker) in
                maker.top.equalToSuperview()
                maker.leading.equalTo(messageImageView.snp.trailing).offset(12)
                maker.trailing.equalToSuperview()
                maker.height.equalTo(27)
            }
            
            messageTextLabel.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalTo(messageTitleLabel)
                maker.top.equalTo(messageTitleLabel.snp.bottom).offset(3)
                maker.bottom.equalToSuperview()
            }
        }
        
    }

}

extension Notice.SocialNoticeViewController {
    
    class UserMessageCell: UICollectionViewCell {
        
        private lazy var messageImageView: UIImageView = {
            let i = UIImageView()
            i.clipsToBounds = true
            i.contentMode = .scaleAspectFill
            return i
        }()
        
        private lazy var messageTitleLabel: UILabel = {
            let l = UILabel()
            l.font = R.font.nunitoExtraBold(size: 20)
            l.textColor = UIColor(hex6: 0xFFFFFF)
            return l
        }()
        
        private lazy var messageTextLabel: UILabel = {
            let l = UILabel()
            l.font = R.font.nunitoBold(size: 14)
            l.textColor = UIColor(hex6: 0x898989)
            l.numberOfLines = 0
            return l
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
            
            contentView.addSubviews(views: messageImageView, messageTitleLabel, messageTextLabel)
            
            messageImageView.snp.makeConstraints { (maker) in
                maker.leading.top.bottom.equalToSuperview()
                maker.width.height.equalTo(64)
            }
            
            messageTitleLabel.snp.makeConstraints { (maker) in
                maker.top.equalToSuperview()
                maker.leading.equalTo(messageImageView.snp.trailing).offset(12)
                maker.trailing.equalToSuperview()
                maker.height.equalTo(27)
            }
            
            messageTextLabel.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalTo(messageTitleLabel)
                maker.top.equalTo(messageTitleLabel.snp.bottom).offset(3)
                maker.bottom.equalToSuperview()
            }
        }
        
    }

}
