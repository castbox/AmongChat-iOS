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
        
        var unlockHandle: (() -> Void)?
        
        let bag = DisposeBag()
        
        private lazy var avatarIV: UIImageView = {
            let iv = UIImageView()
            iv.layer.cornerRadius = 20
            iv.layer.masksToBounds = true
            return iv
        }()
        
        private lazy var usernameLabel: WalkieLabel = {
            let lb = WalkieLabel()
            lb.font = R.font.nunitoExtraBold(size: 20)
            lb.textColor = .white
            return lb
        }()
        
        private lazy var unlockBtn: UIButton = {
            let btn = UIButton()
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 14)
            btn.setTitle("Unblock", for: .normal)
            btn.setTitleColor(.white, for: .normal)
            btn.layer.masksToBounds = true
            btn.layer.cornerRadius = 16
            btn.backgroundColor = UIColor(hex6: 0xFFFFFF, alpha: 0.2)
            return btn
        }()
                
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func prepareForReuse() {
            super.prepareForReuse()

        }
        
        private func setupLayout() {
            selectionStyle = .none
            
            backgroundColor = .clear
            
            contentView.addSubviews(views: avatarIV, usernameLabel, unlockBtn)
            
            avatarIV.snp.makeConstraints { (maker) in
                maker.width.height.equalTo(40)
                maker.centerY.equalToSuperview()
                maker.left.equalToSuperview().offset(15)
            }
            
            usernameLabel.snp.makeConstraints { (maker) in
                maker.left.equalTo(avatarIV.snp.right).offset(12)
                maker.right.equalTo(-100)
                maker.height.equalTo(27)
                maker.centerY.equalToSuperview()
            }
            
            unlockBtn.snp.makeConstraints { (maker) in
                maker.width.equalTo(78)
                maker.height.equalTo(32)
                maker.right.equalTo(-20)
                maker.centerY.equalToSuperview()
            }
            
            unlockBtn.rx.tap
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self]() in
                    self?.unlockHandle?()
                }).disposed(by: bag)
        }
        
        func configView(with model: Entity.RoomUser) {
            usernameLabel.text = model.name
            usernameLabel.appendKern()
            
            avatarIV.setImage(with: model.pictureUrl, placeholder: UIImage(named: "ac_profile_avatar"))
        }
    }
}
