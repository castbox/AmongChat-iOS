//
//  Social.BlockedUser.Widgets.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/9/11.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift

extension Social.BlockedUserList {
    struct Widgets { }
}

extension Social.BlockedUserList.Widgets {
    
    class BlockedUserCell: UITableViewCell {
        
        private lazy var avatarIV: UIImageView = {
            let iv = UIImageView()
            iv.layer.cornerRadius = 20
            iv.layer.masksToBounds = true
            return iv
        }()
        
        private lazy var prefixLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoBlack(size: 16)
            lb.textColor = UIColor(hex6: 0xF8F8F8)
            return lb
        }()
        
        private lazy var usernameLabel: WalkieLabel = {
            let lb = WalkieLabel()
            lb.font = R.font.nunitoBold(size: 16)
            lb.textColor = UIColor(hex6: 0x333333, alpha: 1.0)
            return lb
        }()
        
        private lazy var actionIV: UIImageView = {
            let iv = UIImageView(image: R.image.btn_more_action())
            return iv
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
            contentView.addSubviews(views: avatarIV, usernameLabel, actionIV, prefixLabel)
            
            avatarIV.snp.makeConstraints { (maker) in
                maker.width.height.equalTo(40)
                maker.centerY.equalToSuperview()
                maker.left.equalToSuperview().offset(15)
            }
            
            prefixLabel.snp.makeConstraints { (maker) in
                maker.center.equalTo(avatarIV)
            }
            
            usernameLabel.snp.makeConstraints { (maker) in
                maker.left.equalTo(avatarIV.snp.right).offset(15)
                maker.right.equalTo(actionIV.snp.left).offset(-15)
                maker.height.equalTo(21)
                maker.centerY.equalToSuperview()
            }
            
            actionIV.snp.makeConstraints { (maker) in
                maker.width.height.equalTo(25)
                maker.right.equalToSuperview().inset(15)
                maker.centerY.equalToSuperview()
            }
            
        }
        
        func configView(with viewModel: ChannelUserViewModel) {
            let user = viewModel.channelUser
            usernameLabel.text = viewModel.name
            usernameLabel.appendKern()
            avatarDisposable = viewModel.avatar.subscribe(onSuccess: { [weak self] (image) in
                guard let `self` = self else { return }
                if let _ = image {
                    self.avatarIV.backgroundColor = .clear
                } else {
                    self.avatarIV.backgroundColor = user.iconColor.color()
                }
                self.avatarIV.image = image
            })
            
            prefixLabel.text = user.prefix
            prefixLabel.isHidden = (viewModel.firestoreUser != nil)
        }
        
    }
}
