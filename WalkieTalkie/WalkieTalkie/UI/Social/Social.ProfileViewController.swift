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

extension Social {
    
    class ProfileViewController: ViewController {
        
        enum Option {
            case tiktok
            case pro
            
            func image() -> UIImage? {
                switch self {
                case .tiktok:
                    return R.image.ac_social_tiktok()
                case .pro:
                    return R.image.ac_profile_pro()
                }
            }
            
            func text() -> String {
                switch self {
                case .tiktok:
                    return R.string.localizable.profileShareTiktokTitle()
                case .pro:
                    return Settings.shared.isProValue.value ?
                        R.string.localizable.amongChatProfileProCenter() :
                        R.string.localizable.profileUnlockPro()
                }
            }
        }
        var followedHandle:((Bool) -> Void)?
        private lazy var backBtn: UIButton = {
            let btn = UIButton(type: .custom)
            if isSelfProfile, navigationController?.viewControllers.count == 1 {
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
            return btn
        }()
        
        private lazy var settingsBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.setImage(R.image.ac_profile_settings(), for: .normal)
            btn.rx.tap.observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self]() in
                    guard let `self` = self else { return }
                    let vc = SettingViewController()
                    self.navigationController?.pushViewController(vc)
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
                    self?.moreAction()
                }).disposed(by: bag)
            return btn
        }()
        
        private lazy var headerView: ProfileView = {
            let v = ProfileView(with: isSelfProfile)
            var vH: CGFloat {
                guard isSelfProfile else {
                    return 378
                }
                return 241
            }
            v.frame = CGRect(x: 0, y: 0, width: Frame.Screen.width, height: vH)//298  413
            v.headerHandle = { [weak self] type in
                guard let `self` = self else { return }
                switch type {
                case .avater:
                    let vc = Social.SelectAvatarViewController()
                    self.navigationController?.pushViewController(vc)
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
                }
            }
            return v
        }()
        
        private lazy var table: UITableView = {
            let tb = UITableView(frame: .zero, style: .plain)
            tb.dataSource = self
            tb.delegate = self
            tb.separatorStyle = .none
            tb.showsVerticalScrollIndicator = false
            tb.backgroundColor = UIColor.theme(.backgroundBlack)
            tb.rowHeight = 92
            tb.register(cellWithClass: ProfileTableCell.self)
            tb.neverAdjustContentInset()
            return tb
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
        
        private lazy var loginHeader: UIView = {
            let v = UIView()
            v.addSubview(loginButton)
            loginButton.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(20)
                maker.top.equalToSuperview().offset(12)
                maker.height.equalTo(48)
            }
            return v
        }()
        
        private lazy var options: [Option] = [.pro, .tiktok]
        
        private var relationData: Entity.RelationData?
        
        override var screenName: Logger.Screen.Node.Start {
            if isSelfProfile {
                return .profile
            }
            return .profile_other
        }
        
        private var uid = 0
        private var isSelfProfile = true
        private var blocked = false
        var roomUser: Entity.RoomUser!
        private var userProfile: Entity.UserProfile?
        private var pullToDismiss: PullToDismiss?

        init(with uid: Int) {
            super.init(nibName: nil, bundle: nil)
            self.isNavigationBarHiddenWhenAppear = true
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
            rx.viewDidAppear.take(1)
                .subscribe(onNext: { [weak self](_) in
                    guard let `self` = self else { return }
                    if self.isSelfProfile {
                        Logger.Action.log(.profile_imp, category: nil)
                    } else {
                        Logger.Action.log(.profile_other_imp, category: nil, "\(self.uid)")
                    }
                })
                .disposed(by: bag)
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

        let navLayoutGuide = UIView()
        navLayoutGuide.backgroundColor = .clear
//        view.addLayoutGuide(navLayoutGuide)
        view.addSubview(navLayoutGuide)
        navLayoutGuide.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(Frame.Height.safeAeraTopHeight)
            maker.height.equalTo(49)
        }
//
        view.addSubviews(views: table, backBtn, titleLabel)
        
        titleLabel.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.centerY.equalTo(navLayoutGuide)
        }

        table.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview()
            maker.top.equalTo(navLayoutGuide.snp.bottom)
            maker.bottom.equalTo(bottomLayoutGuide.snp.top)
        }
        
        backBtn.snp.makeConstraints { (maker) in
            maker.leading.equalToSuperview().offset(12.5)
            maker.centerY.equalTo(navLayoutGuide)
            maker.width.height.equalTo(40)//25
        }
        if !isSelfProfile {
            options.removeAll()
            view.addSubview(moreBtn)
            moreBtn.snp.makeConstraints { (make) in
                make.right.equalTo(-15)
                make.centerY.equalTo(backBtn.snp.centerY)
                make.width.height.equalTo(40)//24
            }
        } else {
            view.addSubview(settingsBtn)
            settingsBtn.snp.makeConstraints { (maker) in
                maker.centerY.equalTo(navLayoutGuide)
                maker.right.equalToSuperview().inset(20)
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
        if isSelfProfile, navigationController?.viewControllers.count == 1 {
            pullToDismiss = PullToDismiss(scrollView: table)
            pullToDismiss?.delegate = self
        }
        
        if roomUser != nil {
            self.headerView.setProfileData(self.roomUser)
        }
        loadData()
        if isSelfProfile {
            Settings.shared.amongChatUserProfile.replay()
                .subscribe(onNext: { [weak self] (profile) in
                    guard let profile = profile else { return }
                    self?.headerView.configProfile(profile)
                })
                .disposed(by: bag)
            
            Settings.shared.amongChatAvatarListShown.replay()
                .subscribe(onNext: { [weak self] (ts) in
                    if let _ = ts {
                        self?.headerView.changeIcon.redDotOff()
                    } else {
                        self?.headerView.changeIcon.redDotOn(width: 8)
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
    }
    
    func fetchRealation() {
        Request.relationData(uid: uid)
            .subscribe(onSuccess: { [weak self](data) in
                guard let `self` = self, let data = data else { return }
                self.relationData = data
                self.blocked = data.isBlocked ?? false
                self.headerView.setViewData(data, isSelf: self.isSelfProfile)
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
                        self.headerView.setFollowButton(false)
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
                        self.headerView.setFollowButton(true)
                        self.followedHandle?(true)
                    }
                }, onError: { (error) in
                    removeBlock()
                    cdPrint("follow error:\(error.localizedDescription)")
                }).disposed(by: bag)
        }
    }
    
    func followerAction() {
        if !isSelfProfile {
            Logger.Action.log(.profile_other_clk, category: .followers, "\(uid)")
        }
        headerView.redCountLabel.isHidden = true
        let vc = Social.FollowerViewController(with: uid, isFollowing: false)
        navigationController?.pushViewController(vc)
    }
    
    func followingAction() {
        if !isSelfProfile {
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
    
    private func upgradePro() {        
        presentPremiumView()
        Logger.UserAction.log(.update_pro, "settings")
    }

}
// MARK: - UITableView
extension Social.ProfileViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withClass: ProfileTableCell.self, for: indexPath)

        if let op = options.safe(indexPath.row) {
            
            cell.configCell(with: op)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let op = options.safe(indexPath.row) {
            switch op {
            case .pro:
                upgradePro()
            case .tiktok:
                Logger.Action.log(.profile_tiktok_amongchat_tag_clk)
                guard let url = URL(string: "https://www.tiktok.com/tag/amongchat") else {
                    return
                }
                UIApplication.shared.open(url, options: [:]) { _ in
                    
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        if !AmongChat.Login.isLogedin && isSelfProfile{
            return 104
        } else {
            return .leastNormalMagnitude
        }
        
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if !AmongChat.Login.isLogedin && isSelfProfile {
            return loginHeader
        } else {
            return nil
        }
    }
}
