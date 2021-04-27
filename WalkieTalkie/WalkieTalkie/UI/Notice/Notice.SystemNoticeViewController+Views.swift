//
//  Notice.SystemNoticeViewController+Views.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/4/27.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

extension Notice.SystemNoticeViewController {
    
    class MessageCell: UICollectionViewCell {
        
        private lazy var timeLabel: UILabel = {
            let l = UILabel()
            l.font = R.font.nunitoBold(size: 14)
            l.textAlignment = .center
            l.textColor = UIColor(hex6: 0x595959)
            return l
        }()
        
        private lazy var container: UIView = {
            let v = UIView()
            v.backgroundColor = UIColor(hex6: 0x202020)
            v.layer.cornerRadius = 12
            v.clipsToBounds = true
            return v
        }()
        
        private lazy var aboveTextImageView: UIImageView = {
            let i = UIImageView()
            i.clipsToBounds = true
            i.contentMode = .scaleAspectFill
            return i
        }()
        
        private lazy var belowTextImageView: UIImageView = {
            let i = UIImageView()
            i.clipsToBounds = true
            i.contentMode = .scaleAspectFit
            return i
        }()
        
        private lazy var messageTitleLabel: UILabel = {
            let l = UILabel()
            l.font = R.font.nunitoExtraBold(size: 20)
            l.textColor = UIColor(hex6: 0xFFFFFF)
            l.numberOfLines = 0
            return l
        }()
        
        private lazy var messageTextLabel: UILabel = {
            let l = UILabel()
            l.font = R.font.nunitoBold(size: 14)
            l.textColor = UIColor(hex6: 0x898989)
            l.numberOfLines = 0
            return l
        }()
        
        private lazy var actionView: UIView = {
            
            let v = UIView()
            
            let line: UIView = {
                let v = UIView()
                v.backgroundColor = UIColor(hex6: 0xFFFFFF, alpha: 0.06)
                return v
            }()
            
            let titleLabel: UILabel = {
                let l = UILabel()
                l.font = R.font.nunitoExtraBold(size: 16)
                l.textColor = UIColor(hex6: 0x898989)
                l.text = R.string.localizable.amongChatNoticeClickToGo()
                return l
            }()
            
            let icon = UIImageView(image: R.image.ac_notice_next())
            
            v.addSubviews(views: line, titleLabel, icon)
            
            line.snp.makeConstraints { (maker) in
                maker.leading.top.trailing.equalToSuperview()
                maker.height.equalTo(1)
            }
            
            titleLabel.snp.makeConstraints { (maker) in
                maker.leading.equalTo(16)
                maker.top.equalTo(15)
                maker.centerY.equalToSuperview()
                maker.trailing.equalTo(icon.snp.leading).offset(-8)
                maker.height.equalTo(22)
            }
            
            icon.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.leading.equalTo(titleLabel.snp.trailing).offset(8)
                maker.trailing.lessThanOrEqualTo(-16)
            }
            
            return v
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
            
            container.addSubviews(views: aboveTextImageView, messageTitleLabel, messageTextLabel, belowTextImageView, actionView)
            
            aboveTextImageView.snp.makeConstraints { (maker) in
                maker.leading.top.trailing.equalToSuperview()
                maker.height.equalTo(170)
            }
            
            messageTitleLabel.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(16)
                maker.top.equalTo(aboveTextImageView.snp.bottom).offset(16)
            }
            
            messageTextLabel.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalTo(messageTitleLabel)
                maker.top.equalTo(messageTitleLabel.snp.bottom).offset(8)
            }
            
            belowTextImageView.snp.makeConstraints { (maker) in
                maker.leading.equalTo(messageTitleLabel)
                maker.top.equalTo(messageTextLabel.snp.bottom).offset(12)
                maker.width.height.equalTo(80)
            }
            
            actionView.snp.makeConstraints { (maker) in
                maker.leading.bottom.trailing.equalToSuperview()
                maker.top.equalTo(belowTextImageView.snp.bottom).offset(24)
            }
            
            contentView.addSubviews(views: timeLabel, container)
            
            timeLabel.snp.makeConstraints { (maker) in
                maker.leading.top.trailing.equalToSuperview()
                maker.height.equalTo(19)
            }

            container.snp.makeConstraints { (maker) in
                maker.top.equalTo(timeLabel.snp.bottom).offset(8)
                maker.leading.trailing.bottom.equalToSuperview()
            }
            
        }
        
    }
    
    
}
