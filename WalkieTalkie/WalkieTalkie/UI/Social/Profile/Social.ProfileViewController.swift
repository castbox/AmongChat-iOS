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
import JXPagingView

extension Social {
    
    class ProfileViewController: ViewController {
        
        var followedHandle:((Bool) -> Void)?
        
        private lazy var navView: NavigationBar = {
            let n = NavigationBar()
            let btn = n.leftBtn
            if isSelfProfile.value, navigationController?.viewControllers.count == 1 {
                btn.setImage(R.image.ac_profile_close_down(), for: .normal)
            } else {
                btn.setImage(R.image.ac_back(), for: .normal)
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
        
        private lazy var segmentedButton: FansGroup.GroupsViewController.SegmentedButton = {
            let s = FansGroup.GroupsViewController.SegmentedButton()
            s.frame = CGRect(x: 0, y: 0, width: Frame.Screen.width, height: 60)
            s.backgroundColor = UIColor(hex6: 0x121212)
            s.setButtons(tuples: [(normalIcon: R.image.ac_profile_game_normal(), selectedIcon: R.image.ac_profile_game_selected(), normalTitle: nil, selectedTitle: nil),
                                  (normalIcon: R.image.ac_profile_video_normal(), selectedIcon: R.image.ac_profile_video_selected(), normalTitle: nil, selectedTitle: nil),
                                  (normalIcon: R.image.ac_profile_group_normal(), selectedIcon: R.image.ac_profile_group_selected(), normalTitle: nil, selectedTitle: nil)
            ])
            s.selectedIndexObservable
                .subscribe(onNext: { [weak self] (idx) in
                    guard let `self` = self else { return }
                    let offset = CGPoint(x: self.pagingView.bounds.width * CGFloat(idx), y: 0)
                    self.pagingView.listContainerView.didClickSelectedItem(at: idx)
                    self.pagingView.listContainerView.contentScrollView().setContentOffset(offset, animated: true)
                    
                    switch idx {
                    case 0:
                        Logger.Action.log(.profile_tab_clk, categoryValue: "game")
                    case 1:
                        Logger.Action.log(.profile_tab_clk, categoryValue: "feed")
                    case 2:
                        Logger.Action.log(.profile_tab_clk, categoryValue: "group")
                    default:
                        ()
                    }
                })
                .disposed(by: bag)
            return s
        }()
        
        private lazy var segmentedButtonContainer: UIView = {
            let v = UIView()
            v.addSubview(segmentedButton)
            segmentedButton.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
            return v
        }()
        private let segmentedBtnHeight = CGFloat(60)
        
        private lazy var pagingView: JXPagingView = {
            let p = JXPagingView(delegate: self)
            p.backgroundColor = UIColor(hex6: 0x121212)
            p.mainTableView.backgroundColor = UIColor(hex6: 0x121212)
            p.pinSectionHeaderVerticalOffset = NavigationBar.barHeight.int + Frame.Height.safeAeraTopHeight.int
            return p
        }()
        
        private lazy var profileDataViews = [JXPagingViewListViewDelegate]()
        
        private var pageIndex: Int = 0 {
            didSet {
                segmentedButton.updateSelectedIndex(pageIndex)
            }
        }
        
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
                    return l
                }()
                
                let rightIcon: UIImageView = {
                    let i = UIImageView(image: R.image.ac_profile_pro_next())
                    return i
                }()
                
                v.addSubviews(views: leftIcon, titleLabel, rightIcon)
                
                leftIcon.snp.makeConstraints { (maker) in
                    maker.leading.centerY.equalToSuperview()
                }
                
                titleLabel.snp.makeConstraints { (maker) in
                    maker.leading.equalTo(leftIcon.snp.trailing).offset(6)
                    maker.centerY.equalToSuperview()
                }
                
                rightIcon.snp.makeConstraints { (maker) in
                    maker.leading.equalTo(titleLabel.snp.trailing).offset(2)
                    maker.centerY.trailing.equalToSuperview()
                }
                
                Settings.shared.isProValue.replay()
                    .observeOn(MainScheduler.asyncInstance)
                    .subscribe(onNext: { (isPro) in
                        
                        if isPro {
                            titleLabel.text = R.string.localizable.amongChatProfileProCenter()
                        } else {
                            titleLabel.text = R.string.localizable.profileUnlockPro()
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
        
        private let bottomGradientViewHeight: CGFloat = 134
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
                case .heightUpdated:
                    //update header height
                    self.pagingView.resizeTableHeaderViewHeight()
                }
            }
            return v
        }()
        
        private let relationData = BehaviorRelay<Entity.RelationData?>(value: nil)
        
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
        
        func showReportSheet() {
            Report.ViewController.showReport(on: self, uid: uid.string, type: .user, roomId: "", operate: nil) { [weak self] in
                self?.view.raft.autoShow(.text(R.string.localizable.reportSuccess()))
            }
        }
    }
}

private extension Social.ProfileViewController {
    func setupLayout() {
        
        view.addSubviews(views: pagingView, navView, bottomGradientView)
        
        navView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(Frame.Height.safeAeraTopHeight)
        }
        
        bottomGradientView.snp.makeConstraints { (maker) in
            maker.leading.trailing.bottom.equalToSuperview()
            maker.height.equalTo(bottomGradientViewHeight)
        }
        
        pagingView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        
        if isSelfProfile.value {
            Settings.shared.loginResult.replay()
                .filterNil()
                .observeOn(MainScheduler.asyncInstance)
                .subscribe(onNext: { [weak self] (result) in
                    self?.setUpPagingLayout(for: result.uid)
                })
                .disposed(by: bag)
        } else {
            setUpPagingLayout(for: uid)
        }
        
    }
    
    func setUpPagingLayout(for uid: Int) {
        
        profileDataViews = [
            Social.ProfileGameSkillViewController(with: uid),
            Social.ProfileFeedsViewController(with: uid),
            Social.ProfileGroupsViewController(with: uid)
        ]
        
        if !isSelfProfile.value {
            profileDataViews.forEach { (view) in
                let scroll = view.listScrollView()
                var contentInset = scroll.contentInset
                contentInset.bottom = max(contentInset.bottom, bottomGradientViewHeight)
                scroll.contentInset = contentInset
            }
        }
        
        pagingView.reloadData()
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
        
        isSelfProfile
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] (isSelf) in
                self?.bottomGradientView.isHidden = isSelf
            })
            .disposed(by: bag)
        
        pagingView.listContainerView.contentScrollView().rx.didEndDecelerating
            .subscribe(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                let scrollView = self.pagingView.listContainerView.contentScrollView()
                self.pageIndex = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
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
                    
                    var liveRoom: ProfileLiveRoom? = nil
                    
                    if let room = status.room {
                        liveRoom = room
                    }
                    
                    if let group = status.group {
                        liveRoom = group
                    }
                    
                    self?.headerView.setLiveStatus(liveRoom: liveRoom)
                    
                }, onError: { (error) in
                    
                })
                .disposed(by: bag)
            
        }
    }
    
    func setupData() {
        if isSelfProfile.value, navigationController?.viewControllers.count == 1 {
            pullToDismiss = PullToDismiss(scrollView: pagingView.mainTableView)
            pullToDismiss?.delegate = pagingView
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
            
        }
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

extension Social.ProfileViewController: JXPagingViewDelegate {
    
    func tableHeaderViewHeight(in pagingView: JXPagingView) -> Int {
        return headerView.viewHeight.int
    }
    
    func tableHeaderView(in pagingView: JXPagingView) -> UIView {
        return headerView
    }
    
    func heightForPinSectionHeader(in pagingView: JXPagingView) -> Int {
        return segmentedBtnHeight.int
    }
    
    func viewForPinSectionHeader(in pagingView: JXPagingView) -> UIView {
        return segmentedButtonContainer
    }
    
    func numberOfLists(in pagingView: JXPagingView) -> Int {
        return profileDataViews.count
    }
    
    func pagingView(_ pagingView: JXPagingView, initListAtIndex index: Int) -> JXPagingViewListViewDelegate {
        return profileDataViews[index]
    }
    
    func mainTableViewDidScroll(_ scrollView: UIScrollView) {
        let distance = scrollView.contentOffset.y
        headerView.enlargeTopGbHeight(extraHeight: -distance)
        navView.backgroundView.alpha = distance / NavigationBar.barHeight
        navView.backgroundView.isHidden = distance <= 0
    }
}
