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
        
        private lazy var haloView = SoundAnimationView(frame: .zero)
        
        private lazy var avatarIV: UIImageView = {
            let iv = UIImageView()
            iv.layer.cornerRadius = 20
            iv.layer.masksToBounds = true
            iv.layer.borderWidth = 0.5
            iv.contentMode = .scaleAspectFill
            iv.layer.borderColor = UIColor.white.alpha(0.8).cgColor
            iv.backgroundColor = UIColor.white.alpha(0.2)
            iv.isUserInteractionEnabled = true
            let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressGestureAction))
            longPressGesture.minimumPressDuration = 0.5
            iv.addGestureRecognizer(longPressGesture)
            return iv
        }()
        
        private lazy var kickSelectedView: UIImageView = {
            let iv = UIImageView()
            iv.layer.cornerRadius = 20
            iv.layer.masksToBounds = true
            iv.image = R.image.ac_kick_selected()
            iv.isHidden = true
            iv.contentMode = .center
//            iv.layer.borderWidth = 0.5
//            iv.layer.borderColor = UIColor.white.alpha(0.8).cgColor
            iv.backgroundColor = "D30F0F".color().alpha(0.62)
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
            //            lb.backgroundColor = UIColor.black.alpha(0.69)
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
        var avatarLongPressHandler: ((Entity.RoomUser) -> Void)?
        
        var isKickSelected: Bool = false {
            didSet {
                kickSelectedView.isHidden = !isKickSelected
            }
        }
        
        override init(frame: CGRect) {
            super.init(frame: .zero)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        @objc
        func longPressGestureAction() {
            guard let user = user else {
                return
            }
            avatarLongPressHandler?(user)
        }
        
        override func prepareForReuse() {
            super.prepareForReuse()
            //            stopHaloAnimation()
            //            haloView.stopLoading()
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
        }
        
        func startSoundAnimation() {
            haloView.startLoading()
        }
        
        @objc
        func gameNameButtonAction() {
            user?.nickname?.copyToPasteboard()
            viewContainingController()?.view.raft.autoShow(.text(R.string.localizable.copied()), userInteractionEnabled: false)
        }
        
        private func setupLayout() {
            contentView.backgroundColor = .clear
            contentView.addSubviews(views: indexLabel, gameNameButton, haloView, avatarIV, nameLabel, disableMicView, mutedLabel, kickSelectedView)
            
            indexLabel.snp.makeConstraints { (maker) in
                maker.left.right.top.equalToSuperview()
                maker.height.equalTo(21.5)
            }
            
            //            haloView.soundWidth = 60
            haloView.snp.makeConstraints { (maker) in
                maker.center.equalTo(avatarIV)
                maker.width.height.equalTo(60)
            }
            
            avatarIV.snp.makeConstraints { (maker) in
                maker.size.equalTo(CGSize(width: 40, height: 40))
                maker.centerX.equalToSuperview()
                maker.top.equalTo(indexLabel.snp.bottom).offset(4)
            }
            
            kickSelectedView.snp.makeConstraints { (maker) in
                maker.center.equalTo(avatarIV)
                maker.width.height.equalTo(40)
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
    }
}

extension AmongChat.Room.UserCell {
    
    func bind(_ user: Entity.RoomUser?, topic: AmongChat.Topic, index: Int) {
        if index == 1 {
            indexLabel.text = "\(index)-host"
        } else {
            indexLabel.text = index.string
        }
        
        guard let user = user else {
            clearStyle()
            return
        }
        self.user = user
        avatarIV.contentMode = .scaleAspectFill
        avatarIV.setImage(with: user.pictureUrl)
        nameLabel.text = user.name
        if user.status == .talking {
            haloView.startLoading()
        } else {
            haloView.stopLoading()
        }
        gameNameButton.setTitle(user.nickname, for: .normal)
        avatarIV.layer.borderWidth = 0.5
        haloView.isHidden = false
        gameNameButton.isHidden = !(topic == .roblox && user.nickname.isValid)
        //自己 muted 其他用户
        if isKickSelected {
            mutedLabel.isHidden = true
            disableMicView.isHidden = true
        } else {
            if user.isMutedByLoginUser == true {
                mutedLabel.isHidden = !user.isMutedValue
                disableMicView.isHidden = true
            } else {
                mutedLabel.isHidden = true
                disableMicView.isHidden = !user.isMutedValue
            }
        }
        
        //自己 muted 自己
        //            disableMicView.isHidden = true
        //        } else {
        //            clearStyle()
        //        }
    }
    
    func clearStyle() {
        avatarIV.kf.cancelDownloadTask()
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
