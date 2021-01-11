//
//  AmongChat.Home.RoomJoinViewController.swift
//  WalkieTalkie
//
//  Created by zhang dekai on 2021/1/4.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

extension AmongChat.Home {
    
    class StrangeInvitationView: UIView {
        
        private lazy var avatarIV: UIImageView = {
            let iv = UIImageView()
            iv.layer.cornerRadius = 20
            iv.layer.masksToBounds = true
            iv.setContentHuggingPriority(.required, for: .horizontal)
            iv.setContentCompressionResistancePriority(.required, for: .horizontal)
            return iv
        }()
        
        private lazy var msgLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoBold(size: 14)
            lb.textColor = .white
            lb.numberOfLines = 0
//            lb.textAlignment = .left
//            lb.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            return lb
        }()
        
        private lazy var joinBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 14)
            btn.setTitleColor(UIColor.black, for: .normal)
            btn.backgroundColor = UIColor(hex6: 0xFFF000)
            btn.setTitle(R.string.localizable.socialJoinAction().uppercased(), for: .normal)
            btn.layer.masksToBounds = true
            btn.layer.cornerRadius = 16
            btn.setContentHuggingPriority(.required, for: .horizontal)
            btn.setContentCompressionResistancePriority(.required, for: .horizontal)
            btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
            return btn
        }()
        
        private lazy var container: UIView = {
            let v = UIView()
            v.backgroundColor = UIColor(hex6: 0x303030)
            v.layer.cornerRadius = 12
            v.layer.masksToBounds = true
            return v
        }()
        
        private var joinBtnDisposable: Disposable? = nil
        
        private var room: Entity.FriendUpdatingInfo.Room? = nil
        
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            isUserInteractionEnabled = false
            bindSubviewEvent()
            configureSubview()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override var intrinsicContentSize: CGSize {
            CGSize(width: Frame.Screen.width, height: 80)
        }
        
        private func bindSubviewEvent() {
            setupEvent()
        }
        
        private func configureSubview() {
            setupLayout()
        }
        
        private func setupLayout() {
            
            backgroundColor = .clear//UIColor.black.alpha(0.5)
            
            addSubview(container)
            container.snp.makeConstraints { (maker) in
//                maker.top.equalTo(Frame.Height.safeAeraTopHeight)
//                maker.left.right.equalToSuperview().inset(20)
                maker.top.left.right.equalToSuperview()
                maker.height.equalTo(90)
            }
            
            container.addSubviews(views: avatarIV, msgLabel,joinBtn)
            
            avatarIV.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.left.equalTo(16)
                maker.width.height.equalTo(40)
            }
            
            msgLabel.snp.makeConstraints { (maker) in
                maker.top.greaterThanOrEqualTo(16)
                maker.bottom.lessThanOrEqualTo(-16)
                maker.centerY.equalToSuperview()
                maker.left.equalTo(avatarIV.snp.right).offset(8)
                maker.right.equalTo(joinBtn.snp.left).offset(-8)
            }
            
            joinBtn.snp.makeConstraints { (maker) in
                maker.right.equalTo(-16)
                maker.centerY.equalToSuperview()
                maker.height.equalTo(32)
            }
        }
        
        private func setupEvent() {
            
//            let tap = UITapGestureRecognizer()
//            addGestureRecognizer(tap)
//            tap.rx.event.subscribe(onNext: { [weak self] (_) in
////                self?.dismiss(animated: false)
//            })
//            .disposed(by: bag)
//
//            let containerTap = UITapGestureRecognizer()
//            container.addGestureRecognizer(containerTap)
//            containerTap.rx.event.subscribe(onNext: { (_) in
//
//            })
//            .disposed(by: bag)
        }
        
        
        func updateContent(user: Entity.UserProfile, room: Entity.FriendUpdatingInfo.Room) {
            self.room = room
            avatarIV.setImage(with: URL(string: user.pictureUrl))
            //            nameLabel.text =
            msgLabel.text = "@\(user.name ?? "") " + R.string.localizable.amongChatChannelInvitationMsg(room.topicName.uppercased())
            //            Logger.Action.log(.invite_dialog_imp, categoryValue: room.topicId)
        }
        
        func bindEvent(join: @escaping () -> Void) {
            joinBtnDisposable?.dispose()
            joinBtnDisposable = joinBtn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { (_) in
                    join()
                })
        }
    }
    
    class RoomJoinViewController: WalkieTalkie.ViewController {
        
        private lazy var avatarIV: UIImageView = {
            let iv = UIImageView()
            iv.layer.cornerRadius = 20
            iv.layer.masksToBounds = true
            iv.setContentHuggingPriority(.required, for: .horizontal)
            iv.setContentCompressionResistancePriority(.required, for: .horizontal)
            return iv
        }()
        
        private lazy var msgLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoBold(size: 14)
            lb.textColor = .white
            lb.numberOfLines = 0
//            lb.textAlignment = .left
//            lb.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            return lb
        }()
        
        private lazy var joinBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 14)
            btn.setTitleColor(UIColor.black, for: .normal)
            btn.backgroundColor = UIColor(hex6: 0xFFF000)
            btn.setTitle(R.string.localizable.socialJoinAction().uppercased(), for: .normal)
            btn.layer.masksToBounds = true
            btn.layer.cornerRadius = 16
            btn.setContentHuggingPriority(.required, for: .horizontal)
            btn.setContentCompressionResistancePriority(.required, for: .horizontal)
            btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
            return btn
        }()
        
        private lazy var container: UIView = {
            let v = UIView()
            v.backgroundColor = UIColor(hex6: 0x303030)
            v.layer.cornerRadius = 12
            v.layer.masksToBounds = true
            return v
        }()
        
        private var joinBtnDisposable: Disposable? = nil
        
        private var room: Entity.FriendUpdatingInfo.Room? = nil
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
            setupEvent()
        }
        
        private func setupLayout() {
            
            view.backgroundColor = .clear//UIColor.black.alpha(0.5)
            
            view.addSubview(container)
            container.snp.makeConstraints { (maker) in
                maker.top.equalTo(Frame.Height.safeAeraTopHeight)
                maker.left.right.equalToSuperview().inset(20)
                maker.height.equalTo(90)
            }
            
            container.addSubviews(views: avatarIV, msgLabel,joinBtn)
            
            avatarIV.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.left.equalTo(16)
                maker.width.height.equalTo(40)
            }
            
            msgLabel.snp.makeConstraints { (maker) in
                maker.top.greaterThanOrEqualTo(16)
                maker.bottom.lessThanOrEqualTo(-16)
                maker.centerY.equalToSuperview()
                maker.left.equalTo(avatarIV.snp.right).offset(8)
                maker.right.equalTo(joinBtn.snp.left).offset(8)
            }
            
            joinBtn.snp.makeConstraints { (maker) in
                maker.right.equalTo(-16)
                maker.centerY.equalToSuperview()
                maker.height.equalTo(32)
            }
        }
        
        private func setupEvent() {
            
            let tap = UITapGestureRecognizer()
            view.addGestureRecognizer(tap)
            tap.rx.event.subscribe(onNext: { [weak self] (_) in
                self?.dismiss(animated: false)
            })
            .disposed(by: bag)
            
            let containerTap = UITapGestureRecognizer()
            container.addGestureRecognizer(containerTap)
            containerTap.rx.event.subscribe(onNext: { (_) in
                
            })
            .disposed(by: bag)
        }
        
        
        func updateContent(user: Entity.UserProfile, room: Entity.FriendUpdatingInfo.Room) {
            self.room = room
            avatarIV.setImage(with: URL(string: user.pictureUrl))
            //            nameLabel.text =
            msgLabel.text = "@\(user.name ?? "") " + R.string.localizable.amongChatChannelInvitationMsg(room.topicName.uppercased())
            //            Logger.Action.log(.invite_dialog_imp, categoryValue: room.topicId)
        }
        
        func bindEvent(join: @escaping () -> Void) {
            joinBtnDisposable?.dispose()
            joinBtnDisposable = joinBtn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { (_) in
                    join()
                })
        }
    }
}
