//
//  Social.TopToastModal.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/9/7.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension Social {
    
    class TopToastModal: WalkieTalkie.ViewController {
        
        private lazy var avatarIV: UIImageView = {
            let iv = UIImageView()
            iv.layer.cornerRadius = 20
            iv.layer.masksToBounds = true
            return iv
        }()

        private lazy var msgLabel: WalkieLabel = {
            let lb = WalkieLabel()
            lb.numberOfLines = 0
            lb.font = R.font.nunitoSemiBold(size: 14)
            lb.textColor = .black
            return lb
        }()
        
        private lazy var toastContainer: UIView = {
            let v = UIView()
            v.backgroundColor = .white
            v.addSubviews(views: self.avatarIV, self.msgLabel)
            
            self.avatarIV.snp.makeConstraints { (maker) in
                maker.width.height.equalTo(40)
                maker.left.equalToSuperview().offset(15)
                maker.bottom.equalToSuperview().offset(-14)
            }
            
            self.msgLabel.snp.makeConstraints { (maker) in
                maker.left.equalTo(self.avatarIV.snp.right).offset(15)
                maker.right.equalToSuperview().offset(-26)
                maker.centerY.equalTo(self.avatarIV)
            }
            
            return v
        }()
        
        private let toastHeight: CGFloat = 92
        
        private let originMsg: FireStore.Entity.User.CommonMessage
        
        init(with msg: FireStore.Entity.User.CommonMessage) {
            originMsg = msg
            super.init(nibName: nil, bundle: nil)
            modalPresentationStyle = .overCurrentContext
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
            setupEvent()
            setupData()
        }
        
        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            toastContainer.addCorner(with: 15, corners: [.bottomLeft, .bottomRight])
        }
        
        private func setupLayout() {
            view.backgroundColor = .clear
            view.addSubviews(views: toastContainer)
            toastContainer.snp.makeConstraints { (maker) in
                maker.top.left.right.equalToSuperview()
                maker.height.equalTo(toastHeight)
            }
            
            toastContainer.transform = CGAffineTransform(a: 1, b: 0, c: 0, d: 1, tx: 0, ty: -toastHeight)
        }
        
        private func setupEvent() {
            
            rx.viewDidAppear
            .take(1)
                .subscribe(onNext: { [weak self] (_) in
                    
                    UIView.animate(withDuration: AnimationDuration.normalSlow.rawValue) {
                        self?.toastContainer.transform = .identity
                    }
                    
                    let _ = Observable<Int>.interval(.seconds(2), scheduler: MainScheduler.instance)
                        .take(1)
                        .subscribe(onNext: { (_) in
                            self?.dismissSelf()
                        })
                })
            .disposed(by: bag)
            
            let viewTapGR = UITapGestureRecognizer(target: self, action: #selector(onViewTapped))
            view.addGestureRecognizer(viewTapGR)
            
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

            let msg: String
            
            switch originMsg.msgType {
            case .channelEntryRefuse:
                msg = R.string.localizable.channelJoinRequestRefusedMsg(profile.name)
            case .enterRoom:
                msg = R.string.localizable.channelJoinRequestEnterRoomMsg(profile.name)
            default:
                msg = ""
            }

            msgLabel.text = msg
            msgLabel.appendKern()
            
            profile.avatarObservable
            .subscribe(onSuccess: { [weak self] (image) in
                self?.avatarIV.image = image
            })
            .disposed(by: bag)
        }
        
        @objc
        private func onViewTapped() {
            dismissSelf()
        }
        
        private func dismissSelf() {
            UIView.animate(withDuration: AnimationDuration.normalSlow.rawValue, animations: { [weak self] in
                guard let `self` = self else { return }
                self.toastContainer.transform = CGAffineTransform(a: 1, b: 0, c: 0, d: 1, tx: 0, ty: -self.toastHeight)
            }) { [weak self] (_) in
                self?.dismiss(animated: false)
            }
        }
    }
    
}
