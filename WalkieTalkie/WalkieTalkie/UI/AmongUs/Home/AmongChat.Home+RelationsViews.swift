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
        
        private lazy var avatarTap: UITapGestureRecognizer = {
            let g = UITapGestureRecognizer()
            avatarIV.isUserInteractionEnabled = true
            avatarIV.addGestureRecognizer(g)
            return g
        }()
        
        private var avatarTapDisposable: Disposable? = nil
        
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
                maker.leading.equalToSuperview()
            }
            
            let textLayout = UILayoutGuide()
            addLayoutGuide(textLayout)
                        
            textLayout.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.leading.equalTo(avatarIV.snp.trailing).offset(12)
                maker.trailing.equalToSuperview()
            }
            
            nameLabel.snp.makeConstraints { (maker) in
                maker.leading.top.trailing.equalTo(textLayout)
            }
            
            statusLabel.snp.makeConstraints { (maker) in
                maker.top.equalTo(nameLabel.snp.bottom)
                maker.leading.trailing.bottom.equalTo(textLayout)
            }
            
        }
        
        func bind(viewModel: PlayingViewModel, onAvatarTap: @escaping () -> Void) {
            
            avatarIV.setImage(with: URL(string: viewModel.userAvatarUrl), placeholder: R.image.ac_profile_avatar())
            
            nameLabel.text = viewModel.userName
            
            statusLabel.text = viewModel.playingStatus
            
            avatarTapDisposable?.dispose()
            avatarTapDisposable = avatarTap.rx.event.subscribe(onNext: { (_) in
                onAvatarTap()
            })
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
        
        private lazy var lockedIcon: UIButton = {
            let btn = UIButton(type: .custom)
            btn.setImage(R.image.ac_home_friends_locked(), for: .normal)
            return btn
        }()
        private var lockedDisposable: Disposable? = nil
        
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
                maker.trailing.equalToSuperview().inset(20)
                maker.height.equalTo(32)
            }
            
            userView.snp.makeConstraints { (maker) in
                maker.leading.equalToSuperview().offset(20)
                maker.top.bottom.equalToSuperview()
                maker.trailing.lessThanOrEqualTo(buttonLayout.snp.leading).offset(-20)
            }
            
            joinBtn.snp.makeConstraints { (maker) in
                maker.edges.equalTo(buttonLayout)
            }
            
            lockedIcon.snp.makeConstraints { (maker) in
                maker.trailing.centerY.equalTo(buttonLayout)
            }
            
        }
        
        func bind(viewModel: PlayingViewModel,
                  onJoin: @escaping (_ roomId: String, _ topicId: String) -> Void,
                  onAvatarTap: @escaping () -> Void) {
            userView.bind(viewModel: viewModel, onAvatarTap: onAvatarTap)
            
            if let state = viewModel.roomState {
                joinBtn.isHidden = !(state == .public)
                lockedIcon.isHidden = !(state == .private)
            } else {
                joinBtn.isHidden = true
                lockedIcon.isHidden = true
            }
            
            joinDisposable?.dispose()
            joinDisposable = joinBtn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { (_) in
                    guard let roomId = viewModel.roomId,
                          let topicId = viewModel.roomTopicId else {
                        return
                    }
                    onJoin(roomId, topicId)
                })
            
            lockedDisposable?.dispose()
            lockedDisposable = lockedIcon.rx.controlEvent(.primaryActionTriggered)
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
                maker.trailing.equalToSuperview().inset(20)
                maker.height.equalTo(32)
            }
            
            userView.snp.makeConstraints { (maker) in
                maker.leading.equalToSuperview().offset(20)
                maker.top.bottom.equalToSuperview()
                maker.trailing.lessThanOrEqualTo(buttonLayout.snp.leading).offset(-20)
            }
            
            followBtn.snp.makeConstraints { (maker) in
                maker.edges.equalTo(buttonLayout)
            }

        }
        
        func bind(viewModel: PlayingViewModel,
                  onFollow: @escaping () -> Void,
                  onAvatarTap: @escaping () -> Void) {
            userView.bind(viewModel: viewModel, onAvatarTap: onAvatarTap)
            followDisposable?.dispose()
            followDisposable = followBtn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { (_) in
                    onFollow()
                })
        }

        
    }
    
    class FriendSectionHeader: UICollectionReusableView {
        
        private var titleLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 20)
            lb.textColor = .white
            lb.adjustsFontSizeToFitWidth = true
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
                maker.leading.trailing.equalToSuperview().inset(20)
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
            lb.textColor = UIColor(hex6: 0xFFFFFF)
            lb.text = R.string.localizable.amongChatHomeFriendsShareTitle()
            lb.numberOfLines = 2
            lb.adjustsFontSizeToFitWidth = true
            return lb
        }()
        
        private lazy var rightIcon: UIImageView = {
            let i = UIImageView(image: R.image.ac_right_arrow())
            return i
        }()
        
        private lazy var contentView: UIView = {
            let v = UIView()
            v.backgroundColor = UIColor(hex6: 0x222222)
            v.layer.cornerRadius = 12
            return v
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
            contentView.addSubviews(views: icon, titleLabel, rightIcon)
            addSubviews(views: contentView)
            icon.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.leading.equalToSuperview().offset(16)
                maker.width.height.equalTo(36)
            }
            
            titleLabel.snp.makeConstraints { (maker) in
                maker.leading.equalTo(icon.snp.trailing).offset(12)
                maker.top.greaterThanOrEqualToSuperview().inset(0)
                maker.centerY.equalToSuperview()
                maker.trailing.equalTo(rightIcon.snp.leading).offset(-16)
            }
            
            rightIcon.snp.makeConstraints { (maker) in
                maker.width.height.equalTo(20)
                maker.centerY.equalToSuperview()
                maker.trailing.equalToSuperview().inset(16)
            }
            
            contentView.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(20)
                maker.top.equalToSuperview().offset(7)
                maker.height.equalTo(68)
            }
            
            isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer()
            addGestureRecognizer(tap)
            let _ = tap.rx.event.bind(onNext: { [weak self] (_) in
                self?.onSelect?()
            })
        }
    }
    
    class EmptyReusableView: UICollectionReusableView {
        
    }
    
}
