//
//  AmongChat.Home+RelationsViews.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/12/25.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift

extension AmongChat.Home {
    
    class UserView: UIView {
        
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
        
        override init(frame: CGRect) {
            super.init(frame: .zero)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupLayout() {
            backgroundColor = .clear
            
            addSubviews(views: avatarIV, nameLabel, statusLabel)
            
            avatarIV.snp.makeConstraints { (maker) in
                maker.width.height.equalTo(40)
                maker.centerY.equalToSuperview()
                maker.left.equalToSuperview()
            }
            
            let textLayout = UILayoutGuide()
            addLayoutGuide(textLayout)
                        
            textLayout.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.left.equalTo(avatarIV.snp.right).offset(12)
                maker.right.equalToSuperview()
            }
            
            nameLabel.snp.makeConstraints { (maker) in
                maker.left.top.right.equalTo(textLayout)
            }
            
            statusLabel.snp.makeConstraints { (maker) in
                maker.top.equalTo(nameLabel.snp.bottom)
                maker.left.right.bottom.equalTo(textLayout)
            }
            
        }
        
        func bind(viewModel: PlayingViewModel) {
            
            avatarIV.setImage(with: URL(string: viewModel.userAvatarUrl))
            
            nameLabel.text = viewModel.userName
            
            statusLabel.text = viewModel.playingStatus
            
        }
        
    }
    
    class FriendCell: UICollectionViewCell {
        
        private lazy var userView: UserView = {
            let v = UserView()
            return v
        }()
                
        private lazy var joinBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 14)
            btn.setTitleColor(UIColor.black, for: .normal)
            btn.backgroundColor = UIColor(hex6: 0xFFF000)
            btn.setTitle(R.string.localizable.socialJoinAction().uppercased(), for: .normal)
            btn.layer.masksToBounds = true
            btn.layer.cornerRadius = 16
            btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
            return btn
        }()
        
        private var joinDisposable: Disposable? = nil
        
        private lazy var lockedIcon: UIImageView = {
            let iv = UIImageView(image: R.image.ac_home_friends_locked())
            return iv
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
            
            contentView.addSubviews(views: userView, joinBtn, lockedIcon)
                        
            let buttonLayout = UILayoutGuide()
            contentView.addLayoutGuide(buttonLayout)
            buttonLayout.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.right.equalToSuperview().inset(20)
                maker.height.equalTo(32)
            }
            
            userView.snp.makeConstraints { (maker) in
                maker.left.equalToSuperview().offset(20)
                maker.top.bottom.equalToSuperview()
                maker.right.lessThanOrEqualTo(buttonLayout.snp.left).offset(-20)
            }
            
            joinBtn.snp.makeConstraints { (maker) in
                maker.edges.equalTo(buttonLayout)
            }
            
            lockedIcon.snp.makeConstraints { (maker) in
                maker.right.centerY.equalTo(buttonLayout)
            }
            
        }
        
        func bind(viewModel: PlayingViewModel, onJoin: @escaping (_ roomId: String, _ topicId: String) -> Void) {
            userView.bind(viewModel: viewModel)
            joinBtn.isHidden = !viewModel.joinable
            lockedIcon.isHidden = viewModel.joinable
            joinDisposable?.dispose()
            joinDisposable = joinBtn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { (_) in
                    guard let roomId = viewModel.roomId,
                          let topicId = viewModel.roomTopicId else {
                        return
                    }
                    onJoin(roomId, topicId)
                })
        }
        
    }
    
    class SuggestionCell: UICollectionViewCell {
        
        private lazy var userView: UserView = {
            let v = UserView()
            return v
        }()
        
        private lazy var followBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 14)
            btn.setTitleColor(UIColor(hex6: 0xFFF000), for: .normal)
            btn.setTitleColor(UIColor(hex6: 0x898989), for: .disabled)
            btn.layer.borderColor = UIColor(hex6: 0xFFF000).cgColor
            btn.setTitle(R.string.localizable.channelUserListFollow(), for: .normal)
            btn.setTitle(R.string.localizable.profileFollowing(), for: .disabled)
            btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
            btn.layer.masksToBounds = true
            btn.layer.cornerRadius = 16
            btn.layer.borderWidth = 2.5
            return btn
        }()
        private var followDisposable: Disposable? = nil
        
        override init(frame: CGRect) {
            super.init(frame: .zero)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupLayout() {
            contentView.backgroundColor = .clear
            
            contentView.addSubviews(views: userView, followBtn)
            
            let buttonLayout = UILayoutGuide()
            contentView.addLayoutGuide(buttonLayout)
            buttonLayout.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.right.equalToSuperview().inset(20)
                maker.height.equalTo(32)
            }
            
            userView.snp.makeConstraints { (maker) in
                maker.left.equalToSuperview().offset(20)
                maker.top.bottom.equalToSuperview()
                maker.right.lessThanOrEqualTo(buttonLayout.snp.left).offset(-20)
            }
            
            followBtn.snp.makeConstraints { (maker) in
                maker.edges.equalTo(buttonLayout)
            }

        }
        
        func bind(viewModel: PlayingViewModel, onFollow: @escaping (_ uid: Int, _ updateData: @escaping () -> Void) -> Void) {
            userView.bind(viewModel: viewModel)
            
            followBtn.isEnabled = viewModel.followable
            
            if viewModel.followable {
                followBtn.layer.borderColor = followBtn.titleColor(for: .normal)?.cgColor
            } else {
                followBtn.layer.borderColor = followBtn.titleColor(for: .disabled)?.cgColor
            }
            
            followDisposable?.dispose()
            followDisposable = followBtn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { (_) in
                    onFollow(viewModel.uid, {
                        viewModel.updateFollowState()
                    })
                })
        }

        
    }
    
    class FriendSectionHeader: UICollectionReusableView {
        
        private var titleLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 16)
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
            addSubviews(views: titleLabel)
            titleLabel.snp.makeConstraints { (maker) in
                maker.top.bottom.equalToSuperview()
                maker.left.right.equalToSuperview().inset(20)
            }
        }
        
        func configTitle(_ title: String) {
            titleLabel.text = title
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
        
        var onSelect: (() -> Void)? = nil
        
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
                maker.top.equalToSuperview().offset(14.5)
                maker.left.equalToSuperview().offset(20)
                maker.width.height.equalTo(40)
            }
            
            titleLabel.snp.makeConstraints { (maker) in
                maker.left.equalTo(icon.snp.right).offset(12)
                maker.centerY.equalTo(icon)
                maker.right.equalToSuperview().offset(-20)
            }
            
            isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer()
            addGestureRecognizer(tap)
            tap.rx.event.bind(onNext: { [weak self] (_) in
                self?.onSelect?()
            })
        }
    }
    
    class EmptyReusableView: UICollectionReusableView {
        
    }
    
}
