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
            case more
            case customize
        }
        
        let bag = DisposeBag()
        
        var headerHandle:((HeaderProfileAction) -> Void)?
        
        private lazy var backBtn: UIButton = {
            let btn = UIButton(type: .custom)
            if isSelf, controller?.navigationController?.viewControllers.count == 1 {
                btn.setImage(R.image.ac_profile_close_down(), for: .normal)
            } else {
                btn.setImage(R.image.ac_profile_close_circle(), for: .normal)
            }
            btn.rx.tap.observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self]() in
                    guard let `self` = self else { return }
                    if self.controller?.navigationController?.viewControllers.count == 1 {
                        self.controller?.dismiss(animated: true, completion: nil)
                    } else {
                        self.controller?.navigationController?.popViewController()
                    }
                }).disposed(by: bag)
            return btn
        }()
        
        private lazy var proBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.setImage(R.image.ac_pro_icon_22(), for: .normal)
            btn.setTitleColor(UIColor(hex6: 0xFFEC96), for: .normal)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 14)
            btn.rx.tap.observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self]() in
                    guard let `self` = self else { return }
                    self.controller?.presentPremiumView(source: .setting)
                    Logger.UserAction.log(.update_pro, "settings")
                }).disposed(by: bag)
            
            Settings.shared.isProValue.replay()
                .subscribe(onNext: { (isPro) in
                    
                    if isPro {
                        btn.setTitle(nil, for: .normal)
                    } else {
                        btn.setTitle(R.string.localizable.profileUnlockPro(), for: .normal)
                    }
                    
                })
                .disposed(by: bag)
            btn.layer.cornerRadius = 20
            btn.backgroundColor = UIColor(hex6: 0x000000, alpha: 0.2)
            btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
            btn.titleEdgeInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: -2)
            btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: -2, bottom: 0, right: 2)
            return btn
        }()
        
        private lazy var settingsBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.setImage(R.image.ac_profile_setting(), for: .normal)
            btn.rx.tap.observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self]() in
                    guard let `self` = self else { return }
                    let vc = SettingViewController()
                    self.controller?.navigationController?.pushViewController(vc)
                }).disposed(by: bag)
            return btn
        }()
        
        private lazy var titleLabel: WalkieLabel = {
            let lb = WalkieLabel()
            lb.font = R.font.nunitoExtraBold(size: 24)
            lb.textColor = .white
            lb.textAlignment = .center
            lb.text = R.string.localizable.profileProfile()
            return lb
        }()
        
        private lazy var moreBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.setImage( R.image.ac_profile_more_icon(), for: .normal)
            btn.rx.tap.observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self]() in
                    self?.headerHandle?(.more)
                }).disposed(by: bag)
            return btn
        }()
        
        private lazy var infoContainer: UIView = {
            let v = UIView()
            return v
        }()
        
        private lazy var skinView: Social.ProfileLookViewController.ProfileLookView = {
            let v = Social.ProfileLookViewController.ProfileLookView()
            return v
        }()
        
        private lazy var customizeBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
            btn.setTitle(R.string.localizable.amongChatProfileCustomize(), for: .normal)
            btn.setTitleColor(.black, for: .normal)
            btn.setBackgroundImage("#FFF000".color().image, for: .normal)
            btn.cornerRadius = 18
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 16)
            btn.rx.tap.observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self]() in
                    self?.headerHandle?(.customize)
                }).disposed(by: bag)
            return btn
        }()
                
        private lazy var avatarIV: AvatarImageView = {
            let iv = AvatarImageView()
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
            lb.font = R.font.nunitoExtraBold(size: 22)
            lb.textColor = .white
            lb.numberOfLines = 2
            lb.adjustsFontSizeToFitWidth = true
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
        
        private lazy var loginButton: UIButton = {
            let btn = UIButton(type: .custom)
            btn.adjustsImageWhenHighlighted = false
            btn.layer.masksToBounds = true
            btn.setTitle(R.string.localizable.amongChatProfileSignIn(), for: .normal)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
            btn.titleLabel?.textAlignment = .center
            btn.setTitleColor(.black, for: .normal)
            btn.layer.cornerRadius = 24
            btn.backgroundColor = "#FFF000".color()
            btn.rx.controlEvent(.primaryActionTriggered)
                .subscribe { _ in
                    _ = AmongChat.Login.canDoLoginEvent(style: .inAppLogin)
                }
                .disposed(by: bag)
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
        private weak var controller: ViewController?
                
        init(with isSelf: Bool, viewController: ViewController) {
            super.init(frame: .zero)
            self.isSelf = isSelf
            self.controller = viewController
            setupLayout()
            bindSubviewEvent()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func addUidForName() {
            if changedName {
                nameLabel.text = currentName
            } else {
                nameLabel.text = "\(currentName) - \(uid)"
            }
            changedName = !changedName
        }

        
        func configProfile(_ profile: Entity.UserProfile) {
            uid = profile.uid.string
            nameLabel.attributedText = profile.nameWithVerified(fontSize: 26, withAge: true)
            currentName = nameLabel.text ?? ""
            uidLabel.text = "ID: \(profile.uid)"
            avatarIV.updateAvatar(with: profile)
            if isSelf {
                editBtn.isHidden = false
            }
            profile.decorations.forEach({ (deco) in
                skinView.updateLook(deco)
            })
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
        }
        
        private func bindSubviewEvent() {
            
        }
        
        private func setupLayout() {
            
            let navLayoutGuide = UIView()
            navLayoutGuide.backgroundColor = .clear
            addSubview(navLayoutGuide)
            navLayoutGuide.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview()
                maker.top.equalTo(Frame.Height.safeAeraTopHeight)
                maker.height.equalTo(49)
            }
            
            addSubviews(views: infoContainer, skinView, backBtn, titleLabel, loginButton)
            
            skinView.addSubview(customizeBtn)
                        
            titleLabel.snp.makeConstraints { (maker) in
                maker.centerX.equalToSuperview()
                maker.centerY.equalTo(navLayoutGuide)
            }
            
            backBtn.snp.makeConstraints { (maker) in
                maker.leading.equalToSuperview().offset(12.5)
                maker.centerY.equalTo(navLayoutGuide)
                maker.width.height.equalTo(40)//25
            }
            
            loginButton.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(20)
                maker.bottom.equalToSuperview().offset(-88)
                maker.height.equalTo(48)
            }
            if !isSelf {
                addSubview(moreBtn)
                moreBtn.snp.makeConstraints { (make) in
                    make.right.equalTo(-15)
                    make.centerY.equalTo(backBtn.snp.centerY)
                    make.width.height.equalTo(40)//24
                }
                loginButton.isHidden = true
            } else {
                addSubview(settingsBtn)
                settingsBtn.snp.makeConstraints { (maker) in
                    maker.centerY.equalTo(navLayoutGuide)
                    maker.right.equalToSuperview().inset(20)
                }
                
                titleLabel.isHidden = true
                
                addSubview(proBtn)
                proBtn.snp.makeConstraints { (maker) in
                    maker.centerY.equalTo(navLayoutGuide)
                    maker.right.equalTo(settingsBtn.snp.left).offset(-16)
                    maker.height.equalTo(40)
                }
                
                Settings.shared.loginResult.replay()
                    .subscribe(onNext: { [weak self] (_) in
                        self?.loginButton.isHidden = AmongChat.Login.isLogedin
                    })
                    .disposed(by: bag)
            }

            infoContainer.addSubviews(views: avatarIV, changeIcon, editBtn, relationContainer, redCountLabel)

            followingBtn.snp.makeConstraints { (maker) in
                maker.leading.top.bottom.equalToSuperview()
                maker.trailing.equalTo(followerBtn.snp.leading)
                maker.width.equalTo(followerBtn)
            }
            
            lineView.snp.makeConstraints { maker in
                maker.top.equalToSuperview().offset(9)
                maker.width.equalTo(2)
                maker.height.equalTo(24)
                maker.centerX.equalToSuperview()
            }
            
            followerBtn.snp.makeConstraints { (maker) in
                maker.trailing.top.bottom.equalToSuperview()
            }
            
            skinView.snp.makeConstraints { maker in
                maker.top.leading.trailing.equalToSuperview()
                maker.height.equalTo(skinView.snp.width)
            }
            
            customizeBtn.snp.makeConstraints { maker in
                maker.trailing.equalTo(-20)
                maker.bottom.equalTo(-20)
                maker.height.equalTo(36)
            }
            
            infoContainer.snp.makeConstraints { maker in
                maker.top.equalTo(skinView.snp.bottom)
                maker.leading.trailing.bottom.equalToSuperview()
            }

            setCommonLayout()
            
            if !isSelf {
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

        private func setCommonLayout() {
            
            avatarIV.snp.makeConstraints { (maker) in
                maker.top.equalTo(24)
                maker.leading.equalTo(20)
                maker.height.width.equalTo(80)
            }
            
            changeIcon.snp.makeConstraints { (maker) in
                maker.bottom.equalTo(avatarIV)
                maker.trailing.equalTo(avatarIV).offset(1)
                maker.width.height.equalTo(24)
            }
            
            let infoContainer = UIView()
            addSubview(infoContainer)
            infoContainer.snp.makeConstraints { maker in
                maker.leading.equalTo(avatarIV.snp.trailing).offset(16)
                maker.centerY.equalTo(avatarIV)
                maker.trailing.equalTo(-56)
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
            }
            editBtn.isHidden = true
            
            relationContainer.snp.makeConstraints { maker in
                maker.leading.trailing.equalToSuperview()
                maker.top.equalTo(avatarIV.snp.bottom).offset(33)
            }
            
            redCountLabel.snp.makeConstraints { (make) in
                make.leading.equalTo(followerBtn.titleLabel.snp.trailing).offset(4)
                make.centerY.equalTo(followerBtn.titleLabel.snp.centerY)
                make.height.equalTo(16)
                make.width.greaterThanOrEqualTo(30)
            }
        }
        
        private func setLayoutForOther() {
            editBtn.isHidden = true
            changeIcon.isHidden = true
            customizeBtn.isHidden = true
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
    
    class ProfileTableCell: UITableViewCell {
        
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
            lb.font = R.font.nunitoExtraBold(size: 16)
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
                maker.leading.equalTo(16)
            }
            
            titleLabel.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.leading.equalTo(leftIconIV.snp.trailing).offset(12)
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
            lb.font = R.font.nunitoExtraBold(size: 22)
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
                maker.height.equalTo(30)
            }
            
            subtitleLabel.snp.makeConstraints { (maker) in
                maker.top.equalTo(titleLabel.snp.bottom).inset(4)
                maker.leading.trailing.bottom.equalToSuperview()
                maker.height.equalTo(19)
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

extension Social.ProfileViewController {
    
    class GameCell: UITableViewCell {
        
        private let bag = DisposeBag()
        
        private lazy var nameLabel: UILabel = {
            let lb = UILabel()
            lb.textColor = UIColor(hexString: "#FFFFFF")
            lb.font = R.font.bungeeRegular(size: 20)
            lb.adjustsFontSizeToFitWidth = true
            return lb
        }()
        
        private lazy var deleteButton: SmallSizeButton = {
            let btn = SmallSizeButton(type: .custom)
            btn.setImage(R.image.ac_profile_delete_game_stats(), for: .normal)
            btn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] (_) in
                    self?.deleteHandler?()
                })
                .disposed(by: bag)
            return btn
        }()
        
        private lazy var statsIV: UIImageView = {
            let i = UIImageView()
            i.contentMode = .scaleAspectFill
            i.clipsToBounds = true
            return i
        }()
        
        private lazy var gradientLayer: CAGradientLayer = {
            let l = CAGradientLayer()
            l.colors = [UIColor(hex6: 0x303030).cgColor, UIColor(hex6: 0x222222).cgColor]
            l.startPoint = CGPoint(x: 0, y: 0)
            l.endPoint = CGPoint(x: 1, y: 0)
            return l
        }()
        
        var deleteHandler: (() -> Void)? = nil
                
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupLayout() {
            backgroundColor = .clear
            selectionStyle = .none
            
            let container = UIView()
            container.backgroundColor = .clear
            container.layer.addSublayer(gradientLayer)
            
            container.addSubviews(views: nameLabel, deleteButton, statsIV)
            contentView.addSubview(container)
                        
            container.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(20)
                maker.top.bottom.equalToSuperview().inset(12)
            }
            
            container.layer.cornerRadius = 12
            container.layer.masksToBounds = true
            
            let titleLayout = UILayoutGuide()
            container.addLayoutGuide(titleLayout)
            titleLayout.snp.makeConstraints { (maker) in
                maker.leading.top.trailing.equalToSuperview()
                maker.height.equalTo(44)
            }
            
            nameLabel.snp.makeConstraints { (maker) in
                maker.leading.equalTo(16)
                maker.centerY.equalTo(titleLayout)
                maker.height.equalTo(20)
                maker.trailing.lessThanOrEqualTo(deleteButton.snp.leading).offset(-23)
            }
            
            deleteButton.snp.makeConstraints { (maker) in
                maker.width.height.equalTo(20)
                maker.centerY.equalTo(titleLayout)
                maker.trailing.equalTo(-12)
            }
            
            statsIV.snp.makeConstraints { (maker) in
                maker.leading.trailing.bottom.equalToSuperview()
                maker.top.equalTo(titleLayout.snp.bottom)
            }
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            contentView.layoutIfNeeded()
            gradientLayer.frame = contentView.bounds
        }
        
        func bind(_ game: Entity.UserGameSkill) {
            nameLabel.text = game.topicName.uppercased()
            statsIV.setImage(with: game.img)
        }
    }
    
}

extension Social.ProfileViewController {
    
    class GroupAvatarView: UIView {
        
        private let bag = DisposeBag()
        
        private lazy var nameLabel: UILabel = {
            let lb = UILabel()
            lb.textColor = UIColor(hexString: "#FFFFFF")
            lb.font = R.font.nunitoExtraBold(size: 14)
            return lb
        }()
        
        private lazy var coverIV: UIImageView = {
            let i = UIImageView()
            i.layer.cornerRadius = 12
            i.clipsToBounds = true
            i.contentMode = .scaleAspectFill
            return i
        }()
        
        lazy var gradientMusk: CAGradientLayer = {
            let l = CAGradientLayer()
            l.colors = [UIColor(hex6: 0x000000, alpha: 0).cgColor, UIColor(hex6: 0x000000, alpha: 0.16).cgColor, UIColor(hex6: 0x000000, alpha: 1).cgColor]
            l.startPoint = CGPoint(x: 0.5, y: 0.5)
            l.endPoint = CGPoint(x: 0.5, y: 1.22)
            l.locations = [0, 0.2, 1]
            l.cornerRadius = 12
            l.opacity = 0.6
            return l
        }()
        
        private lazy var onlineStatusView: UIView = {
            let v = UIView()
            v.backgroundColor = UIColor(hex6: 0xFFFFFF)
            v.layer.borderColor = UIColor(hex6: 0x121212).cgColor
            v.layer.borderWidth = 2.5
            v.layer.cornerRadius = 12
            
            let lb = UILabel()
            lb.adjustsFontSizeToFitWidth = true
            lb.font = R.font.nunitoExtraBold(size: 12)
            lb.textColor = .black
            lb.text = R.string.localizable.socialStatusOnline()
            
            let dot = UIView()
            dot.backgroundColor = UIColor(hex6: 0x1FD300)
            dot.layer.cornerRadius = 3.5
            
            v.addSubviews(views: dot, lb)
            
            dot.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.leading.equalTo(8)
                maker.width.height.equalTo(7)
            }
            
            lb.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 17, bottom: 4, right: 8))
                maker.height.equalTo(16)
            }
            
            v.clipsToBounds = true
            
            return v
        }()
        
        var tapHandler: (() -> Void)? = nil
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setUpLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            gradientMusk.frame = bounds
        }
        
        private func setUpLayout() {
            
            addSubviews(views: coverIV, nameLabel, onlineStatusView)
            
            layer.insertSublayer(gradientMusk, above: coverIV.layer)
            
            coverIV.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
            
            nameLabel.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(7)
                maker.bottom.equalTo(-4)
            }
            
            onlineStatusView.snp.makeConstraints { (maker) in
                maker.trailing.equalToSuperview().offset(2.5)
                maker.top.equalTo(-10)
                maker.width.equalTo(64)
            }
            
            let tap = UITapGestureRecognizer()
            addGestureRecognizer(tap)
            tap.rx.event
                .subscribe(onNext: { [weak self] (_) in
                    self?.tapHandler?()
                })
                .disposed(by: bag)
        }
        
        func bindData(_ group: Entity.Group, tapHandler: (() -> Void)? = nil) {
            coverIV.setImage(with: group.cover.url)
            nameLabel.text = group.name
            self.tapHandler = tapHandler
            #if DEBUG
            onlineStatusView.isHidden = false
            #else
            onlineStatusView.isHidden = group.status == 0
            #endif
        }
        
    }
        
    class JoinedGroupsCell: UITableViewCell {
        
        class var groupViewWidth: CGFloat {
            let width = ((Frame.Screen.width - 20 * 2 - 16 * 2) / 3).rounded(.towardZero)
            return width
        }
        
        private var groupViews = [GroupAvatarView]()
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupLayout() {
            backgroundColor = .clear
            selectionStyle = .none
            contentView.backgroundColor = .clear
            
            contentView.snp.makeConstraints { (maker) in
                maker.top.bottom.equalToSuperview().inset(12)
                maker.leading.trailing.equalToSuperview().inset(20)
            }
        }
        
        func bind(_ groups: [Entity.Group], onGroupTapped: ((Entity.Group) -> Void)? = nil) {
            
            let groupAvatarViews = groups.map { (group) -> GroupAvatarView in
                let g = GroupAvatarView()
                g.bindData(group) {
                    onGroupTapped?(group)
                }
                return g
            }
            
            groupViews.forEach { (v) in
                v.removeFromSuperview()
            }
            
            groupViews = groupAvatarViews
            
            contentView.addSubviews(groupViews)
            
            for (idx, v) in groupViews.enumerated() {
                v.snp.makeConstraints { (maker) in
                    maker.width.height.equalTo(Self.groupViewWidth)
                    maker.top.equalToSuperview()
                    maker.leading.equalToSuperview().offset(idx.cgFloat * (Self.groupViewWidth + 16))
                }
            }
        }
    }
    
}
