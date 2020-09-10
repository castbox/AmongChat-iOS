//
//  Social.UserList.ActionModal.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/9/1.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

extension Social.UserList {
    
    class ActionModal: WalkieTalkie.ViewController, Modalable {
        
        private lazy var avatarIV: UIImageView = {
            let iv = UIImageView()
            #if DEBUG
            iv.backgroundColor = UIColor(hex6: 0xF8E71C, alpha: 1.0)
            #endif
            iv.layer.cornerRadius = 45
            iv.layer.masksToBounds = true
            return iv
        }()
        
        private lazy var nameLabel: WalkieLabel = {
            let lb = WalkieLabel()
            lb.font = R.font.nunitoSemiBold(size: 20)
            lb.textColor = .black
            return lb
        }()
        
        private lazy var statusLabel: WalkieLabel = {
            let lb = WalkieLabel()
            lb.font = R.font.nunitoRegular(size: 14)
            lb.textColor = UIColor(hex6: 0x000000, alpha: 0.54)
            return lb
        }()
        
        private lazy var friendView: FriendView = {
            let v = FriendView()
            v.contentStyle = .light
            return v
        }()
        
        private lazy var followBackBtn: UIButton = {
            let btn = WalkieButton(type: .custom)
            btn.backgroundColor = UIColor(hex6: 0xFF7989, alpha: 1.0)
            btn.titleLabel?.font = R.font.nunitoSemiBold(size: 14)
            btn.addTarget(self, action: #selector(onFollowBackBtn), for: .primaryActionTriggered)
            btn.layer.cornerRadius = 24
            btn.setTitle(R.string.localizable.socialFollowerFollowAction(), for: .normal)
            btn.setTitleColor(.white, for: .normal)
            btn.appendKern()
            return btn
        }()
        
        private lazy var unblockBtn: UIButton = {
            let btn = WalkieButton(type: .custom)
            btn.backgroundColor = UIColor(hex6: 0xFF7989, alpha: 1.0)
            btn.titleLabel?.font = R.font.nunitoSemiBold(size: 14)
            btn.addTarget(self, action: #selector(onUnblockBtn), for: .primaryActionTriggered)
            btn.layer.cornerRadius = 24
            btn.setTitle(R.string.localizable.socialUnblock(), for: .normal)
            btn.setTitleColor(.white, for: .normal)
            btn.appendKern()
            return btn
        }()
        
        private lazy var joinBtn: UIButton = {
            let btn = WalkieButton(type: .custom)
            btn.backgroundColor = UIColor(hex6: 0xF8E71C, alpha: 1.0)
            btn.titleLabel?.font = R.font.nunitoSemiBold(size: 14)
            btn.addTarget(self, action: #selector(onJoinBtn), for: .primaryActionTriggered)
            btn.layer.cornerRadius = 24
            btn.setTitle("Join", for: .normal)
            btn.setTitleColor(.white, for: .normal)
            btn.appendKern()
            return btn
        }()

        private lazy var inviteBtn: UIButton = {
            let btn = WalkieButton(type: .custom)
            btn.backgroundColor = UIColor(hex6: 0xF8E71C, alpha: 1.0)
            btn.titleLabel?.font = R.font.nunitoSemiBold(size: 14)
            btn.addTarget(self, action: #selector(onInviteBtn), for: .primaryActionTriggered)
            btn.layer.cornerRadius = 24
            btn.setTitle("Invite", for: .normal)
            btn.setTitleColor(.white, for: .normal)
            btn.appendKern()
            return btn
        }()
        
        private lazy var actionBtnStack: UIStackView = {
            let s = UIStackView(arrangedSubviews: self.actionBtns)
            s.spacing = 15
            s.axis = .vertical
            s.distribution = .fillEqually
            return s
        }()
        
        private lazy var moreActionBtn: UIButton = {
            let btn = WalkieButton(type: .custom)
            btn.setImage(R.image.btn_more_action(), for: .normal)
            btn.addTarget(self, action: #selector(onMoreActionBtn), for: .primaryActionTriggered)
            if self.userType == .blocked {
                btn.isHidden = true
            }
            return btn
        }()
        
        private lazy var bgView: UIView = {
            let v = UIView()
            v.backgroundColor = .white
            return v
        }()
        
        private var actionBtns: [UIView] {
            
            switch userType {
            case .following:
                
                var btns: [UIView] = []
                
                let userChannel = viewModel.channelName
                
                if !userChannel.isEmpty {
                    joinBtn.setTitle("Join \(userChannel)", for: .normal)
                    btns.append(joinBtn)
                }
                
                let selfChannel = Social.Module.shared.currentChannelValue
                
                if selfChannel.isEmpty,
                    userChannel.isEmpty,
                    viewModel.online {
                    inviteBtn.isEnabled = false
                }
                
                inviteBtn.setTitle("Invtie", for: .normal)
                
                btns.append(inviteBtn)
                
                return btns
                
            case .follower:
                return [followBackBtn]
            case .blocked:
                return [unblockBtn]
            }
            
        }
        
        private let viewModel: UserViewModel
        private let userType: UserType
        
        init(with userViewModel: UserViewModel, userType: UserType) {
            viewModel = userViewModel
            self.userType = userType
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            view.backgroundColor = .clear
            
            view.addSubviews(views: bgView, avatarIV, nameLabel, statusLabel, friendView, actionBtnStack, moreActionBtn)
            
            bgView.snp.makeConstraints { (maker) in
                maker.left.right.bottom.equalToSuperview()
                maker.top.equalTo(30)
            }
            
            avatarIV.snp.makeConstraints { (maker) in
                maker.top.centerX.equalToSuperview()
                maker.size.equalTo(CGSize(width: 90, height: 90))
            }
            
            nameLabel.snp.makeConstraints { (maker) in
                maker.centerX.equalToSuperview()
                maker.top.equalTo(avatarIV.snp.bottom).offset(10)
                maker.height.equalTo(27)
            }
            
            statusLabel.snp.makeConstraints { (maker) in
                maker.centerX.equalToSuperview()
                maker.top.equalTo(nameLabel.snp.bottom)
                maker.height.equalTo(19)
            }
            
            friendView.snp.makeConstraints { (maker) in
                maker.centerX.equalToSuperview()
                maker.top.equalTo(statusLabel.snp.bottom).offset(5)
            }
            
            let actionBtnStackHeight: CGFloat = {
                let btnHeight: CGFloat = 48
                let btnsCount = actionBtnStack.arrangedSubviews.count
                let spaceCount = btnsCount - 1
                return CGFloat(Float(btnsCount)) * btnHeight + CGFloat(Float(max(spaceCount, 0))) * actionBtnStack.spacing
            }()
                        
            actionBtnStack.snp.makeConstraints { (maker) in
                maker.top.equalTo(nameLabel.snp.bottom).offset(59)
                maker.width.equalTo(225)
                maker.centerX.equalToSuperview()
                maker.height.equalTo(actionBtnStackHeight)
            }
            
            moreActionBtn.snp.makeConstraints { (maker) in
                maker.width.height.equalTo(25)
                maker.top.right.equalTo(bgView).inset(15)
            }
            
            viewModel.avatar.subscribe(onSuccess: { [weak self] (image) in
                self?.avatarIV.image = image
            })
                .disposed(by: bag)
            
            nameLabel.text = viewModel.username
            nameLabel.appendKern()
            
            statusLabel.text = viewModel.status
            statusLabel.appendKern()
            
        }
        
        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            bgView.addCorner(with: 6)
        }
        
        @objc
        private func onFollowBackBtn() {
            defer {
                dismissModal(animated: true)
            }
            guard let selfUid = Settings.shared.loginResult.value?.uid else { return }
            FireStore.shared.addFollowing(viewModel.userId, to: selfUid)
        }
        
        @objc
        private func onUnblockBtn() {
            defer {
                dismissModal(animated: true)
            }
            guard let selfUid = Settings.shared.loginResult.value?.uid else { return }
            FireStore.shared.removeBlockUser(viewModel.userId, from: selfUid)
        }
        
        @objc
        private func onJoinBtn() {
            defer {
                dismissModal(animated: true)
            }
            guard let profile = Settings.shared.firestoreUserProfile.value else { return }
            if viewModel.channelIsSecrete {
                FireStore.shared.sendJoinChannelRequest(from: profile, to: viewModel.userId, toJoin: viewModel.channelId)
            } else if let roomVC = navigationController?.viewControllers.first as? RoomViewController {
                // join channel directly
                roomVC.joinChannel(viewModel.channelId)
            }
        }
        
        @objc
        private func onInviteBtn() {
            defer {
                dismissModal(animated: true)
            }
            guard let selfUid = Settings.shared.loginResult.value?.uid else { return }
            FireStore.shared.sendChannelInvitation(to: viewModel.userId, toJoin: Social.Module.shared.currentChannelValue, from: selfUid)
        }
        
        
        @objc
        private func onMoreActionBtn() {
            
            let alert = UIAlertController(title: "More Action", message: nil, preferredStyle: .alert)
            
            let blockAction = UIAlertAction(title: "Block", style: .default) { [weak self] (_) in
                guard let `self` = self,
                    let selfUid = Settings.shared.loginResult.value?.uid else { return }
                FireStore.shared.addBlockUser(self.viewModel.userId, to: selfUid)
            }
            
            let unfollowAction = UIAlertAction(title: "Unfollow", style: .destructive) { [weak self] (_) in
                guard let `self` = self,
                    let selfUid = Settings.shared.loginResult.value?.uid else { return }
                FireStore.shared.removeFollowing(self.viewModel.userId, from: selfUid)
            }
            
            alert.addAction(blockAction)
            
            if userType == .following {
                alert.addAction(unfollowAction)
            }
            
            let cancelAction = UIAlertAction(title: "Return", style: .default)
            
            alert.addAction(cancelAction)
            
            present(alert, animated: true)
            
        }
        
        // MARK: - Modalable
        
        func style() -> Modal.Style {
            return .customHeight
        }
        
        func height() -> CGFloat {
            return 259 + Frame.Height.safeAeraBottomHeight
        }
        
        func modalPresentationStyle() -> UIModalPresentationStyle {
            return .overCurrentContext
        }
        
        func cornerRadius() -> CGFloat {
            return 6
        }
        
        func coverAlpha() -> CGFloat {
            return 0.5
        }
        
        func canAutoDismiss() -> Bool {
            return true
        }
        
    }
}
