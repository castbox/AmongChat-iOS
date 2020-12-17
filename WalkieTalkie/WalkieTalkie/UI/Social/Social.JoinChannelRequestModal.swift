//
//  Social.UserList.JoinChannelRequestModal.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/9/4.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

extension Social {
    
    class JoinChannelRequestModal: WalkieTalkie.ViewController, Modalable {
        
        private lazy var avatarIV: UIImageView = {
            let iv = UIImageView()
            #if DEBUG
            iv.backgroundColor = UIColor(hex6: 0xF8E71C, alpha: 1.0)
            #endif
            iv.layer.cornerRadius = 15
            iv.layer.masksToBounds = true
            return iv
        }()
        
        private lazy var nameLabel: WalkieLabel = {
            let lb = WalkieLabel()
            lb.font = R.font.nunitoSemiBold(size: 16)
            lb.textColor = UIColor(hex6: 0x2C2C2C, alpha: 1.0)
            return lb
        }()
        
        private lazy var titleLabel: WalkieLabel = {
            let lb = WalkieLabel()
            lb.font = R.font.nunitoBold(size: 20)
            lb.textColor = UIColor(hex6: 0x2C2C2C, alpha: 1.0)
            lb.text = R.string.localizable.channelJoinRequestModalTitle()
            return lb
        }()
        
        private lazy var msgLabel: WalkieLabel = {
            let lb = WalkieLabel()
            lb.numberOfLines = 0
            lb.font = R.font.nunitoRegular(size: 14)
            lb.textColor = UIColor(hex6: 0x333333, alpha: 0.54)
            lb.text = R.string.localizable.channelJoinRequestModalMsg()
            return lb
        }()
        
        private lazy var refuseBtn: UIButton = {
            let btn = WalkieButton(type: .custom)
            btn.backgroundColor = UIColor(hex6: 0xFE687B, alpha: 1.0)
            btn.titleLabel?.font = R.font.nunitoSemiBold(size: 14)
            btn.addTarget(self, action: #selector(onRefuseBtn), for: .primaryActionTriggered)
            btn.layer.cornerRadius = 24
            btn.setTitle(R.string.localizable.channelJoinRequestRefuse(), for: .normal)
            btn.setTitleColor(.white, for: .normal)
            btn.appendKern()
            return btn
        }()

        private lazy var acceptBtn: UIButton = {
            let btn = WalkieButton(type: .custom)
            btn.backgroundColor = UIColor(hex6: 0xF8E71C, alpha: 1.0)
            btn.titleLabel?.font = R.font.nunitoSemiBold(size: 14)
            btn.addTarget(self, action: #selector(onAcceptBtn), for: .primaryActionTriggered)
            btn.layer.cornerRadius = 24
            btn.setTitle(R.string.localizable.channelJoinRequestAccept(), for: .normal)
            btn.setTitleColor(.black, for: .normal)
            btn.appendKern()
            return btn
        }()
        
        private let originMsg: FireStore.Entity.User.CommonMessage
        
        private lazy var decisionIsMade: Bool = false
        
        init(with msg: FireStore.Entity.User.CommonMessage) {
            originMsg = msg
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
            setupData()
            rx.viewDidAppear
                .take(1)
                .subscribe(onNext: { (_) in
                    // join_secret_imp log
                    GuruAnalytics.log(event: "join_secret_imp", category: nil, name: nil, value: nil, content: nil)
                    //
                })
                .disposed(by: bag)
        }
        
        override func didMove(toParent parent: UIViewController?) {
            super.didMove(toParent: parent)
            
            guard parent == nil,
                decisionIsMade == false else {
                    return
            }
            
            // join_secret_clk log
            GuruAnalytics.log(event: "join_secret_clk", category: nil, name: "2", value: nil, content: nil)
            //

        }
        
        private func setupLayout() {
            view.backgroundColor = .white
            
            view.addSubviews(views: avatarIV, nameLabel, titleLabel, msgLabel, refuseBtn, acceptBtn)
            
            let infoLayoutGuide = UILayoutGuide()
            view.addLayoutGuide(infoLayoutGuide)
            infoLayoutGuide.snp.makeConstraints { (maker) in
                maker.centerX.equalToSuperview()
                maker.top.equalToSuperview().offset(40)
                maker.height.equalTo(30)
            }
            
            avatarIV.snp.makeConstraints { (maker) in
                maker.left.equalTo(infoLayoutGuide)
                maker.top.equalToSuperview().offset(40)
                maker.width.height.equalTo(30)
            }
            
            nameLabel.snp.makeConstraints { (maker) in
                maker.left.equalTo(avatarIV.snp.right).offset(10)
                maker.right.equalTo(infoLayoutGuide)
                maker.centerY.equalTo(avatarIV)
            }
            
            titleLabel.snp.makeConstraints { (maker) in
                maker.top.equalTo(avatarIV.snp.bottom).offset(15)
                maker.centerX.equalToSuperview()
            }
            
            msgLabel.snp.makeConstraints { (maker) in
                maker.top.equalTo(titleLabel.snp.bottom).offset(15)
                maker.left.right.equalToSuperview().inset(25)
            }
            
            refuseBtn.snp.makeConstraints { (maker) in
                maker.left.equalToSuperview().offset(25)
                maker.height.equalTo(48)
                maker.top.equalTo(220)
            }
            
            acceptBtn.snp.makeConstraints { (maker) in
                maker.left.equalTo(refuseBtn.snp.right).offset(25)
                maker.right.equalToSuperview().offset(-25)
                maker.height.width.centerY.equalTo(refuseBtn)
            }
            
        }
        
        private func setupData() {
            if let avatar = originMsg.avatar,
                let name = originMsg.username {
                let profile = FireStore.Entity.User.Profile(avatar: avatar, birthday: "", name: name, premium: false, uidInt: 0, uid: "")
                configViewWith(profile)
            } else {
                FireStore.shared.fetchUserProfile(originMsg.uid)
                    .subscribe(onSuccess: { [weak self] (profile) in
                        guard let profile = profile else { return }
                        self?.configViewWith(profile)
                    })
                    .disposed(by: bag)
            }
        }
        
        private func configViewWith(_ profile: FireStore.Entity.User.Profile) {
            nameLabel.text = profile.name
            nameLabel.appendKern()
            
            profile.avatarObservable
            .subscribe(onSuccess: { [weak self] (image) in
                self?.avatarIV.image = image
            })
            .disposed(by: bag)
        }
                
        @objc
        private func onRefuseBtn() {
            defer {
                dismissSelf(decisionIsMade: true)
            }
            
            // join_secret_clk log
            GuruAnalytics.log(event: "join_secret_clk", category: nil, name: "0", value: nil, content: nil)
            //
            
            guard let selfUid = Settings.shared.loginResult.value?.uid else { return }
//            FireStore.shared.refuseJoinChannelRequest(originMsg, by: selfUid)
        }
        
        @objc
        private func onAcceptBtn() {
            defer {
                dismissSelf(decisionIsMade: true)
            }
            
            // join_secret_clk log
            GuruAnalytics.log(event: "join_secret_clk", category: nil, name: "1", value: nil, content: nil)
            //
            
            let selfChannel = Social.Module.shared.currentChannelValue
            guard let selfProfile = Settings.shared.firestoreUserProfile.value,
                !selfChannel.isEmpty else { return }
            FireStore.shared.acceptJoinChannelRequest(originMsg, toJoinChannel: selfChannel, by: selfProfile)
        }
        
        private func dismissSelf(decisionIsMade: Bool) {
            self.decisionIsMade = decisionIsMade
            dismissModal(animated: true)
        }
        
        // MARK: - Modalable
        
        func style() -> Modal.Style {
            return .customHeight
        }
        
        func height() -> CGFloat {
            return 308 + Frame.Height.safeAeraBottomHeight
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
