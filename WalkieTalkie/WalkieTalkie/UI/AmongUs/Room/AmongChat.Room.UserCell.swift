//
//  AmongChat.Room.UserCell.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/11/27.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import Kingfisher

extension AmongChat.Room {
    
    class UserCell: UICollectionViewCell {
        
        private static let haloViewAnimationKey = "halo_animation"
        
        private lazy var indexLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 16)
            lb.textColor = .white
            lb.textAlignment = .center
            return lb
        }()
        
        private lazy var haloView: UIView = {
            let v = UIView()
            v.backgroundColor = .clear
            v.layer.borderColor = UIColor.white.cgColor
            v.layer.borderWidth = 1
            v.layer.cornerRadius = 20
            return v
        }()
        
        private lazy var avatarIV: UIImageView = {
            let iv = UIImageView()
            iv.layer.cornerRadius = 20
            iv.layer.masksToBounds = true
            iv.layer.borderWidth = 0.5
            iv.layer.borderColor = UIColor.white.alpha(0.8).cgColor
            iv.backgroundColor = UIColor.white.alpha(0.2)
            return iv
        }()
        
        private lazy var disableMicView: UIImageView = {
            let iv = UIImageView()
            iv.image = R.image.ac_icon_room_disable_mic()
            iv.isHidden = true
            return iv
        }()
        
        private lazy var mutedLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 10)
            lb.textColor = "FB5858".color()
            lb.textAlignment = .center
            lb.text = R.string.localizable.roomUserListMuted()
            lb.isHidden = true
            return lb
        }()
        
        private lazy var nameLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 12)
            lb.textColor = .white
            lb.backgroundColor = UIColor.black.alpha(0.69)
            lb.textAlignment = .center
            return lb
        }()
        
        private lazy var gameNameButton: UIButton = {
            let btn = UIButton(type: .custom)
//            btn.setTitle("XXX", for: .normal)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 10)
            btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
            btn.backgroundColor = UIColor.white.alpha(0.2)
            btn.cornerRadius = 10
            btn.addTarget(self, action: #selector(gameNameButtonAction), for: .touchUpInside)
            return btn
        }()
        
        private var avatarDisposable: Disposable?
        private var user: Entity.RoomUser?
        override init(frame: CGRect) {
            super.init(frame: .zero)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func prepareForReuse() {
            super.prepareForReuse()
            stopHaloAnimation()
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
        }
        
        @objc
        func gameNameButtonAction() {
            user?.robloxName?.copyToPasteboard()
            viewController()?.view.raft.autoShow(.text(R.string.localizable.copied()), userInteractionEnabled: false)
        }
        
        private func setupLayout() {
            contentView.backgroundColor = .clear
            contentView.addSubviews(views: indexLabel, haloView, avatarIV, nameLabel, gameNameButton, disableMicView, mutedLabel)
            
            indexLabel.snp.makeConstraints { (maker) in
                maker.left.right.top.equalToSuperview()
                maker.height.equalTo(21.5)
            }
            
            haloView.snp.makeConstraints { (maker) in
                maker.center.equalTo(avatarIV)
                maker.width.height.equalTo(40)
            }
            
            avatarIV.snp.makeConstraints { (maker) in
                maker.size.equalTo(CGSize(width: 40, height: 40))
                maker.centerX.equalToSuperview()
                maker.top.equalTo(indexLabel.snp.bottom).offset(4)
            }
            
            disableMicView.snp.makeConstraints { (maker) in
                maker.right.bottom.equalTo(avatarIV)
//                maker.top.equalTo(indexLabel.snp.bottom).offset(4)
            }
            
            mutedLabel.snp.makeConstraints { (maker) in
                maker.center.equalTo(avatarIV)
                maker.width.height.equalTo(38)
            }
            
            nameLabel.snp.makeConstraints { (maker) in
                maker.top.equalTo(avatarIV.snp.bottom).offset(4)
                maker.left.right.equalToSuperview()
//                maker.bottom.equalTo(gameNameButton.snp.top)
            }
            
            gameNameButton.snp.makeConstraints { maker in
                maker.top.equalTo(nameLabel.snp.bottom).offset(4)
                maker.left.right.equalToSuperview()
                maker.height.equalTo(20)
            }
        }
        
        private func haloAnimation() {
            
            let borderWidthAni = CABasicAnimation(keyPath: "borderWidth")
            borderWidthAni.fromValue = 1
            borderWidthAni.toValue = 0
            
            let opacityAni = CABasicAnimation(keyPath: "opacity")
            opacityAni.fromValue = 1
            opacityAni.toValue = 0
            
            let scaleAni = CABasicAnimation(keyPath: "transform.scale")
            scaleAni.fromValue = 1
            scaleAni.toValue = 1.5
            
            let animationGroup = CAAnimationGroup()
            animationGroup.duration = 1.5;
            animationGroup.animations = [borderWidthAni, opacityAni, scaleAni]
            animationGroup.repeatCount = .greatestFiniteMagnitude
            animationGroup.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            haloView.layer.add(animationGroup, forKey: UserCell.haloViewAnimationKey)
        }
        
        private func stopHaloAnimation() {
            haloView.layer.removeAnimation(forKey: UserCell.haloViewAnimationKey)
        }
        
    }
}

extension AmongChat.Room.UserCell {
    
    func bind(_ user: Entity.RoomUser?, topic: AmongChat.Topic) {
        guard let user = user else {
            clearStyle()
            return
        }
        if user.seatNo == 0 {
            indexLabel.text = user.seatNo.string+"-host"
        } else {
            indexLabel.text = user.seatNo.string
        }
        if user.uid != nil {
            avatarIV.image = nil
            avatarIV.setImage(with: user.avatar)
            nameLabel.text = user.name
            if user.status == .talking {
                haloAnimation()
            } else {
                stopHaloAnimation()
            }
            gameNameButton.setTitle(user.robloxName, for: .normal)
            avatarIV.layer.borderWidth = 0.5
            haloView.isHidden = false
            gameNameButton.isHidden = topic != .roblox
            gameNameButton.isHidden = !user.robloxName.isValid
            //自己 muted 其他用户
            mutedLabel.isHidden = !user.isMuted
            //自己 muted 自己
//            disableMicView.isHidden = true
        } else {
            clearStyle()
        }
    }
    
    func clearStyle() {
        avatarIV.image = R.image.ac_icon_seat_add()
        avatarIV.contentMode = .center
        avatarIV.layer.borderWidth = 0
        haloView.isHidden = true
        nameLabel.text = ""
        gameNameButton.setTitle(nil, for: .normal)
        gameNameButton.isHidden = true
        mutedLabel.isHidden = true
        disableMicView.isHidden = true
    }
    
}
