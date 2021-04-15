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
import PullToDismiss
import SDCAlertView

extension Social {
    
    class ProfileViewController: ViewController {
        
        enum Option {
            case tiktok
            case gameStats
            case groupsCreated
            case groupsJoined
            
            func image() -> UIImage? {
                switch self {
                case .tiktok:
                    return R.image.ac_social_tiktok()
                case .gameStats:
                    return R.image.ac_profile_game()
                case .groupsJoined, .groupsCreated:
                    return nil
                }
            }
            
            func text() -> String? {
                switch self {
                case .tiktok:
                    return R.string.localizable.profileShareTiktokTitle()
                case .gameStats:
                    return R.string.localizable.amongChatProfileAddAGame()
                case .groupsJoined, .groupsCreated:
                    return nil
                }
            }
        }
        var followedHandle:((Bool) -> Void)?
        
        var tableHeaderHeight: CGFloat {
            return 241 + Frame.Screen.width - 16
        }
        
        private lazy var followButton: UIButton = {
            let btn = UIButton()
            btn.backgroundColor = UIColor(hex6: 0xFFF000)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
            btn.layer.cornerRadius = 24
            btn.setTitleColor(.black, for: .normal)
            btn.setTitle(R.string.localizable.channelUserListFollow(), for: .normal)
            btn.rx.tap
                .subscribe(onNext: { [weak self]() in
                    self?.headerView.headerHandle?(.follow)
                }).disposed(by: bag)
            btn.isHidden = true
            return btn
        }()
        
        private lazy var bottomGradientView: GradientView = {
            let v = Social.ChooseGame.bottomGradientView()
            v.addSubviews(views: followButton)
            followButton.snp.makeConstraints { (maker) in
                maker.centerX.equalToSuperview()
                maker.bottom.equalTo(-33)
                maker.height.equalTo(48)
                maker.leading.equalTo(20)
            }
            v.isHidden = true
            return v
        }()
        
        private lazy var headerView: ProfileView = {
            let v = ProfileView(with: isSelfProfile.value, viewController: self)
            v.frame = CGRect(x: 0, y: 0, width: Frame.Screen.width, height: tableHeaderHeight)//298  413
            v.headerHandle = { [weak self] type in
                guard let `self` = self else { return }
                switch type {
                case .avater:
                    let vc = Social.CustomAvatarViewController()
                    vc.modalPresentationStyle = .overCurrentContext
                    self.present(vc, animated: false)
                case .edit:
                    
                    guard AmongChat.Login.canDoLoginEvent(style: .authNeeded(source: R.string.localizable.amongChatLoginAuthSourceProfile())) else {
                        return
                    }
                    
                    let vc = Social.EditProfileViewController()
                    self.navigationController?.pushViewController(vc)
                case .follow:
                    self.followAction()
                case .follower:
                    self.followerAction()
                case .following:
                    self.followingAction()
                case .more:
                    self.moreAction()
                case .customize:
                    let vc = Social.ProfileLookViewController()
                    self.navigationController?.pushViewController(vc)
                }
            }
            return v
        }()
        
        private lazy var table: UITableView = {
            let tb = UITableView(frame: .zero, style: .grouped)
            tb.dataSource = self
            tb.delegate = self
            tb.separatorStyle = .none
            tb.showsVerticalScrollIndicator = false
            tb.backgroundColor = UIColor.theme(.backgroundBlack)
            tb.register(cellWithClass: ProfileTableCell.self)
            tb.register(cellWithClass: GameCell.self)
            tb.register(nibWithCellClass: FansGroupSelfItemCell.self)
            tb.register(nibWithCellClass: FansGroupItemCell.self)
            tb.register(cellWithClass: JoinedGroupsCell.self)
            tb.neverAdjustContentInset()
            return tb
        }()
        
        private lazy var options = [Option]() {
            didSet {
                table.reloadData()
            }
        }
        
        private var relationData: Entity.RelationData?
        
        private var gameSkills = [Entity.UserGameSkill]() {
            didSet {
                table.reloadData()
            }
        }
        
        override var screenName: Logger.Screen.Node.Start {
            if isSelfProfile.value {
                return .profile
            }
            return .profile_other
        }
        
        private var uid = 0
        private let isSelfProfile = BehaviorRelay(value: true)
        private var blocked = false
        var roomUser: Entity.RoomUser!
        private var userProfile: Entity.UserProfile?
        private var pullToDismiss: PullToDismiss?
        
        private let createdGroupsRelay = BehaviorRelay<[Entity.Group]>(value: [])
        private let joinedGroupsRelay = BehaviorRelay<[Entity.Group]>(value: [])
        
        init(with uid: Int) {
            super.init(nibName: nil, bundle: nil)
            self.isNavigationBarHiddenWhenAppear = true
            self.uid = uid
            let selfUid = Settings.shared.amongChatUserProfile.value?.uid ?? 0
            cdPrint(" uid is \(uid)  self uid is \(selfUid)")
            self.isSelfProfile.accept(uid == selfUid)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
            setupData()
            setUpEvents()
        }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            fetchRealation()
        }
    }
}

private extension Social.ProfileViewController {
    func setupLayout() {
        statusBarStyle = .lightContent
        view.backgroundColor = UIColor.theme(.backgroundBlack)

        view.addSubviews(views: table, bottomGradientView)
        
        bottomGradientView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(bottomLayoutGuide.snp.top)
            maker.height.equalTo(134)
        }
        
        table.snp.makeConstraints { (maker) in
            maker.leading.trailing.top.equalToSuperview()
            maker.bottom.equalTo(bottomLayoutGuide.snp.top)
        }
        
        table.tableHeaderView = headerView
        table.reloadData()
        
        Settings.shared.loginResult.replay()
            .subscribe(onNext: { [weak self] (_) in
                
                guard let `self` = self,
                      self.isSelfProfile.value else {
                    return
                }
                
                var frame = self.headerView.frame
                
                if AmongChat.Login.isLogedin {
                    frame.size.height = self.tableHeaderHeight
                } else {
                    frame.size.height = self.tableHeaderHeight + 140
                }
                
                self.table.tableHeaderView?.frame = frame
            })
            .disposed(by: bag)

    }
    
    func setUpEvents() {
        
        rx.viewDidAppear.take(1)
            .subscribe(onNext: { [weak self](_) in
                guard let `self` = self else { return }
                if self.isSelfProfile.value {
                    Logger.Action.log(.profile_imp, category: nil)
                } else {
                    Logger.Action.log(.profile_other_imp, category: nil, "\(self.uid)")
                }
            })
            .disposed(by: bag)
        
        Observable.combineLatest(isSelfProfile, createdGroupsRelay, joinedGroupsRelay)
            .subscribe(onNext: { [weak self] isSelf, createdGroups, joinedGroups in
                
                if !isSelf {
                    self?.options = [.gameStats]
                    self?.bottomGradientView.isHidden = false
                } else {
                    if let v = Settings.shared.amongChatUserProfile.value?.isVerified, v {
                        self?.options = [.gameStats, .tiktok]
                    } else {
                        #if DEBUG
                        self?.options = [.gameStats, .tiktok]
                        #else
                        self?.options = [.tiktok]
                        #endif
                    }
                }
                
                if joinedGroups.count > 0 {
                    self?.options.insert(.groupsJoined, at: 0)
                }
                
                if createdGroups.count > 0 {
                    self?.options.insert(.groupsCreated, at: 0)
                }
                
            })
            .disposed(by: bag)
        
        NotificationCenter.default.rx.notification(FansGroup.GroupUpdateNotification.notificationName)
            .subscribe(onNext: { [weak self] (noti) in
                guard let `self` = self else { return }
                guard let (action, group) = FansGroup.GroupUpdateNotification.getDataFromNotification(noti) else { return }
                
                switch action {
                case .added:
                    ()
                
                case .removed:
                    var groups = self.createdGroupsRelay.value
                    groups.removeAll(where: { $0.gid == group.gid })
                    
                    if groups.count > 0 {
                        self.createdGroupsRelay.accept(groups)
                    } else {
                        self.fetchCreatedGroups()
                    }

                case .updated:
                    var groups = self.createdGroupsRelay.value
                    if let idx = groups.firstIndex(where: { $0.gid == group.gid }) {
                        groups[idx] = group
                        self.createdGroupsRelay.accept(groups)
                    }

                }
            })
            .disposed(by: bag)
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
    
    func loadGameSkills() {
        
        Request.gameSkills(uid: uid)
            .subscribe(onSuccess: { [weak self] (skills) in
                self?.gameSkills = skills
            }, onError: { (error) in
                
            })
            .disposed(by: bag)
        
    }
    
    func fetchCreatedGroups() {
        Request.groupListOfHost(uid, skip: 0, limit: 2)
            .subscribe(onSuccess: { [weak self] (groupList) in
                self?.createdGroupsRelay.accept(groupList)
            })
            .disposed(by: bag)
    }
    
    func fetchJoinedGroups() {
        Request.groupListOfUserJoined(uid, skip: 0, limit: 3)
            .subscribe(onSuccess: { [weak self] (groupList) in
                self?.joinedGroupsRelay.accept( groupList.sorted(by: \.status, with: >) )
            })
            .disposed(by: bag)
    }
    
    func setupData() {
        if isSelfProfile.value, navigationController?.viewControllers.count == 1 {
            pullToDismiss = PullToDismiss(scrollView: table)
            pullToDismiss?.delegate = self
            pullToDismiss?.dismissableHeightPercentage = 0.4
        }
        
        if roomUser != nil {
            self.headerView.setProfileData(self.roomUser)
        }
        loadData()
        if isSelfProfile.value {
            Settings.shared.amongChatUserProfile.replay()
                .subscribe(onNext: { [weak self] (profile) in
                    guard let profile = profile else { return }
                    if profile.isVerified == true {
                        Logger.Action.log(.profile_show_verify_icon)
                    }
                    self?.headerView.configProfile(profile)
                })
                .disposed(by: bag)
            
            Settings.shared.amongChatAvatarListShown.replay()
                .subscribe(onNext: { [weak self] (ts) in
                    if let _ = ts {
                        self?.headerView.changeIcon.redDotOff()
                    } else {
                        self?.headerView.changeIcon.redDotOn(rightInset: -2, diameter: 8)
                    }
                })
                .disposed(by: bag)
            
            Settings.shared.loginResult.replay()
                .observeOn(MainScheduler.asyncInstance)
                .subscribe(onNext: { [weak self] (result) in
                    guard let `self` = self,
                          let result = result else {
                        return
                    }
                    self.table.reloadData()
                    
                    let _ = Request.profile()
                        .subscribe(onSuccess: { (profile) in
                            guard let p = profile else {
                                return
                            }
                            Settings.shared.amongChatUserProfile.value = p
                        })
                    
                    self.uid = result.uid

                })
                .disposed(by: bag)
            
            Settings.shared.isProValue.replay()
                .observeOn(MainScheduler.asyncInstance)
                .subscribe(onNext: { [weak self] (_) in
                    self?.table.reloadData()
                })
                .disposed(by: bag)

        }
        loadGameSkills()
        fetchCreatedGroups()
        fetchJoinedGroups()
    }
    
    func fetchRealation() {
        Request.relationData(uid: uid)
            .subscribe(onSuccess: { [weak self](data) in
                guard let `self` = self, let data = data else { return }
                self.relationData = data
                self.blocked = data.isBlocked ?? false
                self.headerView.setViewData(data, isSelf: self.isSelfProfile.value)
                let follow = data.isFollowed ?? false
                self.setFollowButton(follow)
            }, onError: { (error) in
                cdPrint("relationData error :\(error.localizedDescription)")
            }).disposed(by: bag)
    }
    
    func followAction() {
        let removeBlock = view.raft.show(.loading)
        let isFollowed = relationData?.isFollowed ?? false
        if isFollowed {
                
            Logger.Action.log(.profile_other_clk, category: .unfollow, "\(uid)")
            Request.unFollow(uid: uid, type: "follow")
                .subscribe(onSuccess: { [weak self](success) in
                    guard let `self` = self else { return }
                    removeBlock()
                    if success {
                        self.fetchRealation()
                        self.relationData?.isFollowed = false
                        self.setFollowButton(false)
                        self.followedHandle?(false)
                    }
                }, onError: { (error) in
                    removeBlock()
                    cdPrint("unfollow error:\(error.localizedDescription)")
                }).disposed(by: bag)
        } else {
            Logger.Action.log(.profile_other_clk, category: .follow, "\(uid)")
            Request.follow(uid: uid, type: "follow")
                .subscribe(onSuccess: { [weak self](success) in
                    guard let `self` = self else { return }
                    removeBlock()
                    if success {
                        self.fetchRealation()
                        self.relationData?.isFollowed = true
                        self.setFollowButton(true)
                        self.followedHandle?(true)
                    }
                }, onError: { (error) in
                    removeBlock()
                    cdPrint("follow error:\(error.localizedDescription)")
                }).disposed(by: bag)
        }
    }
    
    func followerAction() {
        if !isSelfProfile.value {
            Logger.Action.log(.profile_other_clk, category: .followers, "\(uid)")
        }
        headerView.redCountLabel.isHidden = true
        let vc = Social.FollowerViewController(with: uid, isFollowing: false)
        navigationController?.pushViewController(vc)
    }
    
    func followingAction() {
        if !isSelfProfile.value {
            Logger.Action.log(.profile_other_clk, category: .following, "\(uid)")
        }
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
                self?.showReportSheet()
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
        showAmongAlert(title: message, message: nil,
                       cancelTitle: R.string.localizable.toastCancel(),
                       confirmTitle: confirmString, confirmAction: { [weak self] in
                        self?.blockUser()
                       })
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
                let newUser = Entity.RoomUser(uid: uid, name: userProfile?.name ?? "", pic: userProfile?.pictureUrl ?? "")
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
    
    private func toAddAGame() {
        Logger.Action.log(.profile_add_game_clk)
        let chooseGameVC = Social.ChooseGame.ViewController()
        chooseGameVC.gameUpdatedHandler = { [weak self] in
            self?.loadGameSkills()
        }
        navigationController?.pushViewController(chooseGameVC, animated: true)
    }
    
    private func toRemoveGameSkill(_ game: Entity.UserGameSkill, completionHandler: @escaping (() -> Void)) {
        Logger.Action.log(.profile_game_state_item_delete_clk, categoryValue: game.topicId)
        
        let messageAttr: NSAttributedString = NSAttributedString(string: R.string.localizable.amongChatGameStatsDeleteTip(),
                                                                 attributes: [
                                                                    NSAttributedString.Key.font : R.font.nunitoExtraBold(size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .heavy),
                                                                    .foregroundColor: UIColor.white
                                                                 ])
        
        let cancelAttr: NSAttributedString = NSAttributedString(string: R.string.localizable.toastCancel(),
                                                                attributes: [
                                                                    NSAttributedString.Key.font: R.font.nunitoExtraBold(size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .heavy),
                                                                    .foregroundColor: "#6C6C6C".color()
                                                                ])
        
        let confirmAttr = NSAttributedString(string: R.string.localizable.amongChatDelete(),
                                             attributes: [
                                                NSAttributedString.Key.font: R.font.nunitoExtraBold(size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .heavy),
                                                .foregroundColor: "#FB5858".color()
                                             ])
        
        let alertVC = AlertController(attributedTitle: nil, attributedMessage: messageAttr, preferredStyle: .alert)
        let visualStyle = AlertVisualStyle(alertStyle: .alert)
        visualStyle.backgroundColor = "#222222".color()
        visualStyle.actionViewSeparatorColor = UIColor.white.alpha(0.08)
        alertVC.visualStyle = visualStyle
        
        alertVC.addAction(AlertAction(attributedTitle: cancelAttr, style: .normal))
        
        alertVC.addAction(AlertAction(attributedTitle: confirmAttr, style: .normal, handler: { [weak self] _ in
            guard let `self` = self else { return }
            
            let hudRemoval: (() -> Void)? = self.view.raft.show(.loading, userInteractionEnabled: false)
            
            Request.removeGameSkill(game: game)
                .do(onDispose: {
                    hudRemoval?()
                })
                .subscribe(onSuccess: { (_) in
                    completionHandler()
                }, onError: { (error) in
                    
                })
                .disposed(by: self.bag)
        })
        )
        
        alertVC.view.backgroundColor = UIColor.black.alpha(0.6)
        alertVC.present()
        
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
    
    private func gotoEditGroup(_ groupId: String) {
        
        let hudRemoval = view.raft.show(.loading)
        
        FansGroup.GroupEditViewController.groupEditVC(groupId)
            .do(onDispose: {
                hudRemoval()
            })
            .subscribe(onSuccess: { [weak self] (vc) in
                self?.navigationController?.pushViewController(vc, animated: true)
            }, onError: { [weak self] (error) in
                self?.view.raft.autoShow(.text(error.msgOfError ?? R.string.localizable.amongChatUnknownError()))
            })
            .disposed(by: bag)
        
    }
}
// MARK: - UITableView
extension Social.ProfileViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return options.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        guard let op = options.safe(section) else {
            return 0
        }
        
        switch op {
        case .gameStats:
            if isSelfProfile.value {
                return max(1, gameSkills.count)
            } else {
                return gameSkills.count
            }
            
        case .tiktok:
            return 1
            
        case .groupsCreated:
            return createdGroupsRelay.value.count
            
        case .groupsJoined:
            return 1
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let op = options[indexPath.section]
        
        switch op {
        case .gameStats:
            
            if let game = gameSkills.safe(indexPath.row) {
                let cell = tableView.dequeueReusableCell(withClass: GameCell.self, for: indexPath)
                cell.bind(game)
                cell.deleteHandler = { [weak self] in
                    self?.toRemoveGameSkill(game, completionHandler: {
                        self?.loadGameSkills()
                    })
                }
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withClass: ProfileTableCell.self, for: indexPath)
                cell.configCell(with: op)
                return cell
            }
            
        case .tiktok:
            let cell = tableView.dequeueReusableCell(withClass: ProfileTableCell.self, for: indexPath)
            cell.configCell(with: op)
            return cell
            
        case .groupsCreated:
            
            let group = createdGroupsRelay.value[indexPath.row]
            
            if isSelfProfile.value {
                let cell = tableView.dequeueReusableCell(withClass: FansGroupSelfItemCell.self)
                cell.tagView.isHidden = true
                cell.bindData(group)  { [weak self] action in
                    guard let `self` = self else { return }
                    switch action {
                    case .edit:
                        self.gotoEditGroup(group.gid)
                        Logger.Action.log(.profile_group_clk, categoryValue: "edit")
                    case .start:
                        self.enter(group: group, logSource: .init(.profile), apiSource: nil)
                        Logger.Action.log(.profile_group_clk, categoryValue: "start")
                    }
                }
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withClass: FansGroupItemCell.self)
                cell.bindData(group)
                return cell
            }
            
        case .groupsJoined:
            let cell = tableView.dequeueReusableCell(withClass: JoinedGroupsCell.self)
            cell.bind(joinedGroupsRelay.value) { [weak self] (group) in
                
                if group.status == 1 {
                    self?.enter(group: group, logSource: .init(.profile), apiSource: nil)
                } else {
                    let vc = FansGroup.GroupInfoViewController(groupId: group.gid)
                    self?.navigationController?.pushViewController(vc, animated: true)
                }
                
            }
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let op = options.safe(indexPath.section) {
            switch op {
            case .gameStats:
                if let game = gameSkills.safe(indexPath.row) {
                    // TODO: - 跳转H5
                    WebViewController.pushFrom(self, url: game.h5.url, contentType: .gameSkill(game))
                    Logger.Action.log(isSelfProfile.value ? .profile_game_state_item_clk : .profile_other_game_state_item_clk, categoryValue: game.topicId)
                    
                } else {
                    toAddAGame()
                }
                
            case .tiktok:
                Logger.Action.log(.profile_tiktok_amongchat_tag_clk)
                guard let url = URL(string: "https://www.tiktok.com/tag/amongchat") else {
                    return
                }
                UIApplication.shared.open(url, options: [:]) { _ in
                    
                }
                
            case .groupsJoined:
                ()
            case .groupsCreated:
                Logger.Action.log( isSelfProfile.value ? .profile_group_clk : .profile_other_group_clk, categoryValue: "group")
                guard let group = createdGroupsRelay.value.safe(indexPath.row) else {
                    return
                }
                if group.status == 1 {
                    enter(group: group, logSource: nil, apiSource: nil)
                } else {
                    
                    let vc = FansGroup.GroupInfoViewController(groupId: group.gid)
                    navigationController?.pushViewController(vc, animated: true)
                }

            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        guard let op = options.safe(indexPath.section) else {
            return .leastNormalMagnitude
        }
        
        switch op {
        case .gameStats:
            
            if let _ = gameSkills.safe(indexPath.row) {
                return 44 + (Frame.Screen.width - 20 * 2) * 180.0 / 335.0 + 12 * 2
            } else {
                return 92
            }
            
        case .tiktok:
            return 92
            
        case .groupsCreated:
            return 149
            
        case .groupsJoined:
            return JoinedGroupsCell.groupViewWidth + 24
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 35
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        guard let op = options.safe(section) else {
            return nil
        }
        
        let v = UIView()
        let l = UILabel()
        l.textColor = UIColor(hexString: "#FFFFFF")
        l.font = R.font.nunitoExtraBold(size: 20)
        l.adjustsFontSizeToFitWidth = true
        
        v.addSubview(l)
        l.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.leading.equalTo(20)
            maker.height.equalTo(27)
        }
        switch op {
        case .gameStats:
            
            if isSelfProfile.value {
                
                l.text = R.string.localizable.amongChatProfileMyGameStats()

                if gameSkills.count > 0 {

                    let btn = UIButton(type: .custom)
                    btn.setImage(R.image.ac_profile_add_game_stats(), for: .normal)
                    btn.setTitle(R.string.localizable.amongChatProfileAddAGame(), for: .normal)
                    btn.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
                    btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 4)
                    btn.titleEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4)
                    btn.rx.controlEvent(.primaryActionTriggered)
                        .subscribe(onNext: { [weak self] (_) in
                            self?.toAddAGame()
                        })
                        .disposed(by: bag)
                    
                    v.addSubview(btn)
                    
                    btn.snp.makeConstraints { (maker) in
                        maker.centerY.equalToSuperview()
                        maker.trailing.equalTo(-20)
                        maker.height.equalTo(27)
                    }
                    l.snp.makeConstraints { (maker) in
                        maker.trailing.lessThanOrEqualTo(btn.snp.leading).offset(-20)
                    }
                    
                } else {
                    l.snp.makeConstraints { (maker) in
                        maker.trailing.lessThanOrEqualTo(-20)
                    }
                }
                
            } else {
                
                if gameSkills.count > 0 {
                    l.text = R.string.localizable.amongChatProfileGameStats()
                    l.snp.makeConstraints { (maker) in
                        maker.trailing.lessThanOrEqualTo(-20)
                    }
                }
                
            }
            
        case .tiktok:
            l.text = R.string.localizable.amongChatProfileMakeTiktokVideo()
            l.snp.makeConstraints { (maker) in
                maker.trailing.lessThanOrEqualTo(-20)
            }
            
        case .groupsCreated:
            
            if isSelfProfile.value {
                l.text = R.string.localizable.amongChatGroupGroupsOwnedByMe()
            } else {
                l.text = R.string.localizable.amongChatGroupGroupsCreated()
            }
            
            let btn = SmallSizeButton(type: .custom)
            btn.setTitle(R.string.localizable.socialSeeAll(), for: .normal)
            btn.setTitleColor(UIColor(hex6: 0x898989), for: .normal)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
            btn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] (_) in
                    Logger.Action.log(.profile_group_clk, categoryValue: "see_all")
                    guard let `self` = self else { return }
                    let listVC = FansGroup.GroupListViewController(source: .createdGroups(self.uid))
                    self.navigationController?.pushViewController(listVC, animated: true)
                })
                .disposed(by: bag)
            
            v.addSubview(btn)
            
            btn.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.trailing.equalTo(-20)
            }
            
            l.snp.makeConstraints { (maker) in
                maker.trailing.lessThanOrEqualTo(btn.snp.leading).offset(-20)
            }
            
        case .groupsJoined:
            l.text = R.string.localizable.amongChatGroupGroupsJoined()

            let btn = SmallSizeButton(type: .custom)
            btn.setTitle(R.string.localizable.socialSeeAll(), for: .normal)
            btn.setTitleColor(UIColor(hex6: 0x898989), for: .normal)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
            btn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] (_) in
                    Logger.Action.log(.profile_group_clk, categoryValue: "see_all")
                    guard let `self` = self else { return }
                    let listVC = FansGroup.GroupListViewController(source: .joinedGroups(self.uid))
                    self.navigationController?.pushViewController(listVC, animated: true)
                })
                .disposed(by: bag)
            
            v.addSubview(btn)
            
            btn.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.trailing.equalTo(-20)
            }
            l.snp.makeConstraints { (maker) in
                maker.trailing.lessThanOrEqualTo(btn.snp.leading).offset(-20)
            }

        }
        
        return v
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard let op = options.safe(section) else {
            return .leastNormalMagnitude
        }
        
        switch op {
        case .gameStats:
            if isSelfProfile.value {
                if gameSkills.count > 0 {
                    return 40
                } else {
                    return 28
                }
            } else {
                return 134
            }
            
        case .tiktok:
            
            if isSelfProfile.value {
                return 46
            } else {
                return 134
            }
            
        case .groupsJoined, .groupsCreated:
            return 28
        }
        
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }
    
}
