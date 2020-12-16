//
//  AmongChat.Room.UserCell.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/11/27.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift

extension AmongChat.Room {
    
    class UserCell: UICollectionViewCell {
        
        private static let haloViewAnimationKey = "halo_animation"
        
        private lazy var indexLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoRegular(size: 11)
            lb.textColor = .white
            lb.textAlignment = .center
            return lb
        }()
        
        private lazy var haloView: UIView = {
            let v = UIView()
            v.backgroundColor = .clear
            v.layer.borderColor = UIColor.white.cgColor
            v.layer.borderWidth = 1
            v.layer.cornerRadius = 25
            return v
        }()
        
        private lazy var avatarIV: UIImageView = {
            let iv = UIImageView()
            iv.layer.cornerRadius = 25
            iv.layer.masksToBounds = true
            iv.layer.borderWidth = 0.5
            iv.layer.borderColor = UIColor.white.alpha(0.8).cgColor
            return iv
        }()
        
        private lazy var nameLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoRegular(size: 11)
            lb.textColor = .white
            lb.textAlignment = .center
            return lb
        }()
        
//        private lazy var gameNameButton: UIButton = {
//            let btn = UIButton(type: .custom)
//            btn.setTitle("XXX", for: .normal)
////            btn.setTitleColor(<#T##color: UIColor?##UIColor?#>, for: <#T##UIControl.State#>)
////            btn.setImage(R.image.icon_close(), for: .normal)
////            btn.addTarget(self, action: #selector(onCloseBtn), for: .primaryActionTriggered)
//            return btn
//        }()
        
        private var avatarDisposable: Disposable?
        
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
        
        private func setupLayout() {
            contentView.backgroundColor = .clear
            contentView.addSubviews(views: indexLabel, haloView, avatarIV, nameLabel)
            
            indexLabel.snp.makeConstraints { (maker) in
                maker.left.right.top.equalToSuperview()
            }
            
            haloView.snp.makeConstraints { (maker) in
                maker.center.equalTo(avatarIV)
                maker.size.equalTo(avatarIV)
            }
            
            avatarIV.snp.makeConstraints { (maker) in
                maker.size.equalTo(CGSize(width: 50, height: 50))
                maker.centerX.equalToSuperview()
                maker.top.equalTo(indexLabel.snp.bottom)
            }
            
            nameLabel.snp.makeConstraints { (maker) in
                maker.left.bottom.right.equalToSuperview()
//                maker.bottom.equalTo(gameNameButton.snp.top)
            }
            
//            gameNameButton.snp.makeConstraints { maker in
//                maker.left.right.bottom.equalToSuperview()
//            }
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
    
    func bind(_ userViewModel: ChannelUserViewModel?) {
        
        if let userViewModel = userViewModel {
            avatarIV.image = nil
            let user = userViewModel.channelUser
            avatarDisposable?.dispose()
            avatarDisposable = userViewModel.avatar.subscribe(onSuccess: { [weak self] (image) in
                guard let `self` = self else { return }
                
                if let _ = image {
                    self.avatarIV.backgroundColor = .clear
                } else {
                    self.avatarIV.backgroundColor = user.iconColor.color()
                }
                self.avatarIV.image = image
            })
            
            nameLabel.text = userViewModel.name
            if userViewModel.channelUser.status == .talking {
                haloAnimation()
            } else {
                stopHaloAnimation()
            }
        } else {
            avatarIV.image = R.image.speak_list_add()
            avatarIV.backgroundColor = nil
            nameLabel.text = ""
        }
    }
    
}
