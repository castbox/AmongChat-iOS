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
            case profile
            case tiktok
            case gameStats
            case groupsCreated
            case groupsJoined
            case live
            
            func image() -> UIImage? {
                switch self {
                case .tiktok:
                    return R.image.ac_social_tiktok()
                case .gameStats:
                    return R.image.ac_profile_game()
                case .groupsJoined, .groupsCreated, .profile, .live:
                    return nil
                }
            }
            
            func text() -> String? {
                switch self {
                case .tiktok:
                    return R.string.localizable.profileShareTiktokTitle()
                case .gameStats:
                    return R.string.localizable.amongChatProfileAddAGame()
                case .groupsJoined, .groupsCreated, .profile, .live:
                    return nil
                }
            }
        }
        var followedHandle:((Bool) -> Void)?
        
        private lazy var navView: NavigationBar = {
            let n = NavigationBar()
            let btn = n.leftBtn
            if isSelfProfile.value, navigationController?.viewControllers.count == 1 {
                btn.setImage(R.image.ac_profile_close_down(), for: .normal)
            } else {
                btn.setImage(R.image.ac_profile_close(), for: .normal)
            }
            btn.rx.tap.observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self]() in
                    guard let `self` = self else { return }
                    if self.navigationController?.viewControllers.count == 1 {
                        self.dismiss(animated: true, completion: nil)
                    } else {
                        self.navigationController?.popViewController()
                    }
                }).disposed(by: bag)
            
            if isSelfProfile.value {
                n.addSubview(settingsBtn)
                settingsBtn.snp.makeConstraints { (maker) in
                    maker.centerY.equalToSuperview()
                    maker.trailing.equalToSuperview().inset(Frame.horizontalBleedWidth)
                }
                
                n.addSubview(proBtn)
                proBtn.snp.makeConstraints { (maker) in
                    maker.top.bottom.equalToSuperview()
                    maker.trailing.equalTo(settingsBtn.snp.leading).offset(-20)
                }

            } else {
                n.addSubview(moreBtn)
                moreBtn.snp.makeConstraints { (make) in
                    make.trailing.equalToSuperview().inset(Frame.horizontalBleedWidth)
                    make.centerY.equalToSuperview()
                }
            }
            return n
        }()
        
        private lazy var settingsBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.setImage(R.image.ac_profile_setting(), for: .normal)
            btn.rx.tap.observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self]() in
                    let vc = SettingViewController()
                    self?.navigationController?.pushViewController(vc)
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
        
        private lazy var proBtn: UIView = {
            let btn: UIView = {
                let v = UIView()
                
                let leftIcon: UIImageView = {
                    let i = UIImageView(image: R.image.ac_pro_icon_27())
                    return i
                }()
                
                let titleLabel: UILabel = {
                    let l = UILabel()
                    l.font = R.font.nunitoExtraBold(size: 16)
                    l.textColor = UIColor(hex6: 0xFFEC96)
                    l.text = R.string.localizable.profileUnlockPro()
                    return l
                }()
                
                let rightIcon: UIImageView = {
                    let i = UIImageView(image: R.image.ac_profile_pro_next())
                    return i
                }()
                v.addSubviews(views: leftIcon)
                
                Settings.shared.isProValue.replay()
                    .observeOn(MainScheduler.asyncInstance)
                    .subscribe(onNext: { (isPro) in
                        
                        if isPro {
                            titleLabel.removeFromSuperview()
                            rightIcon.removeFromSuperview()
                            leftIcon.snp.remakeConstraints { (maker) in
                                maker.leading.trailing.centerY.equalToSuperview()
                            }
                        } else {
                            v.addSubviews(views: titleLabel, rightIcon)
                            leftIcon.snp.remakeConstraints { (maker) in
                                maker.leading.centerY.equalToSuperview()
                            }
                            titleLabel.snp.remakeConstraints { (maker) in
                                maker.leading.equalTo(leftIcon.snp.trailing).offset(6)
                                maker.centerY.equalToSuperview()
                            }
                            rightIcon.snp.remakeConstraints { (maker) in
                                maker.leading.equalTo(titleLabel.snp.trailing).offset(2)
                                maker.centerY.trailing.equalToSuperview()
                            }
                        }
                        
                    })
                    .disposed(by: bag)
                return v
            }()
            
            let tap = UITapGestureRecognizer()
            btn.addGestureRecognizer(tap)
            tap.rx.event
                .subscribe(onNext: { [weak self] (_) in
                    self?.presentPremiumView(source: .setting)
                    Logger.UserAction.log(.update_pro, "settings")
                }).disposed(by: bag)
            return btn
        }()
        
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
        
        private lazy var chatButton: UIButton = {
            let btn = UIButton()
            btn.layer.borderColor = UIColor(hex6: 0xFFF000).cgColor
            btn.layer.borderWidth = 2
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
            btn.layer.cornerRadius = 24
            btn.setTitleColor(UIColor(hex6: 0xFFF000), for: .normal)
            btn.setTitle(R.string.localizable.amongChatProfileChat(), for: .normal)
            btn.rx.tap
                .subscribe(onNext: { [weak self] () in
                    self?.startChatIfCould()
                    Logger.Action.log(.profile_other_chat_clk, category: nil, self?.userProfile.value?.uid.string)
                }).disposed(by: bag)
            btn.isHidden = true
            return btn
        }()
        
        private lazy var bottomGradientView: GradientView = {
            let v = GradientView()
            let l = v.layer
            l.colors = [UIColor(hex6: 0x121212, alpha: 0).cgColor, UIColor(hex6: 0x121212, alpha: 0.18).cgColor, UIColor(hex6: 0x121212, alpha: 0.57).cgColor, UIColor(hex6: 0x121212).cgColor]
            l.startPoint = CGPoint(x: 0.5, y: 0)
            l.endPoint = CGPoint(x: 0.5, y: 0.4)
            l.locations = [0, 0.3, 0.6, 1]
            
            Observable.combineLatest(relationData.filterNil(),
                                     userProfile.filterNil())
                .take(1)
                .observeOn(MainScheduler.asyncInstance)
                .subscribe(onNext: { [weak self] relation, p in
                    
                    guard let `self` = self else { return }
                    
                    if AmongChat.Login.isLogedin,
                       !(p.isAnonymous ?? true) {
                        v.addSubviews(views: self.chatButton, self.followButton)
                        self.chatButton.snp.makeConstraints { (maker) in
                            maker.leading.equalTo(20)
                            maker.bottom.equalTo(-33)
                            maker.height.equalTo(48)
                        }
                        self.followButton.snp.makeConstraints { (maker) in
                            maker.bottom.equalTo(-33)
                            maker.height.equalTo(48)
                            maker.leading.equalTo(self.chatButton.snp.trailing).offset(20)
                            maker.trailing.equalTo(-20)
                            maker.width.equalTo(self.chatButton.snp.width)
                        }
                        self.chatButton.isHidden = false
                    } else {
                        v.addSubviews(views: self.followButton)
                        self.followButton.snp.makeConstraints { (maker) in
                            maker.bottom.equalTo(-33)
                            maker.height.equalTo(48)
                            maker.leading.trailing.equalToSuperview().inset(20)
                        }
                    }
                    
                    let follow = relation.isFollowed ?? false
                    self.setFollowButton(follow)
                })
                .disposed(by: bag)
            
            v.isHidden = true
            return v
        }()
        
        private lazy var headerView: ProfileView = {
            let v = ProfileView(with: isSelfProfile.value, viewController: self)
            v.frame = CGRect(x: 0, y: 0, width: Frame.Screen.width, height: v.viewHeight)
            v.headerHandle = { [weak self] type in
                guard let `self` = self else { return }
                switch type {
                case .avater:
                    let vc = Social.CustomAvatarViewController()
                    vc.modalPresentationStyle = .overCurrentContext
                    self.present(vc, animated: false)
                case .edit:
                    
                    guard AmongChat.Login.canDoLoginEvent(style: .authNeeded(source: .editProfile)) else {
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
                case .expandDescription:
                    self.table.reloadData()
                }
            }
            return v
        }()
        
        private typealias FansGroupSelfItemCell = FansGroup.Views.OwnedGroupCell
        private typealias FansGroupItemCell = FansGroup.Views.JoinedGroupCell
        
        private lazy var table: UICollectionView = {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .vertical
            var hInset: CGFloat = 20
            adaptToIPad {
                hInset = 40
            }
            layout.sectionInset = UIEdgeInsets(top: 16, left: 0, bottom: 44, right: 0)
            layout.minimumLineSpacing = 20
            let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
            v.contentInset = UIEdgeInsets(top: 0, left: hInset, bottom: isSelfProfile.value ? 0 : 48, right: hInset)
            v.register(FansGroupItemCell.self, forCellWithReuseIdentifier: NSStringFromClass(FansGroupItemCell.self))
            v.register(FansGroupSelfItemCell.self, forCellWithReuseIdentifier: NSStringFromClass(FansGroupSelfItemCell.self))
            v.register(cellWithClass: ProfileTableCell.self)
            v.register(cellWithClass: GameCell.self)
            v.register(cellWithClass: JoinedGroupCell.self)
            v.register(LiveCell.self, forCellWithReuseIdentifier: NSStringFromClass(LiveCell.self))
            v.register(cellWithClass: UICollectionViewCell.self)
            v.register(supplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withClass: SectionHeader.self)
            v.showsVerticalScrollIndicator = false
            v.showsHorizontalScrollIndicator = false
            v.dataSource = self
            v.delegate = self
            v.backgroundColor = .clear
            v.alwaysBounceVertical = true
            if #available(iOS 11.0, *) {
                v.contentInsetAdjustmentBehavior = .never
            } else {
                automaticallyAdjustsScrollViewInsets = false
            }
            return v
        }()
        
        private lazy var options = [Option]() {
            didSet {
                table.reloadData()
            }
        }
        
        private let relationData = BehaviorRelay<Entity.RelationData?>(value: nil)
        
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
        private let userProfile = BehaviorRelay<Entity.UserProfile?>(value: nil)
        private var pullToDismiss: PullToDismiss?
        
        private let createdGroupsRelay = BehaviorRelay<[Entity.Group]>(value: [])
        private let joinedGroupsRelay = BehaviorRelay<[Entity.Group]>(value: [])
        private let liveRoomRelay = BehaviorRelay<[Any]>(value: [])
        
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
        
        override func showReportSheet() {
            Report.ViewController.showReport(on: self, uid: uid.string, type: .user, roomId: "", operate: nil) { [weak self] in
                self?.view.raft.autoShow(.text(R.string.localizable.reportSuccess()))
            }
        }
    }
}

private extension Social.ProfileViewController {
    func setupLayout() {
        view.addSubviews(views: table, navView, bottomGradientView)
        
        navView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(Frame.Height.safeAeraTopHeight)
        }
        
        bottomGradientView.snp.makeConstraints { (maker) in
            maker.leading.trailing.bottom.equalToSuperview()
            maker.height.equalTo(134)
        }
        
        table.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        
        Settings.shared.loginResult.replay()
            .subscribe(onNext: { [weak self] (_) in                
                self?.table.reloadData()
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
        
        Observable.combineLatest(isSelfProfile, createdGroupsRelay, joinedGroupsRelay, liveRoomRelay)
            .subscribe(onNext: { [weak self] isSelf, createdGroups, joinedGroups, liveRooms in
                
                if !isSelf {
                    self?.options = [.gameStats]
                    self?.bottomGradientView.isHidden = false
                } else {
                    self?.options = [.gameStats, .tiktok]
                }
                
                if joinedGroups.count > 0 {
                    self?.options.insert(.groupsJoined, at: 0)
                }
                
                if createdGroups.count > 0 {
                    self?.options.insert(.groupsCreated, at: 0)
                }
                
                if liveRooms.count > 0 {
                    self?.options.insert(.live, at: 0)
                }
                
                self?.options.insert(.profile, at: 0)
            })
            .disposed(by: bag)
        
        FansGroup.GroupUpdateNotification.groupUpdated
            .subscribe(onNext: { [weak self] action, group in
                guard let `self` = self else { return }
                
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
        
        table.rx.contentOffset
            .subscribe(onNext: { [weak self] (point) in
                
                guard let `self` = self else { return }
                
                let distance = point.y
                
                self.headerView.enlargeTopGbHeight(extraHeight: -distance)
                
                self.navView.backgroundView.alpha = distance / 49
                self.navView.backgroundView.isHidden = distance <= 0
            })
            .disposed(by: bag)

    }
    
    func loadData() {
        Request.profilePage(uid: uid)
            .map({$0?.profile})
            .subscribe(onSuccess: { [weak self](data) in
                guard let data = data, let `self` = self else { return }
                self.userProfile.accept(data)
                self.headerView.configProfile(data)
            }, onError: {(error) in
                cdPrint("profilePage error : \(error.localizedDescription)")
            }).disposed(by: bag)
        
        if !isSelfProfile.value {
            Request.userStatus(uid)
                .subscribe(onSuccess: { [weak self] (status) in
                    
                    guard let status = status else { return }
                    
                    self?.headerView.onlineStatusView.isHidden = !(status.isOnline == true && status.room == nil && status.group == nil)
                    
                    var liveRooms = [Any]()
                    
                    if let room = status.room {
                        liveRooms.append(room)
                    }
                    
                    if let group = status.group {
                        liveRooms.append(group)
                    }
                    
                    self?.liveRoomRelay.accept(liveRooms)
                    
                }, onError: { (error) in
                    
                })
                .disposed(by: bag)

        }
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
                        self?.headerView.changeIcon.badgeOff()
                    } else {
                        self?.headerView.changeIcon.badgeOn(hAlignment: .tailByTail(-2), diameter: 8, borderWidth: 0, borderColor: nil)
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
                self.relationData.accept(data)
                self.blocked = data.isBlocked ?? false
                self.headerView.setViewData(data, isSelf: self.isSelfProfile.value)
            }, onError: { (error) in
                cdPrint("relationData error :\(error.localizedDescription)")
            }).disposed(by: bag)
    }
    
    func followAction() {
        let removeBlock = view.raft.show(.loading)
        let isFollowed = relationData.value?.isFollowed ?? false
        if isFollowed {
            
            Logger.Action.log(.profile_other_clk, category: .unfollow, "\(uid)")
            Request.unFollow(uid: uid, type: "follow")
                .subscribe(onSuccess: { [weak self](success) in
                    guard let `self` = self else { return }
                    removeBlock()
                    if success {
                        self.fetchRealation()
                        var r = self.relationData.value
                        r?.isFollowed = false
                        self.relationData.accept(r)
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
                        var r = self.relationData.value
                        r?.isFollowed = true
                        self.relationData.accept(r)
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
        headerView.redDotView.isHidden = true
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
                let newUser = Entity.RoomUser(uid: uid, name: userProfile.value?.name ?? "", pic: userProfile.value?.pictureUrl ?? "")
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
    
    func startChatIfCould() {
        //判断为非匿名用户
        guard let profile = userProfile.value?.dmProfile else {
            return
        }
        
        let hudRemoval = view.raft.show(.loading)
        //query
        DMManager.shared.queryConversation(fromUid: profile.uid.string)
            .flatMap { conversation -> Single<Entity.DMConversation?> in
                guard conversation == nil else {
                    return .just(conversation)
                }
                return DMManager.shared.add(message: Entity.DMMessage.emptyMessage(for: profile))
                    .flatMap { DMManager.shared.queryConversation(fromUid: profile.uid.string) }
            }
            .subscribe(onSuccess: { [weak self] conversation in
                hudRemoval()
                guard let conversation = conversation else {
                    return
                }
                let vc = ConversationViewController(conversation)
                self?.navigationController?.pushViewController(vc)
            }, onError: { error in
                hudRemoval()
            })
            .disposed(by: bag)
    }
}
// MARK: - UICollectionViewDataSource
extension Social.ProfileViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return options.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
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
            return joinedGroupsRelay.value.count
        case .profile:
            return 1
        case .live:
            return liveRoomRelay.value.count
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let op = options[indexPath.section]
        
        switch op {
        case .gameStats:
            
            if let game = gameSkills.safe(indexPath.row) {
                let cell = collectionView.dequeueReusableCell(withClass: GameCell.self, for: indexPath)
                cell.bind(game)
                cell.deleteButton.isHidden = !isSelfProfile.value
                cell.deleteHandler = { [weak self] in
                    self?.toRemoveGameSkill(game, completionHandler: {
                        self?.loadGameSkills()
                    })
                }
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withClass: ProfileTableCell.self, for: indexPath)
                cell.configCell(with: op)
                return cell
            }
            
        case .tiktok:
            let cell = collectionView.dequeueReusableCell(withClass: ProfileTableCell.self, for: indexPath)
            cell.configCell(with: op)
            return cell
            
        case .groupsCreated:
            
            let group = createdGroupsRelay.value[indexPath.row]
            
            if isSelfProfile.value {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(FansGroupSelfItemCell.self), for: indexPath)
                if let cell = cell as? FansGroupSelfItemCell {
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
                }
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(FansGroupItemCell.self), for: indexPath)
                if let cell = cell as? FansGroupItemCell {
                    cell.bindData(group)
                }
                return cell
            }
            
        case .groupsJoined:
            let cell = collectionView.dequeueReusableCell(withClass: JoinedGroupCell.self, for: indexPath)
            cell.bindData(joinedGroupsRelay.value[indexPath.item])
            return cell
        case .profile:
            let cell = collectionView.dequeueReusableCell(withClass: UICollectionViewCell.self, for: indexPath)
            headerView.removeFromSuperview()
            cell.contentView.addSubview(headerView)
            headerView.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
            return cell
            
        case .live:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(LiveCell.self), for: indexPath)
            if let cell = cell as? LiveCell {
                
                let liveRoom = liveRoomRelay.value.first
                
                if let room = liveRoom as? Entity.UserStatus.Room {
                    
                    cell.coverIV.setImage(with: room.coverUrl)
                    cell.label.text = room.topicName
                    cell.label.text = R.string.localizable.profileUserInChannel(room.topicName)
                    
                    cell.joinHandler = { [weak self] in
                        self?.enterRoom(roomId: room.roomId, topicId: room.topicId)
                    }
                } else if let group = liveRoom as? Entity.UserStatus.Group {
                    cell.coverIV.setImage(with: group.cover)
                    cell.label.text = R.string.localizable.profileUserInGroup(group.name)
                    cell.joinHandler = { [weak self] in
                        self?.enter(group: group.gid)
                    }
                }
                
            }
            return cell
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
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
                let group = joinedGroupsRelay.value[indexPath.item]
                if group.status == 1 {
                    enter(group: group, logSource: .init(.profile), apiSource: nil)
                } else {
                    let vc = FansGroup.GroupInfoViewController(groupId: group.gid)
                    navigationController?.pushViewController(vc, animated: true)
                }
                
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
                
            case .profile, .live:
                ()
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            
            let op = options[indexPath.section]
            
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withClass: SectionHeader.self, for: indexPath)
            
            switch op {
            case .gameStats:
                
                if isSelfProfile.value {
                    
                    header.titleLabel.text = R.string.localizable.amongChatProfileMyGameStats()
                    
                    header.actionButton.setImage(R.image.ac_profile_add_game_stats(), for: .normal)
                    header.actionButton.setTitle(R.string.localizable.amongChatProfileAddAGame(), for: .normal)
                    header.actionButton.setTitleColor(UIColor(hex6: 0xFFFFFF), for: .normal)
                    header.actionButton.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
                    header.actionButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 4)
                    header.actionButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4)
                    header.actionHandler = { [weak self] () in
                        self?.toAddAGame()
                    }
                    
                    header.actionButton.isHidden = !(gameSkills.count > 0)
                    
                } else {
                    
                    header.actionButton.isHidden = true
                    
                    if gameSkills.count > 0 {
                        header.titleLabel.text = R.string.localizable.amongChatProfileGameStats()
                    }
                    
                }
                
            case .tiktok:
                header.titleLabel.text = R.string.localizable.amongChatProfileMakeTiktokVideo()
                header.actionButton.isHidden = true
                
            case .groupsCreated:
                header.actionButton.isHidden = false
                
                if isSelfProfile.value {
                    header.titleLabel.text = R.string.localizable.amongChatGroupGroupsOwnedByMe()
                } else {
                    header.titleLabel.text = R.string.localizable.amongChatGroupGroupsCreated()
                }
                
                header.actionButton.setTitle(R.string.localizable.socialSeeAll(), for: .normal)
                header.actionButton.setTitleColor(UIColor(hex6: 0x898989), for: .normal)
                header.actionButton.setImage(nil, for: .normal)
                header.actionButton.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
                header.actionHandler = { [weak self] () in
                    Logger.Action.log(.profile_group_clk, categoryValue: "see_all")
                    guard let `self` = self else { return }
                    let listVC = FansGroup.GroupListViewController(source: .createdGroups(self.uid))
                    self.navigationController?.pushViewController(listVC, animated: true)
                }
                
            case .groupsJoined:
                header.actionButton.isHidden = false
                header.titleLabel.text = R.string.localizable.amongChatGroupGroupsJoined()
                
                header.actionButton.setTitle(R.string.localizable.socialSeeAll(), for: .normal)
                header.actionButton.setTitleColor(UIColor(hex6: 0x898989), for: .normal)
                header.actionButton.setImage(nil, for: .normal)
                header.actionButton.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
                header.actionHandler = { [weak self] () in
                    Logger.Action.log(.profile_group_clk, categoryValue: "see_all")
                    guard let `self` = self else { return }
                    let listVC = FansGroup.GroupListViewController(source: .joinedGroups(self.uid))
                    self.navigationController?.pushViewController(listVC, animated: true)
                }
                
            case .profile, .live:
                ()
                
            }
            
            return header
            
        default:
            return UICollectionReusableView()
        }
        
    }
    
}

extension Social.ProfileViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        guard let op = options.safe(indexPath.section) else {
            return .zero
        }
        
        let padding: CGFloat = collectionView.contentInset.left + collectionView.contentInset.right
        
        switch op {
        case .live:
            
            let cellWidth = UIScreen.main.bounds.width - padding
            let cellHeight = CGFloat(56)
            
            return CGSize(width: cellWidth, height: cellHeight)
            
        case .gameStats:
            
            if let _ = gameSkills.safe(indexPath.row) {
                
                let interitemSpacing: CGFloat = 20
                var hwRatio: CGFloat = 180.0 / 335.0
                var columns: Int = 1
                adaptToIPad {
                    columns = 2
                    hwRatio = 227.0 / 367.0
                }
                let cellWidth = ((UIScreen.main.bounds.width - padding - interitemSpacing * CGFloat(columns - 1)) / CGFloat(columns)).rounded(.towardZero)
                let cellHeight = ceil(cellWidth * hwRatio)
                
                return CGSize(width: cellWidth, height: cellHeight)
                
            } else {
                return CGSize(width: Frame.Screen.width - padding, height: 68)
            }
            
        case .tiktok:
            return CGSize(width: Frame.Screen.width - padding, height: 68)
            
        case .groupsCreated:
            
            var columns: Int = 1
            adaptToIPad {
                columns = 2
            }
            let interitemSpacing: CGFloat = 20
            let hwRatio: CGFloat = 129.0 / 335.0
            
            let cellWidth = ((UIScreen.main.bounds.width - padding - interitemSpacing * CGFloat(columns - 1)) / CGFloat(columns)).rounded(.towardZero)
            let cellHeight = ceil(cellWidth * hwRatio)
            
            return CGSize(width: cellWidth, height: cellHeight)
            
        case .groupsJoined:
            
            var columns: Int = 3
            adaptToIPad {
                columns = 6
            }
            let interitemSpacing: CGFloat = 16
            let hwRatio: CGFloat = 1
            
            let cellWidth = ((UIScreen.main.bounds.width - padding - interitemSpacing * CGFloat(columns - 1)) / CGFloat(columns)).rounded(.towardZero)
            let cellHeight = ceil(cellWidth * hwRatio)
            
            return CGSize(width: cellWidth, height: cellHeight)
            
        case .profile:
            
            return CGSize(width: Frame.Screen.width, height: headerView.viewHeight)
            
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        let op = options[section]
        
        switch op {
        case .profile:
            return UIEdgeInsets(top: 0, left: 0, bottom: 56, right: 0)
        case .live:
            return UIEdgeInsets(top: 13, left: 0, bottom: 56, right: 0)
        default:
            return (collectionViewLayout as? UICollectionViewFlowLayout)?.sectionInset ?? .zero
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        
        let op = options[section]
        
        switch op {
        case .groupsJoined:
            return 16
        default:
            return 20
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let op = options[section]
        
        switch op {
        case .profile, .live:
            return .zero
        default:
            return CGSize(width: Frame.Screen.width, height: 27)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return .zero
    }
    
}
