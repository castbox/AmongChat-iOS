//
//  Social.ProfileViewController.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/8/27.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

extension Social {
    
    class ProfileViewController: ViewController {
        
        enum Option {
            case inviteFriends
            case blockUser
            case settings
            
            func image() -> UIImage? {
                switch self {
                case .inviteFriends:
                    return R.image.profile_invite_friends()
                case .blockUser:
                    return R.image.profile_block_users()
                case .settings:
                    return R.image.profile_settings()
                }
            }
            
            func text() -> String {
                switch self {
                case .inviteFriends:
                    return R.string.localizable.profileInviteFriends()
                case .blockUser:
                    return R.string.localizable.profileBlockUser()
                case .settings:
                    return R.string.localizable.profileSettings()
                }
            }
        }
        
        private lazy var headerView: ProfileView = {
            let v = ProfileView()
            v.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 273)
            v.editBtnHandler = { [weak self] in
                let vc = Social.EditProfileViewController()
                self?.navigationController?.pushViewController(vc)
            }
            v.followingBtnHandler = { [weak self] in
                let vc = Social.RelationsViewController(.followingTab)
                self?.navigationController?.pushViewController(vc)
            }
            v.followerBtnHandler = { [weak self] in
                let vc = Social.RelationsViewController(.followerTab)
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
            tb.backgroundColor = UIColor(hex6: 0xFFD52E, alpha: 1.0)
            return tb
        }()
        
        private lazy var options: [Option] = {
            return [
            .inviteFriends,
            .blockUser,
            .settings
            ]
        }()
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
            setupData()
        }
        
        private func setupLayout() {
            isNavigationBarHiddenWhenAppear = true
            view.backgroundColor = UIColor(hex6: 0xFFD52E, alpha: 1.0)

            view.addSubview(table)
            table.snp.makeConstraints { (maker) in
                maker.left.right.equalToSuperview()
                maker.top.equalTo(topLayoutGuide.snp.bottom)
                maker.bottom.equalTo(bottomLayoutGuide.snp.top)
            }
            
            table.tableHeaderView = headerView
            table.reloadData()
        }
        
        private func setupData() {
                        
            Settings.shared.firestoreUserProfile.replay()
                .subscribe(onNext: { [weak self] (profile) in
                    guard let profile = profile else { return }
                    self?.headerView.configProfile(profile)
                })
                .disposed(by: bag)
            
            Social.Module.shared.followingObservable
                .map { $0.count }
                .subscribe(onNext: { [weak self] (count) in
                    self?.headerView.configFollowingCount(count)
                })
                .disposed(by: bag)
            
            Social.Module.shared.followerObservable
                .map { $0.count }
                .subscribe(onNext: {  [weak self] (count) in
                    self?.headerView.configFollowerCount(count)
                })
                .disposed(by: bag)
        }
        
    }
}

extension Social.ProfileViewController: UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - UITableView
    
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
                ()
            case .blockUser:
                let vc = Social.BlockedUserViewController()
                navigationController?.pushViewController(vc)
            case .settings:
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "SettingViewController")
                navigationController?.pushViewController(vc)
            }
        }
    }
}

// MARK: - Widgets

extension Social.ProfileViewController {
    
    private class ProfileView: UIView {
        
        private lazy var avatarIV: UIImageView = {
            let iv = UIImageView()
            iv.layer.cornerRadius = 40
            iv.layer.masksToBounds = true
            #if DEBUG
            iv.backgroundColor = .gray
            #endif
            return iv
        }()
        
        private lazy var nameLabel: WalkieLabel = {
            let lb = WalkieLabel()
            lb.font = R.font.nunitoSemiBold(size: 20)
            lb.textColor = .black
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
        
        var followingBtnHandler: (() -> Void)? = nil
        var followerBtnHandler: (() -> Void)? = nil
        var editBtnHandler: (() -> Void)? = nil
        
        private lazy var EditBtn: UIButton = {
            let btn = WalkieButton(type: .custom)
            btn.backgroundColor = UIColor(hex6: 0xFFFFFF, alpha: 0.5)
            btn.titleLabel?.font = R.font.nunitoSemiBold(size: 14)
            btn.addTarget(self, action: #selector(onEditBtn), for: .primaryActionTriggered)
            btn.layer.cornerRadius = 20
            btn.setTitle(R.string.localizable.profileEdit(), for: .normal)
            btn.setTitleColor(.black, for: .normal)
            btn.appendKern()
            return btn
        }()
        
        init() {
            super.init(frame: .zero)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupLayout() {
            
            let seperator = UIView(frame: CGRect(x: 0, y: 0, width: 0.5, height: 25))
            seperator.backgroundColor = UIColor(hex6: 0x000000, alpha: 0.87)
                        
            let btnStack = UIStackView(arrangedSubviews: [followingBtn, seperator, followerBtn],
                                       axis: .horizontal,
                                       spacing: 15,
                                       alignment: .center,
                                       distribution: .equalSpacing)
            
            let avatarBorder = UIView()
            
            addSubviews(views: avatarBorder, avatarIV, nameLabel, btnStack, EditBtn)
            
            avatarIV.snp.makeConstraints { (maker) in
                maker.top.equalToSuperview().offset(16)
                maker.centerX.equalToSuperview()
                maker.height.width.equalTo(80)
            }
            
            avatarBorder.snp.makeConstraints { (maker) in
                maker.edges.equalTo(avatarIV).inset(-2)
            }
            avatarBorder.layer.cornerRadius = 42
            avatarBorder.layer.borderWidth = 2
            avatarBorder.layer.borderColor = UIColor(hex6: 0xFFFFFF, alpha: 0.25).cgColor
            
            nameLabel.snp.makeConstraints { (maker) in
                maker.top.equalTo(avatarIV.snp.bottom).offset(10)
                maker.centerX.equalToSuperview()
                maker.left.greaterThanOrEqualToSuperview().offset(25)
            }
            
            btnStack.snp.makeConstraints { (maker) in
                maker.top.equalTo(nameLabel.snp.bottom)
                maker.centerX.equalToSuperview()
            }
            
            EditBtn.snp.makeConstraints { (maker) in
                maker.top.equalTo(btnStack.snp.bottom).offset(25)
                maker.height.equalTo(40)
                maker.width.greaterThanOrEqualTo(122)
                maker.centerX.equalToSuperview()
            }
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
        
        func configProfile(_ profile: FireStore.Entity.User.Profile) {
            nameLabel.text = profile.name
            nameLabel.appendKern()
            
            let _ = profile.avatarObservable
                .subscribe(onSuccess: { [weak self] (image) in
                    self?.avatarIV.image = image
                })
        }
        
        func configFollowerCount(_ followerCount: Int) {
            followerBtn.setTitle("\(followerCount)")
        }
        
        func configFollowingCount(_ followingCount: Int) {
            followingBtn.setTitle("\(followingCount)")
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
}

extension Social.ProfileViewController {
    
    private class TableCell: UITableViewCell {
        
        private lazy var iconIV: UIImageView = {
            let iv = UIImageView()
            return iv
        }()
        
        private lazy var titleLabel: WalkieLabel = {
            let lb = WalkieLabel()
            lb.font = R.font.nunitoSemiBold(size: 16)
            lb.textColor = .black
            return lb
        }()
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
        }
        
        private func setupLayout() {
            selectionStyle = .none
            contentView.addSubviews(views: iconIV, titleLabel)
            
            iconIV.snp.makeConstraints { (maker) in
                maker.width.height.equalTo(50)
                maker.left.equalTo(25)
                maker.centerY.equalToSuperview()
            }
            
            titleLabel.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.left.equalTo(90)
            }
        }
        
        func configCell(with option: Option) {
            iconIV.image = option.image()
            titleLabel.text = option.text()
            titleLabel.appendKern()
        }
        
    }
}
