//
//  AmongChat.GroupRoom.MembersController.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 01/04/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SwiftyUserDefaults
import HWPanModal

extension AmongChat.GroupRoom {
    class MembersController: WalkieTalkie.ViewController {
        private lazy var titleView: HeaderView = {
            let v = HeaderView()
            v.title = R.string.localizable.groupRoomMembersTitle()
            return v
        }()
        
        private lazy var tableView: UITableView = {
            let tb = UITableView(frame: .zero, style: .plain)
            tb.dataSource = self
            tb.delegate = self
            tb.register(cellWithClass: MembersCell.self)
            tb.separatorStyle = .none
            tb.backgroundColor = .clear
            return tb
        }()
        
        private var userList: [Entity.UserProfile] = [] {
            didSet {
                tableView.reloadData()
            }
        }
        private var uid = 0
        private var isSelf = false
        
//        override var screenName: Logger.Screen.Node.Start {
//            return .followers
//        }
        
        init(with uid: Int) {
            super.init(nibName: nil, bundle: nil)
            self.uid = uid
            let selfUid = Settings.shared.amongChatUserProfile.value?.uid ?? 0
            cdPrint(" uid is \(uid)  self uid is \(selfUid)")
            self.isSelf = uid == selfUid
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
            loadData()
        }
        
        private func setupLayout() {
            isNavigationBarHiddenWhenAppear = true
            view.backgroundColor = UIColor.theme(.backgroundBlack)
            
            
//            Logger.Action.log(.profile_following_imp, category: nil)
            
            view.addSubviews(views: titleView)
                        
            titleView.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview()
                maker.height.equalTo(65.5)
                maker.top.equalTo(topLayoutGuide.snp.bottom)
            }
            
            view.addSubview(tableView)
            tableView.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview()
                maker.top.equalTo(titleView.snp.bottom)
                maker.bottom.equalTo(bottomLayoutGuide.snp.top)
            }
            
            tableView.pullToRefresh { [weak self] in
                self?.loadData()
            }
            tableView.pullToLoadMore { [weak self] in
                self?.loadMore()
            }
        }
        
        private func loadData() {
            let removeBlock = view.raft.show(.loading)
            
                Request.followingList(uid: uid, skipMs: 0)
                    .subscribe(onSuccess: { [weak self](data) in
                        removeBlock()
                        guard let `self` = self, let data = data else { return }
                        self.userList = data.list ?? []
                        if self.userList.isEmpty {
                            self.addNoDataView(R.string.localizable.errorNoFollowing())
                        }
                        self.tableView.endLoadMore(data.more ?? false)
                    }, onError: { [weak self](error) in
                        removeBlock()
                        self?.addErrorView({ [weak self] in
                            self?.loadData()
                        })
                        cdPrint("followingList error: \(error.localizedDescription)")
                    }).disposed(by: bag)
        }
        
        private func loadMore() {
            let skipMS = userList.last?.opTime ?? 0
            
            Request.followingList(uid: uid, skipMs: skipMS)
                .subscribe(onSuccess: { [weak self](data) in
                    guard let data = data else { return }
                    let list =  data.list ?? []
                    var origenList = self?.userList
                    list.forEach({ origenList?.append($0)})
                    self?.userList = origenList ?? []
                    self?.tableView.endLoadMore(data.more ?? false)
                }, onError: { (error) in
                    cdPrint("followingList error: \(error.localizedDescription)")
                }).disposed(by: bag)
        }
    }
}
// MARK: - UITableView
extension AmongChat.GroupRoom.MembersController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withClass: MembersCell.self)
        if let user = userList.safe(indexPath.row) {
//            cell.configView(with: user, isFollowing: isFollowing, isSelf: isSelf)
            cell.updateFollowData = { [weak self] (follow) in
                guard let `self` = self else { return }
                self.userList[indexPath.row].isFollowed = follow
                self.addLogForFollow(with: self.userList[indexPath.row].uid)
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let user = userList.safe(indexPath.row) {
            addLogForProfile(with: user.uid)
            let vc = Social.ProfileViewController(with: user.uid)
            vc.followedHandle = { [weak self](followed) in
                guard let `self` = self else { return }
//                if self.isSelf && self.isFollowing {
//                    if followed {
//                        self.userList.insert(user, at: indexPath.row)
//                    } else {
//                        self.userList.remove(at: indexPath.row)
//                    }
//                }
            }
            self.navigationController?.pushViewController(vc)
        }
    }
    
    private func addLogForFollow(with uid: Int) {
//        if isSelf {
//            if isFollowing {
//                Logger.Action.log(.profile_following_clk, category: .follow, "\(uid)")
//            } else {
//                Logger.Action.log(.profile_followers_clk, category: .follow, "\(uid)")
//            }
//        } else {
//            if isFollowing {
//                Logger.Action.log(.profile_other_followers_clk, category: .follow, "\(uid)")
//            } else {
//                Logger.Action.log(.profile_other_following_clk, category: .follow, "\(uid)")
//            }
//        }
    }
    private func addLogForProfile(with uid: Int) {
//        if isSelf {
//            if isFollowing {
//                Logger.Action.log(.profile_following_clk, category: .profile, "\(uid)")
//            } else {
//                Logger.Action.log(.profile_followers_clk, category: .profile, "\(uid)")
//            }
//        } else {
//            if isFollowing {
//                Logger.Action.log(.profile_other_following_clk, category: .profile, "\(uid)")
//            } else {
//                Logger.Action.log(.profile_other_followers_clk, category: .profile, "\(uid)")
//            }
//        }
    }
}

extension AmongChat.GroupRoom.MembersController {
    
    class MembersCell: TableViewCell {
        
        var updateFollowData: ((Bool) -> Void)?
        var updateInviteData: ((Bool) -> Void)?
        
        let bag = DisposeBag()
        
        private lazy var userView: AmongChat.Home.UserView = {
            let v = AmongChat.Home.UserView()
            return v
        }()

        private lazy var followBtn: UIButton = {
            let btn = UIButton()
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 14)
            btn.setTitle(R.string.localizable.channelUserListFollow(), for: .normal)
            btn.setTitleColor(UIColor(hex6: 0xFFF000), for: .normal)
            btn.layer.masksToBounds = true
            btn.layer.cornerRadius = 16
            btn.layer.borderWidth = 2
            btn.layer.borderColor = UIColor(hex6: 0xFFF000).cgColor
            btn.backgroundColor = UIColor.theme(.backgroundBlack)
            btn.titleLabel?.lineBreakMode = .byTruncatingMiddle
            return btn
        }()
        
        private var userInfo: Entity.UserProfile!
        private var roomId = ""
        private var isInvite = false
        private var isStranger = false
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func prepareForReuse() {
            super.prepareForReuse()
            
        }
        
        private func setupLayout() {
            selectionStyle = .none
            
            backgroundColor = .clear
            
            contentView.addSubviews(views: userView, followBtn)
            let buttonLayout = UILayoutGuide()
            contentView.addLayoutGuide(buttonLayout)
            buttonLayout.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.trailing.equalToSuperview().inset(20)
                maker.height.equalTo(32)
            }
            
            userView.snp.makeConstraints { (maker) in
                maker.leading.equalToSuperview().offset(20)
                maker.top.bottom.equalToSuperview()
                maker.trailing.equalTo(buttonLayout.snp.leading).offset(-20)
            }

            followBtn.snp.makeConstraints { (maker) in
                maker.edges.equalTo(buttonLayout)
            }
            
            followBtn.rx.tap
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self]() in
                    guard let `self` = self else { return }
                    if self.isInvite {
                        if self.userInfo != nil {
                            self.inviteUserAction(self.userInfo, isStranger: self.isStranger)
                        }
                    } else {
                        self.followUser()
                    }
                }).disposed(by: bag)
        }
        
        func configView(with model: Entity.UserProfile, isFollowing: Bool, isSelf: Bool) {
            self.isStranger = false
            self.userInfo = model
            if isSelf {
                if isFollowing {
                    followBtn.isHidden = true
                } else {
                    followBtn.isHidden = false
                }
            } else {
                followBtn.isHidden = false
                if !isFollowing {
                    let selfUid = Settings.shared.amongChatUserProfile.value?.uid ?? 0
                    if selfUid == model.uid {
                        followBtn.isHidden = true
                    }
                }
            }
            
//            avatarIV.setAvatarImage(with: model.pictureUrl)
//            usernameLabel.attributedText = model.nameWithVerified()
            let isfollow = model.isFollowed ?? false
            setFollow(isfollow)
        }
        
        func setFollow(_ isFolllow: Bool) {
            if isFolllow {
                grayFollowStyle()
            } else {
                yellowFollowStyle()
            }
        }
        
        private func setUIForShare() {
            isInvite = true
            followBtn.setTitleColor(.black, for: .normal)
            followBtn.setTitle(R.string.localizable.socialInvite(), for: .normal)
            followBtn.backgroundColor = UIColor(hex6: 0xFFF000)
            followBtn.snp.updateConstraints { (maker) in
                maker.width.equalTo(78)
            }
        }
        
        private func grayFollowStyle() {
            followBtn.setTitle(R.string.localizable.profileFollowing(), for: .normal)
            followBtn.setTitleColor(UIColor(hex6: 0x898989), for: .normal)
            followBtn.layer.borderColor = UIColor(hex6: 0x898989).cgColor
            followBtn.isEnabled = false
        }
        
        private func yellowFollowStyle() {
            followBtn.setTitle(R.string.localizable.profileFollow(), for: .normal)
            followBtn.setTitleColor(UIColor(hex6: 0xFFF000), for: .normal)
            followBtn.layer.borderColor = UIColor(hex6: 0xFFF000).cgColor
            followBtn.isEnabled = true
        }
        
        private func grayInviteStyle() {
            followBtn.setTitle(R.string.localizable.socialInvited(), for: .normal)
            followBtn.setTitleColor(UIColor(hex6: 0x898989), for: .normal)
            followBtn.backgroundColor = UIColor(hex6: 0x222222)
            followBtn.layer.borderColor = UIColor(hex6: 0x898989).cgColor
        }
        
        private func followUser() {
            let isFollowed = userInfo?.isFollowed ?? false
            if isFollowed {
                //                Request.unFollow(uid: userInfo?.uid ?? 0, type: "follow")
                //                    .subscribe(onSuccess: { [weak self](success) in
                //                        guard let `self` = self else { return }
                //                        removeBlock?()
                //                        if success {
                //                            self.setFollow(false)
                //                            self.updateFollowData?(false)
                //                        }
                //                    }, onError: { (error) in
                //                        removeBlock?()
                //                        cdPrint("unfollow error:\(error.localizedDescription)")
                //                    }).disposed(by: bag)
            } else {
                let offset = (Frame.Screen.height - (superview?.height ?? 0)) / 2
                let removeBlock = self.containingController?.view.raft.show(.loading, offset: CGPoint(x: 0, y: -offset))
                Request.follow(uid: userInfo?.uid ?? 0, type: "follow")
                    .subscribe(onSuccess: { [weak self](success) in
                        guard let `self` = self else { return }
                        removeBlock?()
                        if success {
                            self.setFollow(true)
                            self.updateFollowData?(true)
                        }
                    }, onError: { (error) in
                        removeBlock?()
                        cdPrint("follow error:\(error.localizedDescription)")
                    }).disposed(by: bag)
            }
        }
        
        private func inviteUserAction(_ user: Entity.UserProfile, isStranger: Bool) {
            let invited = userInfo.invited ?? false
            if !invited {
                let offset = (Frame.Screen.height - (superview?.height ?? 0)) / 2
                let removeBlock = self.containingController?.view.raft.show(.loading, offset: CGPoint(x: 0, y: -offset))
                Request.inviteUser(roomId: roomId, uid: user.uid, isStranger: isStranger)
                    .subscribe(onSuccess: { [weak self](data) in
                        removeBlock?()
                        self?.updateInviteData?(true)
                    }, onError: { (error) in
                        removeBlock?()
                        cdPrint("invite user error:\(error.localizedDescription)")
                    }).disposed(by: bag)
            }
        }
    }
}


extension AmongChat.GroupRoom.MembersController {
    
    private class HeaderView: UIView {
        
        private lazy var titleLabel: WalkieLabel = {
            let lb = WalkieLabel()
            lb.textAlignment = .center
            lb.font = R.font.nunitoExtraBold(size: 16)
            lb.textColor = .white
            return lb
        }()
        
        var title: String? {
            set { titleLabel.text = newValue }
            get { titleLabel.text }
        }
                
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            addSubview(titleLabel)
            titleLabel.snp.makeConstraints { (make) in
                make.bottom.equalTo(16)
                make.centerX.equalToSuperview()
            }
            
            
            let lineView = UIView()
            lineView.backgroundColor = UIColor.white.alpha(0.08)
            addSubviews(views: lineView)
            
            lineView.snp.makeConstraints { maker in
                maker.left.right.bottom.equalToSuperview()
                maker.height.equalTo(1)
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

extension AmongChat.GroupRoom.MembersController {
    
    override func longFormHeight() -> PanModalHeight {
        return PanModalHeight(type: .topInset, height: 0)
    }
    
    override func shortFormHeight() -> PanModalHeight {
        return PanModalHeight(type: .content, height: Frame.Scale.height(500))
    }
    
    override func panScrollable() -> UIScrollView? {
        return tableView
    }
    
    override func allowsExtendedPanScrolling() -> Bool {
        return true
    }
    
    override func cornerRadius() -> CGFloat {
        return 20
    }
    
    override func showDragIndicator() -> Bool {
        return false
    }
    
}

