//
//  Social.ProfileViewcontrollerExtension.swift
//  WalkieTalkie
//
//  Created by zhang dekai on 2020/12/29.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import SwiftyUserDefaults

extension Social.ProfileViewController {
    
    class ProfileView: UIView {
        
        enum HeaderProfileAction {
            case edit
            case following
            case follower
            case avater
            case follow
        }
        
        let bag = DisposeBag()
        
        var headerHandle:((HeaderProfileAction) -> Void)?
                
        private lazy var avatarIV: UIImageView = {
            let iv = UIImageView()
            iv.layer.cornerRadius = 50
            iv.layer.masksToBounds = true
            let tapGR = UITapGestureRecognizer()
            tapGR.addTarget(self, action: #selector(onAvatarTapped))
            iv.isUserInteractionEnabled = true
            iv.addGestureRecognizer(tapGR)
            return iv
        }()
        
        private(set) lazy var changeIcon: UIImageView = {
            let iv = UIImageView(image: R.image.profile_avatar_random_btn())
            return iv
        }()
                
        private lazy var nameLabel: WalkieLabel = {
            let lb = WalkieLabel()
            lb.font = R.font.nunitoExtraBold(size: 26)
            lb.textColor = .white
            lb.lineBreakMode = .byTruncatingMiddle
            return lb
        }()
        
        private lazy var uidLabel: WalkieLabel = {
            let lb = WalkieLabel()
            lb.font = R.font.nunitoExtraBold(size: 16)
            lb.textColor = "#898989".color()
            return lb
        }()
        
        private lazy var followingBtn: VerticalTitleButton = {
            let v = VerticalTitleButton()
            v.setTitle("0")
            v.setSubtitle(R.string.localizable.profileLittleFollowing())
            let tapGR = UITapGestureRecognizer()
            tapGR.addTarget(self, action: #selector(onFollowingBtn))
            v.isUserInteractionEnabled = true
            v.addGestureRecognizer(tapGR)
            return v
        }()
        
        private lazy var relationContainer: UIView = {
            let view = UIView()
            view.addSubview(followerBtn)
            view.addSubview(lineView)
            view.addSubview(followingBtn)
            return view
        }()
        private lazy var lineView: UIView = {
            let lineView = UIView()
            lineView.backgroundColor = UIColor.white.alpha(0.2)
            return lineView
        }()
        
        private lazy var followerBtn: VerticalTitleButton = {
            let v = VerticalTitleButton()
            v.setTitle("0")
            v.setSubtitle(R.string.localizable.profileLittleFollower())
            let tapGR = UITapGestureRecognizer()
            tapGR.addTarget(self, action: #selector(onFollowerBtn))
            v.isUserInteractionEnabled = true
            v.addGestureRecognizer(tapGR)
            return v
        }()
        
        private lazy var editBtn: UIButton = {
            let btn = WalkieButton(type: .custom)
            btn.addTarget(self, action: #selector(onEditBtn), for: .primaryActionTriggered)
            btn.setImage(R.image.ac_profile_edit(), for: .normal)
            return btn
        }()
        
        private lazy var followButton: UIButton = {
            let btn = UIButton()
            btn.backgroundColor = UIColor(hex6: 0xFFF000)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
            btn.layer.cornerRadius = 24
            btn.setTitleColor(.black, for: .normal)
            btn.setTitle(R.string.localizable.channelUserListFollow(), for: .normal)
            btn.isHidden = true
            return btn
        }()
        
        lazy var redCountLabel: UILabel = {
            let lb = WalkieLabel()
            lb.font = R.font.nunitoExtraBold(size: 12)
            lb.textColor = .white
            lb.backgroundColor = UIColor(hex6: 0xFB5858)
            lb.layer.masksToBounds = true
            lb.layer.cornerRadius = 8
            lb.isHidden = true
            lb.textAlignment = .center
            return lb
        }()
        
        private var isSelf = true
        private var uid = ""
        private var changedName = false
        private var currentName = ""
        private func addUidForName() {
            if changedName {
                nameLabel.text = currentName
            } else {
                nameLabel.text = "\(currentName) - \(uid)"
            }
            changedName = !changedName
        }
        
        init(with isSelf: Bool) {
            super.init(frame: .zero)
            self.isSelf = isSelf
            setupLayout()
            bindSubviewEvent()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func configProfile(_ profile: Entity.UserProfile) {
            uid = profile.uid.string
            nameLabel.attributedText = profile.nameWithVerified(fontSize: 26, withAge: true)
            currentName = nameLabel.text ?? ""
            uidLabel.text = "ID: \(profile.uid)"
            avatarIV.setAvatarImage(with: profile.pictureUrl)
            if isSelf {
                editBtn.isHidden = false
            }
        }
        
        func setProfileData(_ model: Entity.RoomUser) {
            uid = model.uid.string
            nameLabel.text = model.name
            uidLabel.text = "ID: \(model.uid)"
            avatarIV.setAvatarImage(with: model.pictureUrl)
        }
        
        func setViewData(_ model: Entity.RelationData, isSelf: Bool) {
            
            let lastCount = Defaults[\.followersCount]
            
            let followersCount = model.followersCount ?? 0
            
            followingBtn.setTitle("\(model.followingCount ?? 0)")
            followerBtn.setTitle("\(followersCount)")

            if isSelf {
                Defaults[\.followersCount] = followersCount
                if followersCount > lastCount {
                    redCountLabel.text = "+\(followersCount - lastCount)"
                    redCountLabel.isHidden = false
                } else {
                    redCountLabel.isHidden = true
                }
            }
            let follow = model.isFollowed ?? false
            setFollowButton(follow)
        }
        
        func setFollowButton(_ isFollowed: Bool) {
            if isFollowed {
                greyFollowButton()
            } else {
                yellowFollowButton()
            }
            followButton.isHidden = false
        }
        
        private func greyFollowButton() {
            followButton.setTitle(R.string.localizable.profileFollowing(), for: .normal)
            followButton.setTitleColor(UIColor(hex6: 0x898989), for: .normal)
            followButton.layer.borderWidth = 3
            followButton.layer.borderColor = UIColor(hex6: 0x898989).cgColor
            followButton.backgroundColor = UIColor.theme(.backgroundBlack)
        }
        
        private func yellowFollowButton() {
            followButton.setTitle(R.string.localizable.channelUserListFollow(), for: .normal)
            followButton.backgroundColor = UIColor(hex6: 0xFFF000)
            followButton.layer.borderWidth = 3
            followButton.layer.borderColor = UIColor(hex6: 0xFFF000).cgColor
            followButton.setTitleColor(.black, for: .normal)
        }
        
        private func bindSubviewEvent() {
        }
        
        private func setupLayout() {
            
            addSubviews(views: avatarIV, changeIcon, editBtn, relationContainer, followButton, redCountLabel)
            
            followingBtn.snp.makeConstraints { (maker) in
                maker.leading.top.bottom.equalToSuperview()
                maker.trailing.equalTo(followerBtn.snp.leading)
                maker.width.equalTo(followerBtn)
//                maker.top.equalTo(nameLabel.snp.bottom).offset(12)
//                maker.left.equalTo(avatarIV.snp.right).offset(20)
//                maker.height.equalTo(43)
            }
            
            lineView.snp.makeConstraints { maker in
                maker.center.equalToSuperview()
                maker.width.equalTo(2)
                maker.height.equalTo(28)
            }
            
            followerBtn.snp.makeConstraints { (maker) in
                maker.trailing.top.bottom.equalToSuperview()

//                maker.top.equalTo(followingBtn.snp.top)
//                maker.left.equalTo(followingBtn.snp.right).offset(40)
//                maker.height.equalTo(43)
            }

            if isSelf {
                setLayoutForSelf()
            } else {
                addSubviews(views: nameLabel, uidLabel)
                setLayoutForOther()
            }
            
            let tap = UITapGestureRecognizer()
            tap.numberOfTapsRequired = 5
            nameLabel.isUserInteractionEnabled = true
            nameLabel.addGestureRecognizer(tap)
            tap.rx.event.observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self](tap) in
                    self?.addUidForName()
                }).disposed(by: bag)
        }

        private func setLayoutForSelf() {
            
            avatarIV.snp.makeConstraints { (maker) in
                maker.top.equalTo(40)
                maker.leading.equalTo(20)
                maker.height.width.equalTo(100)
            }
            
            changeIcon.snp.makeConstraints { (maker) in
                maker.bottom.equalTo(avatarIV)
                maker.trailing.equalTo(avatarIV).offset(1)
            }
            
            let infoContainer = UIView()
            addSubview(infoContainer)
            infoContainer.snp.makeConstraints { maker in
                maker.leading.equalTo(avatarIV.snp.trailing).offset(20)
                maker.centerY.equalTo(avatarIV)
                maker.trailing.equalTo(-65)
            }
            infoContainer.addSubviews(views: nameLabel, uidLabel)
            
            nameLabel.snp.makeConstraints { (maker) in
                maker.top.leading.trailing.equalToSuperview()
            }

            uidLabel.snp.makeConstraints { (maker) in
                maker.top.equalTo(nameLabel.snp.bottom).offset(6)
                maker.leading.bottom.equalToSuperview()
            }

            editBtn.snp.makeConstraints { (maker) in
                maker.trailing.equalTo(-20)
                maker.centerY.equalTo(nameLabel.snp.centerY)
                maker.height.width.equalTo(28)
            }
            editBtn.isHidden = true
            
            relationContainer.snp.makeConstraints { maker in
                maker.leading.trailing.equalToSuperview()
                maker.top.equalTo(avatarIV.snp.bottom).offset(20)
                maker.height.equalTo(50)
            }
            
            redCountLabel.snp.makeConstraints { (make) in
                make.leading.equalTo(followerBtn.titleLabel.snp.trailing).offset(4)
                make.centerY.equalTo(followerBtn.titleLabel.snp.centerY)
                make.height.equalTo(16)
                make.width.greaterThanOrEqualTo(30)
            }
        }
        
        private func setLayoutForOther() {
            
            avatarIV.snp.makeConstraints { (maker) in
                maker.top.equalTo(40)
                maker.centerX.equalToSuperview()
                maker.height.width.equalTo(100)
            }
            
            nameLabel.snp.makeConstraints { (maker) in
                maker.top.equalTo(avatarIV.snp.bottom).offset(8)
                maker.leading.trailing.equalToSuperview().inset(20)
            }
            
            nameLabel.textAlignment = .center
            
            uidLabel.snp.makeConstraints { (maker) in
                maker.top.equalTo(nameLabel.snp.bottom).offset(6)
                maker.centerX.equalToSuperview()
            }
            
            relationContainer.snp.makeConstraints { maker in
                maker.leading.trailing.equalToSuperview()
                maker.top.equalTo(uidLabel.snp.bottom).offset(20)
                maker.height.equalTo(50)
            }
            

//            followingBtn.snp.makeConstraints { (maker) in
//                maker.top.equalTo(nameLabel.snp.bottom).offset(8)
//                maker.centerX.equalToSuperview().offset(-80)
//                maker.height.equalTo(43)
//            }
//
//            followerBtn.snp.makeConstraints { (maker) in
//                maker.top.equalTo(followingBtn.snp.top)
//                maker.centerX.equalToSuperview().offset(80)
//                maker.height.equalTo(43)
//            }
            
            followButton.snp.makeConstraints { (maker) in
                maker.top.equalTo(followingBtn.snp.bottom).offset(40)
                maker.leading.trailing.equalToSuperview().inset(40)
                maker.height.equalTo(48)
            }
            followButton.rx.tap
                .subscribe(onNext: { [weak self]() in
                    self?.headerHandle?(.follow)
                }).disposed(by: bag)
            
            editBtn.isHidden = true
            changeIcon.isHidden = true
        }
        
        
        @objc private func onEditBtn() {
            headerHandle?(.edit)
        }
        
        @objc private func onFollowingBtn() {
            headerHandle?(.following)
        }
        
        @objc private func onFollowerBtn() {
            headerHandle?(.follower)
        }
        
        @objc private func onAvatarTapped() {
            if isSelf {
                headerHandle?(.avater)
            }
        }
    }
    
    class ProfileTableCell: TableViewCell {
        
        private lazy var leftIconIV: UIImageView = {
            let iv = UIImageView()
            return iv
        }()
        
        private lazy var rightIconIV: UIImageView = {
            let i = UIImageView(image: R.image.ac_right_arrow())
            return i
        }()
        
        private lazy var titleLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 20)
            lb.textColor = .white
            lb.numberOfLines = 2
            lb.adjustsFontSizeToFitWidth = true
            return lb
        }()
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func configCell(with option: Option) {
            leftIconIV.image = option.image()
            titleLabel.text = option.text()
        }
        
        private func setupLayout() {
            self.backgroundColor = UIColor.theme(.backgroundBlack)
            selectionStyle = .none
            
            contentView.addSubviews(views: leftIconIV, titleLabel, rightIconIV)
            
            leftIconIV.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.width.height.equalTo(40)
                maker.leading.equalTo(24)
            }
            
            titleLabel.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.leading.equalTo(leftIconIV.snp.trailing).offset(16)
                maker.trailing.lessThanOrEqualTo(rightIconIV.snp.leading).offset(-8)
            }
            
            rightIconIV.snp.makeConstraints { (maker) in
                maker.width.height.equalTo(20)
                maker.centerY.equalToSuperview()
                maker.trailing.equalToSuperview().inset(16)
            }
            
            contentView.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(20)
                maker.top.bottom.equalToSuperview().inset(12)
            }
            
            contentView.layer.cornerRadius = 12
            contentView.backgroundColor = UIColor(hex6: 0x222222)
        }
    }
    
    class VerticalTitleButton: UIView {
         lazy var titleLabel: WalkieLabel = {
            let lb = WalkieLabel()
            lb.textAlignment = .center
            lb.font = R.font.nunitoExtraBold(size: 26)
            lb.textColor = .white
            return lb
        }()
        
        private lazy var subtitleLabel: WalkieLabel = {
            let lb = WalkieLabel()
            lb.textAlignment = .center
            lb.font = R.font.nunitoExtraBold(size: 14)
            lb.textColor = UIColor(hex6: 0x898989)
            return lb
        }()
        
        init() {
            super.init(frame: .zero)
            addSubviews(views: titleLabel, subtitleLabel)
            titleLabel.snp.makeConstraints { (maker) in
                maker.top.leading.trailing.equalToSuperview()
            }
            
            subtitleLabel.snp.makeConstraints { (maker) in
                maker.top.equalTo(titleLabel.snp.bottom)
                maker.leading.trailing.bottom.equalToSuperview()
                maker.height.equalTo(18)
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func setTitle(_ title: String) {
            titleLabel.text = title
            titleLabel.appendKern()
        }
        
        func setSubtitle(_ subtitle: String) {
            subtitleLabel.text = subtitle
            subtitleLabel.appendKern()
        }
    }
}
