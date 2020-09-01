//
//  Social.UserList.Widgets.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/9/1.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift

protocol SocialUserListView {
    func configView(with viewModel: Social.UserList.UserViewModel)
}

extension Social.UserList {
    
    class FollowingUserCell: UITableViewCell, SocialUserListView {
        
        private lazy var userView: UserView = {
            let v = UserView()
            return v
        }()
        
        private lazy var joinChannelBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.addTarget(self, action: #selector(onJoinChannelBtn), for: .primaryActionTriggered)
            return btn
        }()
        
        private lazy var inviteBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.addTarget(self, action: #selector(onInviteBtn), for: .primaryActionTriggered)
            return btn
        }()
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupLayout() {
            selectionStyle = .none
            contentView.addSubviews(views: userView, joinChannelBtn, inviteBtn)
            
            userView.snp.makeConstraints { (maker) in
                maker.top.bottom.equalToSuperview()
                maker.left.equalToSuperview().offset(15)
                maker.right.equalTo(inviteBtn.snp.left).offset(-10)
            }
            
            joinChannelBtn.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.right.equalToSuperview().inset(14.5)
            }
            
            inviteBtn.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.right.equalTo(joinChannelBtn.snp.left).offset(-15)
            }
        }
        
        @objc
        private func onJoinChannelBtn() {
            
        }
        
        @objc
        private func onInviteBtn() {
            
        }
        
        func configView(with viewModel: Social.UserList.UserViewModel) {
            userView.configView(with: viewModel)
        }
        
    }
    
}

extension Social.UserList {
    
    class FollowerUserCell: UITableViewCell, SocialUserListView {
        
        private lazy var userView: UserView = {
            let v = UserView()
            return v
        }()
        
        private lazy var followBtn: UIButton = {
            let btn = WalkieButton(type: .custom)
            btn.addTarget(self, action: #selector(onFollowBtn), for: .primaryActionTriggered)
            btn.backgroundColor = .white
            btn.titleLabel?.font = R.font.nunitoSemiBold(size: 14)
            btn.layer.cornerRadius = 15
            btn.setTitle(R.string.localizable.socialFollowerFollowAction(), for: .normal)
            btn.setTitleColor(UIColor(hex6: 0x000000, alpha: 0.8), for: .normal)
            btn.appendKern()
            return btn
        }()
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupLayout() {
            selectionStyle = .none
            contentView.addSubviews(views: userView, followBtn)
            
            userView.snp.makeConstraints { (maker) in
                maker.top.bottom.equalToSuperview()
                maker.left.equalToSuperview().offset(15)
                maker.right.equalTo(followBtn.snp.left).offset(-15)
            }
            
            followBtn.snp.makeConstraints { (maker) in
                maker.height.equalTo(30)
                maker.right.equalToSuperview().inset(15)
                maker.centerY.equalToSuperview()
                maker.width.equalTo(107)
            }
            
        }
        
        @objc
        private func onFollowBtn() {
            
        }
        
        func configView(with viewModel: Social.UserList.UserViewModel) {
            userView.configView(with: viewModel)
        }

    }
    
}

extension Social.UserList {
    
    class BlockedUserCell: UITableViewCell, SocialUserListView {
        
        private lazy var avatarIV: UIImageView = {
            let iv = UIImageView()
            iv.layer.cornerRadius = 20
            iv.layer.masksToBounds = true
            return iv
        }()
                
        private lazy var usernameLabel: WalkieLabel = {
            let lb = WalkieLabel()
            lb.font = R.font.nunitoBold(size: 16)
            lb.textColor = UIColor(hex6: 0x333333, alpha: 1.0)
            return lb
        }()
                
        private lazy var actionBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.addTarget(self, action: #selector(onActionBtn), for: .primaryActionTriggered)
            return btn
        }()
        
        private var avatarDisposable: Disposable? = nil
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func prepareForReuse() {
            super.prepareForReuse()
            avatarDisposable?.dispose()
        }
        
        private func setupLayout() {
            selectionStyle = .none
            contentView.addSubviews(views: avatarIV, usernameLabel, actionBtn)
            
            avatarIV.snp.makeConstraints { (maker) in
                maker.width.height.equalTo(40)
                maker.centerY.equalToSuperview()
                maker.left.equalToSuperview().offset(15)
            }
            
            usernameLabel.snp.makeConstraints { (maker) in
                maker.left.equalTo(avatarIV.snp.right).offset(15)
                maker.right.equalTo(actionBtn.snp.left).offset(-15)
                maker.height.equalTo(21)
                maker.centerY.equalToSuperview()
            }
                        
            actionBtn.snp.makeConstraints { (maker) in
                maker.width.height.equalTo(25)
                maker.right.equalToSuperview().inset(15)
                maker.centerY.equalToSuperview()
            }
            
        }
        
        @objc
        private func onActionBtn() {
            
        }
        
        func configView(with viewModel: Social.UserList.UserViewModel) {
            usernameLabel.text = viewModel.username
            usernameLabel.appendKern()
            avatarDisposable = viewModel.avatar.subscribe(onSuccess: { [weak self] (image) in
                self?.avatarIV.image = image
            })
        }

    }
    
}

extension Social.UserList {
    
    class UserView: UIView, SocialUserListView {
        
        private lazy var avatarIV: UIImageView = {
            let iv = UIImageView()
            iv.layer.cornerRadius = 20
            iv.layer.masksToBounds = true
            return iv
        }()
                
        private lazy var usernameLabel: WalkieLabel = {
            let lb = WalkieLabel()
            lb.font = R.font.nunitoBold(size: 16)
            lb.textColor = UIColor(hex6: 0x333333, alpha: 1.0)
            return lb
        }()
        
        private lazy var statusLabel: WalkieLabel = {
            let lb = WalkieLabel()
            lb.font = R.font.nunitoRegular(size: 14)
            lb.textColor = UIColor(hex6: 0x000000, alpha: 0.54)
            return lb
        }()
        
        private var avatarDisposable: Disposable? = nil
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupLayout() {
            addSubviews(views: avatarIV, usernameLabel, statusLabel)
            
            avatarIV.snp.makeConstraints { (maker) in
                maker.width.height.equalTo(40)
                maker.centerY.equalToSuperview()
                maker.left.equalToSuperview().offset(15)
            }
            
            let textLayoutGuide = UILayoutGuide()
            addLayoutGuide(textLayoutGuide)
            
            textLayoutGuide.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.left.equalTo(avatarIV.snp.right).offset(15)
                maker.right.equalToSuperview()
            }
            
            usernameLabel.snp.makeConstraints { (maker) in
                maker.left.top.equalTo(textLayoutGuide)
                maker.height.equalTo(21)
            }
            
            statusLabel.snp.makeConstraints { (maker) in
                maker.left.bottom.equalTo(textLayoutGuide)
                maker.right.lessThanOrEqualTo(textLayoutGuide)
                maker.top.equalTo(usernameLabel.snp.bottom).offset(2)
                maker.height.equalTo(19)
            }
            
        }
        
        func configView(with viewModel: Social.UserList.UserViewModel) {
            avatarDisposable?.dispose()
            
            usernameLabel.text = viewModel.username
            usernameLabel.appendKern()
            statusLabel.text = viewModel.status
            statusLabel.appendKern()
            
            avatarDisposable = viewModel.avatar.subscribe(onSuccess: { [weak self] (image) in
                self?.avatarIV.image = image
            })
        }
        
    }
    
}
