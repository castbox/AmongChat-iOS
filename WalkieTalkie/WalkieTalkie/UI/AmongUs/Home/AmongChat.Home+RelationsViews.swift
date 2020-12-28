//
//  AmongChat.Home+RelationsViews.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/12/25.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

extension AmongChat.Home {
    
    class FriendCell: UICollectionViewCell {
        
        private lazy var avatarIV: UIImageView = {
            let iv = UIImageView()
            iv.layer.cornerRadius = 20
            iv.layer.masksToBounds = true
            return iv
        }()
        
        private lazy var nameLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 16)
            lb.textColor = .white
            return lb
        }()
        
        private lazy var statusLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoBold(size: 14)
            lb.textColor = UIColor(hex6: 0x898989)
            return lb
        }()
        
        private lazy var joinBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 14)
            btn.setTitleColor(UIColor.black, for: .normal)
            btn.backgroundColor = UIColor(hex6: 0xFFF000)
            btn.setTitle(R.string.localizable.socialJoinAction().uppercased(), for: .normal)
            btn.layer.masksToBounds = true
            btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
            return btn
        }()
        
        private lazy var lockedIcon: UIImageView = {
            let iv = UIImageView(image: R.image.ac_home_friends_locked())
            return iv
        }()
        
        private lazy var followBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 14)
            btn.setTitleColor(UIColor(hex6: 0xFFF000), for: .normal)
            btn.setTitleColor(UIColor(hex6: 0x898989), for: .disabled)
            btn.layer.borderColor = UIColor(hex6: 0xFFF000).cgColor
            btn.setTitle(R.string.localizable.channelUserListFollow(), for: .normal)
            btn.setTitle(R.string.localizable.profileFollowing(), for: .disabled)
            btn.layer.masksToBounds = true
            return btn
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
            
            contentView.addSubviews(views: avatarIV, nameLabel, statusLabel, joinBtn, followBtn, lockedIcon)
            
            avatarIV.snp.makeConstraints { (maker) in
                maker.width.height.equalTo(40)
                maker.centerY.equalToSuperview()
                maker.left.equalToSuperview().offset(20)
            }
            
            let textLayout = UILayoutGuide()
            contentView.addLayoutGuide(textLayout)
            
            let buttonLayout = UILayoutGuide()
            contentView.addLayoutGuide(buttonLayout)
            buttonLayout.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.right.equalToSuperview().inset(20)
            }
            
            textLayout.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.left.equalTo(avatarIV.snp.right).offset(12)
                maker.right.equalTo(buttonLayout.snp.left).offset(-20)
            }
            
            nameLabel.snp.makeConstraints { (maker) in
                maker.left.top.right.equalTo(textLayout)
            }
            
            statusLabel.snp.makeConstraints { (maker) in
                maker.top.equalTo(nameLabel.snp.bottom)
                maker.left.right.bottom.equalTo(textLayout)
            }
            
            followBtn.snp.makeConstraints { (maker) in
                maker.edges.equalTo(buttonLayout)
            }
            
            joinBtn.snp.makeConstraints { (maker) in
                maker.top.bottom.right.equalTo(buttonLayout)
            }
            
            lockedIcon.snp.makeConstraints { (maker) in
                maker.right.centerY.equalTo(buttonLayout)
            }
            
        }
        
    }
    
    class FriendSectionHeader: UICollectionReusableView {
        
        private var titleLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 16)
            lb.textColor = UIColor(hex6: 0x898989)
            lb.text = R.string.localizable.amongChatHomeFriendsOnlineTitle()
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
            addSubviews(views: titleLabel)
            titleLabel.snp.makeConstraints { (maker) in
                maker.top.bottom.equalToSuperview()
                maker.left.right.equalToSuperview().inset(20)
            }
        }
    }
    
    class FriendShareFooter: UICollectionReusableView {
        
        private lazy var icon: UIImageView = {
            let iv = UIImageView(image: R.image.ac_home_invite())
            iv.backgroundColor = .clear
            return iv
        }()
        
        private lazy var titleLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 16)
            lb.textColor = UIColor(hex6: 0x898989)
            lb.text = R.string.localizable.amongChatHomeFriendsShareTitle()
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
            addSubviews(views: icon, titleLabel)
            icon.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.left.equalToSuperview().offset(20)
                maker.width.height.equalTo(40)
            }
            
            titleLabel.snp.makeConstraints { (maker) in
                maker.left.equalTo(icon.snp.right).offset(12)
                maker.centerY.equalToSuperview()
                maker.right.equalToSuperview().offset(-20)
            }
        }
    }
    
}
