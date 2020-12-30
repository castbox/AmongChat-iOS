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
        
        private lazy var backBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.setImage(R.image.ac_profile_close(), for: .normal)
            btn.rx.tap.observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self]() in
                    guard let `self` = self else { return }
                    self.navigationController?.popViewController()
                }).disposed(by: bag)
            return btn
        }()
        
        private lazy var moreBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.setImage( R.image.ac_profile_more_icon(), for: .normal)
            btn.rx.tap.observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self]() in
                    self?.moreAction()
                }).disposed(by: bag)
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
        
        private lazy var options: [Option] = [.inviteFriends, .settings, .community, .blockUser, ]
        
        private var relationData: Entity.RelationData?
        
        override var screenName: Logger.Screen.Node.Start {
            return .profile
        }
        
        private var uid = 0
        private var isSelfProfile = true
        private var blocked = false
        var roomUser: Entity.RoomUser!
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
        Request.profilePage(uid: uid)
            .map({$0?.profile})
            .subscribe(onSuccess: { [weak self](data) in
                guard let data = data, let `self` = self else { return }
                self.userProfile = data
                self.headerView.configProfile(data)
            }, onError: {(error) in
                cdPrint("profilePage error : \(error.localizedDescription)")
            }).disposed(by: bag)
    }
    
    func setupData() {
        if roomUser != nil {
            self.headerView.setProfileData(self.roomUser)
        }
        loadData()
        fetchRealation()
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
    }
    
    func fetchRealation() {
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
                        self.fetchRealation()
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
                        self.fetchRealation()
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
        headerView.redCountLabel.isHidden = true
        let vc = Social.FollowerViewController(with: uid, isFollowing: false)
        navigationController?.pushViewController(vc)
    }
    
    func followingAction() {
        let vc = Social.FollowerViewController(with: uid, isFollowing: true)
        navigationController?.pushViewController(vc)
    }
    
    func moreAction() {
        var type:[AmongSheetController.ItemType]!
        if blocked {
            type = [.unblock, .report, .cancel]
        } else {
            type = [.block, .report, .cancel]
        }
        AmongSheetController.show(items: type, in: self, uiType: .profile) { [weak self](type) in
            switch type {
            case.report:
                self?.reportUser()
            case .block, .unblock:
                self?.showBlockAlter()
            default:
                break
            }
        }
    }
    
    func showBlockAlter() {
        var message = R.string.localizable.profileBlockMessage()
        var confirmString = R.string.localizable.alertBlock()
        if blocked {
            message = R.string.localizable.profileUnblockMessage()
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
                        self?.handleBlockResult(isBlocked: false)
                    }
                    removeBlock()
                }, onError: { (error) in
                    removeBlock()
                    
                }).disposed(by: bag)
        } else {
            Request.follow(uid: uid, type: "block")
                .subscribe(onSuccess: { [weak self](success) in
                    if success {
                        self?.handleBlockResult(isBlocked: true)
                    }
                    removeBlock()
                }, onError: { (error) in
                    removeBlock()
                }).disposed(by: bag)
        }
    }
    
    func handleBlockResult(isBlocked: Bool) {
        var blockedUsers = Defaults[\.blockedUsersV2Key]
        if isBlocked {
            blocked = true
            if !blockedUsers.contains(where: { $0.uid == uid}) {
                let newUser = Entity.RoomUser(uid: uid, name: userProfile?.name ?? "", pic: userProfile?.pictureUrl ?? "", nickname: userProfile?.nickname ?? "")
                blockedUsers.append(newUser)
                Defaults[\.blockedUsersV2Key] = blockedUsers
            }
            view.raft.autoShow(.text(R.string.localizable.profileBlockUserSuccess()))
        } else {
            blocked = false
            blockedUsers.removeElement(ifExists: { $0.uid == uid })
            Defaults[\.blockedUsersV2Key] = blockedUsers
            view.raft.autoShow(.text(R.string.localizable.profileUnblockUserSuccess()))
        }
        
    }
    
    func reportUser() {
        let user = Entity.RoomUser(uid: uid, name: userProfile?.name ?? "", pic: userProfile?.pictureUrl ?? "")
        self.showReportSheet(for: user)
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
