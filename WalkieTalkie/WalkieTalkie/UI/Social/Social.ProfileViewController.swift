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
import SwiftyUserDefaults

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
        
        var isPresent = true
        
        private lazy var backBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.setImage(R.image.ac_profile_close(), for: .normal)
            btn.rx.tap.observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self]() in
                    guard let `self` = self else { return }
                    if self.isPresent {
                        self.hideModal()
                    } else {
                        self.navigationController?.popViewController()
                    }
                }).disposed(by: bag)
            return btn
        }()
        
        private lazy var moreBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.setImage(UIImage(named: "ac_profile_more_icon"), for: .normal)
            return btn
        }()
        
        private lazy var headerView: ProfileView = {
            let v = ProfileView(with: isSelfProfile)
            let vH: CGFloat = isSelfProfile ? 276:414
            v.frame = CGRect(x: 0, y: 0, width: Frame.Screen.width, height: vH)//298  413
            v.headerHandle = { [weak self] type in
                guard let `self` = self else { return }
                switch type {
                case .avater:
                    let vc = Social.SelectAvatarViewController()
                    self.navigationController?.pushViewController(vc)
                case .edit:
                    let vc = Social.EditProfileViewController()
                    self.navigationController?.pushViewController(vc)
                case .follow:
                    self.followAction()
                case .follower:
                    self.followerAction()
                case .following:
                    self.followingAction()
                }
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
            return [.inviteFriends, .settings, .community, .blockUser, ]
        }()
        private var relationData: Entity.RelationData?
        
        override var screenName: Logger.Screen.Node.Start {
            return .profile
        }
        
        private var uid = 0
        private var isSelfProfile = true
        private var blocked = false
        private var userProfile: Entity.UserProfile?
        
        init(with uid: Int) {
            super.init(nibName: nil, bundle: nil)
            self.uid = uid
            let selfUid = Settings.shared.amongChatUserProfile.value?.uid ?? 0
            cdPrint(" uid is \(uid)  self uid is \(selfUid)")
            self.isSelfProfile = uid == selfUid
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
            setupData()
            AdsManager.shared.requestRewardVideoIfNeed()
        }
    }
}

extension Social.ProfileViewController: Modalable {
    func style() -> Modal.Style {
        return .customHeight
    }
    
    func height() -> CGFloat {
        return Frame.Screen.height
    }
    
    func modalPresentationStyle() -> UIModalPresentationStyle {
        return .overCurrentContext
    }
    
    func cornerRadius() -> CGFloat {
        return 0
    }
    
    func coverAlpha() -> CGFloat {
        return 0.5
    }
    
    func canAutoDismiss() -> Bool {
        return true
    }

}

private extension Social.ProfileViewController {
    func setupLayout() {
        isNavigationBarHiddenWhenAppear = true
        statusBarStyle = .lightContent
        view.backgroundColor = UIColor.theme(.backgroundBlack)
        
        view.addSubviews(views: table, backBtn)
        table.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        backBtn.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview().offset(20)
            maker.top.equalTo(16 + Frame.Height.safeAeraTopHeight)
            maker.width.height.equalTo(25)
        }
        if !isSelfProfile {
            options.removeAll()
            view.addSubview(moreBtn)
            moreBtn.snp.makeConstraints { (make) in
                make.right.equalTo(-20)
                make.centerY.equalTo(backBtn.snp.centerY)
                make.width.height.equalTo(24)
            }
        }
        table.tableHeaderView = headerView
        table.reloadData()
    }
    
    func loadData() {
        let removeBlock = view.raft.show(.loading)
        Request.profilePage(uid: uid)
            .subscribe(onSuccess: { [weak self](data) in
                guard let data = data, let `self` = self else { return }
                self.userProfile = data.profile
                if let profile = data.profile {
                    self.headerView.configProfile(profile)
                }
                removeBlock()
            }, onError: { (error) in
                removeBlock()
            }).disposed(by: bag)
    }
    
    func setupData() {
        loadData()
        getRealation()
        if isSelfProfile {
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
        } else {
            moreBtn.rx.tap
                .subscribe(onNext: { [weak self]() in
                    self?.moreAction()
                }).disposed(by: bag)
        }
    }
    
    func getRealation() {
        Request.relationData(uid: uid)
            .subscribe(onSuccess: { [weak self](data) in
                guard let `self` = self, let data = data else { return }
                self.relationData = data
                self.blocked = data.isBlocked ?? false
                self.headerView.setViewData(data)
            }, onError: { (error) in
                cdPrint("relationData error :\(error.localizedDescription)")
            }).disposed(by: bag)
    }
    
    func followAction() {
        let removeBlock = view.raft.show(.loading)
        let isFollowed = relationData?.isFollowed ?? false
        if isFollowed {
            Request.unFollow(uid: uid, type: "follow")
                .subscribe(onSuccess: { [weak self](success) in
                    guard let `self` = self else { return }
                    removeBlock()
                    if success {
                        self.relationData?.isFollowed = false
                        self.headerView.setFollowButton(false)
                    }
                }, onError: { (error) in
                    removeBlock()
                    cdPrint("unfollow error:\(error.localizedDescription)")
                }).disposed(by: bag)
        } else {
            Request.follow(uid: uid, type: "follow")
                .subscribe(onSuccess: { [weak self](success) in
                    guard let `self` = self else { return }
                    removeBlock()
                    if success {
                        self.relationData?.isFollowed = true
                        self.headerView.setFollowButton(true)
                    }
                }, onError: { (error) in
                    removeBlock()
                    cdPrint("follow error:\(error.localizedDescription)")
                }).disposed(by: bag)
        }
    }
    
    func followerAction() {
        let vc = Social.FollowerViewController(with: uid, isFollowing: false)
        //        let vc = Social.LeaveGameViewController(with: uid)
        navigationController?.pushViewController(vc)
    }
    
    func followingAction() {
        let vc = Social.FollowerViewController(with: uid, isFollowing: true)
        navigationController?.pushViewController(vc)
    }
    
    func moreAction() {
        let block = relationData?.isBlocked ?? false
        var type:[AmongSheetController.ItemType]!
        if block {
            type = [.unblock, .report, .cancel]
        } else {
            type = [.block, .report, .cancel]
        }
        
        AmongSheetController.show(items: type, in: self, uiType: .profile) { [weak self](type) in
            switch type {
            case.report:
                self?.reportUser()
            case .block:
                self?.showBlockAlter()
            default:
                break
            }
        }
    }
    
    func showBlockAlter() {
        var message = "Are you sure to block this person"
        var confirmString = R.string.localizable.alertBlock()
        if blocked {
            message = "Are you sure to unblock this person"
            confirmString = R.string.localizable.alertUnblock()
        }
        showAmongAlert(title: nil, message: message,
                       cancelTitle: R.string.localizable.toastCancel(),
                       confirmTitle: confirmString) { [weak self] in
            self?.blockUser()
        }
    }
    
    func blockUser() {
        let removeBlock = view.raft.show(.loading)
        if blocked {
            Request.unFollow(uid: uid, type: "block")
                .subscribe(onSuccess: { [weak self](success) in
                    if success {
                        self?.blocked = false
                        self?.relationData?.isBlocked = false
                    }
                    removeBlock()
                }, onError: { (error) in
                    removeBlock()
                    
                }).disposed(by: bag)
        } else {
            Request.follow(uid: uid, type: "block")
                .subscribe(onSuccess: { [weak self](success) in
                    if success {
                        self?.blocked = true
                        self?.relationData?.isBlocked = true
                    }
                    removeBlock()
                }, onError: { (error) in
                    removeBlock()
                }).disposed(by: bag)
        }
    }
    
    func reportUser() {
        let removeBlock = view.raft.show(.loading)
        mainQueueDispatchAsync(after: 1.0) {
            removeBlock()
        }
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
        
        enum HeaderProfileAction {
            case edit
            case following
            case follower
            case avater
            case follow
        }
        
        let bag = DisposeBag()
        
        var headerHandle:((HeaderProfileAction) -> Void)?
        
        private lazy var titleLabel: WalkieLabel = {
            let lb = WalkieLabel()
            lb.font = R.font.nunitoExtraBold(size: 24)
            lb.textColor = .white
            lb.textAlignment = .center
            lb.text = R.string.localizable.profileProfile()
            return lb
        }()
        
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
        private var isSelf = true
        
        init(with isSelf: Bool) {
            super.init(frame: .zero)
            self.isSelf = isSelf
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
            
            avatarIV.setAvatarImage(with: profile.pictureUrl)
            if isSelf {
                editBtn.isHidden = false
            }
        }
        
        func setViewData(_ model: Entity.RelationData) {
            followerBtn.setTitle("\(model.followersCount ?? 0)")
            followingBtn.setTitle("\(model.followingCount ?? 0)")
            
            let follow = model.isFollowed ?? false
            setFollowButton(follow)
        }
        
        func setFollowButton(_ isFollowed: Bool) {
            if isFollowed {
                greyFollowButton()
            } else {
                yellowFollowButton()
            }
        }
        
        private func greyFollowButton() {
            followButton.setTitle("Following", for: .normal)
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
        
        private func setupLayout() {
            
            addSubviews(views: titleLabel, avatarIV,changeIcon, nameLabel, editBtn, followingBtn, followerBtn, followButton)
            
            titleLabel.snp.makeConstraints { (maker) in
                maker.top.equalTo(12 + Frame.Height.safeAeraTopHeight)
                maker.centerX.equalToSuperview()
            }
            if isSelf {
                setLayoutForSelf()
            } else {
                setLayoutForOther()
            }
        }
        
        private func setLayoutForSelf() {
            
            avatarIV.snp.makeConstraints { (maker) in
                maker.top.equalTo(titleLabel.snp.bottom).offset(48)
                maker.left.equalTo(20)
                maker.height.width.equalTo(100)
            }
            
            changeIcon.snp.makeConstraints { (maker) in
                maker.bottom.equalTo(avatarIV)
                maker.right.equalTo(avatarIV).offset(1)
            }
            
            nameLabel.snp.makeConstraints { (maker) in
                maker.top.equalTo(avatarIV.snp.top)
                maker.left.equalTo(avatarIV.snp.right).offset(20)
            }
            
            editBtn.snp.makeConstraints { (maker) in
                maker.right.equalTo(-20)
                maker.centerY.equalTo(nameLabel.snp.centerY)
                maker.height.width.equalTo(28)
            }
            editBtn.isHidden = true
            
            followingBtn.snp.makeConstraints { (maker) in
                maker.top.equalTo(nameLabel.snp.bottom).offset(12)
                maker.left.equalTo(avatarIV.snp.right).offset(20)
                maker.height.equalTo(43)
            }
            
            followerBtn.snp.makeConstraints { (maker) in
                maker.top.equalTo(followingBtn.snp.top)
                maker.left.equalTo(followingBtn.snp.right).offset(40)
                maker.height.equalTo(43)
            }
        }
        
        private func setLayoutForOther() {
            
            avatarIV.snp.makeConstraints { (maker) in
                maker.top.equalTo(titleLabel.snp.bottom).offset(48)
                maker.centerX.equalToSuperview()
                maker.height.width.equalTo(100)
            }
            
            nameLabel.snp.makeConstraints { (maker) in
                maker.top.equalTo(avatarIV.snp.bottom).offset(8)
                maker.centerX.equalToSuperview()
            }
            
            followingBtn.snp.makeConstraints { (maker) in
                maker.top.equalTo(nameLabel.snp.bottom).offset(8)
                maker.centerX.equalToSuperview().offset(-80)
                maker.height.equalTo(43)
            }
            
            followerBtn.snp.makeConstraints { (maker) in
                maker.top.equalTo(followingBtn.snp.top)
                maker.centerX.equalToSuperview().offset(80)
                maker.height.equalTo(43)
            }
            
            followButton.snp.makeConstraints { (maker) in
                maker.top.equalTo(followingBtn.snp.bottom).offset(40)
                maker.left.equalTo(40)
                maker.right.equalTo(-40)
                maker.height.equalTo(48)
            }
            followButton.rx.tap
                .subscribe(onNext: { [weak self]() in
                    self?.headerHandle?(.follow)
                }).disposed(by: bag)
            
            editBtn.isHidden = true
            changeIcon.isHidden = true
            followButton.isHidden = false
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
            
            contentView.addSubviews(views: iconIV, titleLabel)
            
            iconIV.snp.makeConstraints { (maker) in
                maker.top.equalToSuperview()
                maker.width.height.equalTo(30)
                maker.left.equalTo(20)
                maker.bottom.equalToSuperview().offset(40).priorityLow()
            }
            
            titleLabel.snp.makeConstraints { (maker) in
                maker.centerY.equalTo(iconIV.snp.centerY)
                maker.left.equalTo(iconIV.snp.right).offset(13)
            }
        }
        
    }
    private class VerticalTitleButton: UIView {
        private lazy var titleLabel: WalkieLabel = {
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
                maker.left.top.right.equalToSuperview()
            }
            subtitleLabel.snp.makeConstraints { (maker) in
                maker.top.equalTo(titleLabel.snp.bottom)
                maker.left.right.equalToSuperview()
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
