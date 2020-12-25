//
//  Social.ProfileViewController.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/8/27.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

extension Social {
    
    class ProfileViewController: ViewController {
        
        enum Option {
            case inviteFriends
            case settings
            case community
            case blockUser
            
            func image() -> UIImage? {
                switch self {
                case .inviteFriends:
                    return R.image.profile_invite_friends()
                case .settings:
                    return R.image.profile_settings()
                case .community:
                    return R.image.ac_profile_communtiy()
                case .blockUser:
                    return R.image.ac_profile_block()
                }
            }
            
            func text() -> String {
                switch self {
                case .inviteFriends:
                    return R.string.localizable.profileInviteFriends()
                case .settings:
                    return R.string.localizable.profileSettings()
                case .community:
                    return R.string.localizable.profileCommunity()
                case .blockUser:
                    return R.string.localizable.profileBlockUser()
                }
            }
        }
        
        private lazy var backBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.addTarget(self, action: #selector(onBackBtn), for: .primaryActionTriggered)
            btn.setImage(R.image.ac_profile_close(), for: .normal)
            return btn
        }()
        
        private lazy var headerView: ProfileView = {
            let v = ProfileView()
            v.frame = CGRect(x: 0, y: 0, width: Frame.Screen.width, height: 298)
            v.editBtnHandler = { [weak self] in
                let vc = Social.EditProfileViewController()
                self?.navigationController?.pushViewController(vc)
            }
            v.avatarBtnHandler = { [weak self] in
                let vc = Social.SelectAvatarViewController()
                self?.navigationController?.pushViewController(vc)
            }
            return v
        }()
        
        private lazy var table: UITableView = {
            let tb = UITableView(frame: .zero, style: .plain)
            tb.register(TableCell.self, forCellReuseIdentifier: NSStringFromClass(TableCell.self))
            tb.dataSource = self
            tb.delegate = self
            tb.separatorStyle = .none
            tb.showsVerticalScrollIndicator = false
            tb.backgroundColor = UIColor.theme(.backgroundBlack)
            tb.rowHeight = 75
            tb.neverAdjustContentInset()
            return tb
        }()
        
        private lazy var options: [Option] = {
            return [
                .inviteFriends,
                .settings,
                .community,
                .blockUser,
            ]
        }()
        
        override var screenName: Logger.Screen.Node.Start {
            return .profile
        }
        
        // MARK: - life
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
            setupData()
            AdsManager.shared.requestRewardVideoIfNeed()
            //            //AD
            //            rx.viewDidAppear
            //                .take(1)
            //                .subscribe(onNext: { [weak self] (_) in
            //                    guard let `self` = self else { return }
            //                    Ad.InterstitialManager.shared.showAdIfReady(from: self)
            //                })
            //                .disposed(by: bag)
            
            rx.viewDidAppear
                .take(1)
                .subscribe(onNext: { (_) in
                    Logger.Action.log(.profile_imp, category: nil)
                })
                .disposed(by: bag)
        }
    }
}
private extension Social.ProfileViewController {
    func setupLayout() {
        isNavigationBarHiddenWhenAppear = true
        statusBarStyle = .lightContent
        view.backgroundColor = UIColor(hex6: 0x121212, alpha: 1.0)
        
        view.addSubviews(views: table, backBtn)
        table.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        backBtn.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview().offset(20)
            maker.top.equalTo(16 + Frame.Height.safeAeraTopHeight)
            maker.width.height.equalTo(25)
        }
        
        table.tableHeaderView = headerView
        
        table.reloadData()
    }
    
    func setupData() {
        
        Settings.shared.amongChatUserProfile.replay()
            .subscribe(onNext: { [weak self] (profile) in
                guard let profile = profile else { return }
                self?.headerView.configProfile(profile)
            })
            .disposed(by: bag)
        
        if Settings.shared.amongChatUserProfile.value == nil {
            let hudRemoval = view.raft.show(.loading, userInteractionEnabled: false)
            Request.profile()
                .do(onDispose: {
                    hudRemoval()
                })
                .subscribe(onSuccess: { (profile) in
                    guard let p = profile else {
                        return
                    }
                    Settings.shared.amongChatUserProfile.value = p
                }, onError: { (error) in
                })
                .disposed(by: bag)
        }
        
        Settings.shared.amongChatAvatarListShown.replay()
            .subscribe(onNext: { [weak self] (ts) in
                if let _ = ts {
                    self?.headerView.changeIcon.redDotOff()
                } else {
                    self?.headerView.changeIcon.redDotOn()
                }
            })
            .disposed(by: bag)

    }
    
    @objc
    func onBackBtn() {
        navigationController?.popViewController()
    }
}
// MARK: - UITableView
extension Social.ProfileViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(TableCell.self), for: indexPath)
        cell.backgroundColor = .clear
        if let tableCell = cell as? TableCell,
           let op = options.safe(indexPath.row) {
            tableCell.configCell(with: op)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let op = options.safe(indexPath.row) {
            switch op {
            case .inviteFriends:
                Logger.Action.log(.profile_invite_friend_clk, category: nil)
                let removeHUDBlock = view.raft.show(.loading, userInteractionEnabled: false)
                let removeBlock = { [weak self] in
                    self?.view.isUserInteractionEnabled = true
                    removeHUDBlock()
                }
                
                self.view.isUserInteractionEnabled = false
                ShareManager.default.showActivity(viewController: self) { () in
                    removeBlock()
                }
            case .blockUser:
                let vc = Social.BlockedUserList.ViewController()
                navigationController?.pushViewController(vc)
            case .settings:
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "SettingViewController")
                navigationController?.pushViewController(vc)
            case .community:
                self.open(urlSting: Config.PolicyType.url(.guideline))
            }
        }
    }
}

// MARK: - Widgets
extension Social.ProfileViewController {
    
    private class ProfileView: UIView {
        
        var editBtnHandler: (() -> Void)? = nil
        var followingBtnHandler: (() -> Void)? = nil
        var followerBtnHandler: (() -> Void)? = nil
        
        private lazy var titleLabel: WalkieLabel = {
            let lb = WalkieLabel()
            lb.font = R.font.nunitoExtraBold(size: 24)
            lb.textColor = .white
            lb.textAlignment = .center
            lb.text = R.string.localizable.profileProfile()
            return lb
        }()
        var avatarBtnHandler: (() -> Void)? = nil
        
        private lazy var avatarIV: UIImageView = {
            let iv = UIImageView()
            iv.layer.cornerRadius = 45
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
            lb.font = R.font.nunitoExtraBold(size: 20)
            lb.textColor = .white
            lb.textAlignment = .center
            return lb
        }()
        
        private lazy var followingBtn: VerticalTitleButton = {
            let v = VerticalTitleButton()
            v.setSubtitle(R.string.localizable.profileFollowing())
            let tapGR = UITapGestureRecognizer()
            tapGR.addTarget(self, action: #selector(onFollowingBtn))
            v.isUserInteractionEnabled = true
            v.addGestureRecognizer(tapGR)
            return v
        }()
        
        private lazy var followerBtn: VerticalTitleButton = {
            let v = VerticalTitleButton()
            v.setSubtitle(R.string.localizable.profileFollower())
            let tapGR = UITapGestureRecognizer()
            tapGR.addTarget(self, action: #selector(onFollowerBtn))
            v.isUserInteractionEnabled = true
            v.addGestureRecognizer(tapGR)
            return v
        }()
        
        private lazy var editBtn: UIButton = {
            let btn = WalkieButton(type: .custom)
            btn.backgroundColor = .white
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 12)
            btn.addTarget(self, action: #selector(onEditBtn), for: .primaryActionTriggered)
            btn.layer.cornerRadius = 14
            btn.contentHorizontalAlignment = .left
            btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 0)
            btn.titleEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 12)
            btn.setTitleColor(.black, for: .normal)
            btn.setImage(R.image.ac_profile_edit(), for: .normal)
            btn.setTitle(R.string.localizable.profileEdit(), for: .normal)
            return btn
        }()
        
        init() {
            super.init(frame: .zero)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func configProfile(_ profile: Entity.UserProfile) {
            
            if let b = profile.birthday, !b.isEmpty {
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyyMMdd"
                
                if let startDate = dateFormatter.date(from: b)  {
                    
                    let endDate = Date()
                    
                    let calendar = Calendar.current
                    let calcAge = calendar.dateComponents([.year], from: startDate, to: endDate)
                    
                    if let age = calcAge.year?.string, !age.isEmpty {
                        nameLabel.text = "\(profile.name ?? ""), \(age)"
                    } else {
                        nameLabel.text = profile.name
                    }
                } else {
                    nameLabel.text = profile.name
                }
            } else {
                nameLabel.text = profile.name
            }
            
            nameLabel.appendKern()
            
            avatarIV.setAvatarImage(with: profile.pictureUrl)
            
            editBtn.isHidden = false
        }
        
        func configFollowerCount(_ followerCount: Int) {
            followerBtn.setTitle("\(followerCount)")
        }
        
        func configFollowingCount(_ followingCount: Int) {
            followingBtn.setTitle("\(followingCount)")
        }
        
        private func setupLayout() {
            
            addSubviews(views: titleLabel, avatarIV, changeIcon,nameLabel, editBtn)
            
            titleLabel.snp.makeConstraints { (maker) in
                maker.top.equalTo(12 + Frame.Height.safeAeraTopHeight)
                maker.centerX.equalToSuperview()
            }
            
            avatarIV.snp.makeConstraints { (maker) in
                maker.top.equalTo(titleLabel.snp.bottom).offset(28)
                maker.centerX.equalToSuperview()
                maker.height.width.equalTo(90)
            }
            
            changeIcon.snp.makeConstraints { (maker) in
                maker.bottom.equalTo(avatarIV)
                maker.right.equalTo(avatarIV).offset(1)
            }
            
            nameLabel.snp.makeConstraints { (maker) in
                maker.top.equalTo(avatarIV.snp.bottom).offset(8)
                maker.centerX.equalToSuperview()
                maker.left.greaterThanOrEqualToSuperview().offset(25)
            }
            
            editBtn.snp.makeConstraints { (maker) in
                maker.top.equalTo(nameLabel.snp.bottom).offset(12)
                maker.height.equalTo(28)
                maker.width.greaterThanOrEqualTo(74)
                maker.centerX.equalToSuperview()
            }
            editBtn.isHidden = true
        }
        
        @objc
        private func onEditBtn() {
            editBtnHandler?()
        }
        
        @objc
        private func onFollowingBtn() {
            followingBtnHandler?()
        }
        
        @objc
        private func onFollowerBtn() {
            followerBtnHandler?()
        }
        
        @objc
        private func onAvatarTapped() {
            avatarBtnHandler?()
        }
    }
}

extension Social.ProfileViewController {
    
    private class TableCell: UITableViewCell {
        
        private lazy var iconIV: UIImageView = {
            let iv = UIImageView()
            return iv
        }()
        
        private lazy var titleLabel: WalkieLabel = {
            let lb = WalkieLabel()
            lb.font = R.font.nunitoExtraBold(size: 20)
            lb.textColor = .white
            return lb
        }()
        
        private lazy var backView = UIView()
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func configCell(with option: Option) {
            iconIV.image = option.image()
            titleLabel.text = option.text()
            titleLabel.appendKern()
        }
        
        private func setupLayout() {
            self.backgroundColor = UIColor.theme(.backgroundBlack)
            selectionStyle = .none
            contentView.addSubviews(views: backView)
            
            backView.snp.makeConstraints { (maker) in
                maker.left.equalTo(20)
                maker.right.equalTo(-20)
                maker.top.equalToSuperview()
                maker.height.equalTo(76)
                maker.bottom.equalTo(-12)
            }
            
            backView.addSubviews(views: iconIV, titleLabel)
            
            iconIV.snp.makeConstraints { (maker) in
                maker.width.height.equalTo(30)
                maker.left.centerY.equalToSuperview()
            }
            
            titleLabel.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.left.equalTo(iconIV.snp.right).offset(12)
            }
        }
        
    }
    private class VerticalTitleButton: UIView {
        private lazy var titleLabel: WalkieLabel = {
            let lb = WalkieLabel()
            lb.textAlignment = .center
            lb.font = R.font.nunitoSemiBold(size: 14)
            lb.textColor = .black
            return lb
        }()
        
        private lazy var subtitleLabel: WalkieLabel = {
            let lb = WalkieLabel()
            lb.textAlignment = .center
            lb.font = R.font.nunitoSemiBold(size: 12)
            lb.textColor = UIColor(hex6: 0x000000, alpha: 0.5)
            return lb
        }()
        
        init() {
            super.init(frame: .zero)
            addSubviews(views: titleLabel, subtitleLabel)
            titleLabel.snp.makeConstraints { (maker) in
                maker.left.top.right.equalToSuperview()
                maker.height.equalTo(19)
            }
            subtitleLabel.snp.makeConstraints { (maker) in
                maker.left.right.bottom.equalToSuperview()
                maker.height.equalTo(16)
                maker.top.equalTo(titleLabel.snp.bottom)
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
