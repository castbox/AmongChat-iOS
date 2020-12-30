//
//  FollowerViewController.swift
//  WalkieTalkie
//
//  Created by zhang dekai on 2020/12/24.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension Social {
    
    class FollowerViewController: WalkieTalkie.ViewController {
        
        private lazy var backBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.rx.tap.observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self]() in
                    self?.navigationController?.popViewController()
                }).disposed(by: bag)
            btn.setImage(R.image.ac_back(), for: .normal)
            return btn
        }()
        
        private lazy var titleLabel: WalkieLabel = {
            let lb = WalkieLabel()
            lb.font = R.font.nunitoExtraBold(size: 24)
            lb.text = R.string.localizable.profileFollower()
            lb.textColor = .white
            lb.appendKern()
            return lb
        }()
        
        private lazy var tableView: UITableView = {
            let tb = UITableView(frame: .zero, style: .plain)
            tb.dataSource = self
            tb.delegate = self
            tb.register(cellWithClass: Social.FollowerCell.self)
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
        private var isFollowing = true
        
        init(with uid: Int, isFollowing: Bool) {
            super.init(nibName: nil, bundle: nil)
            self.uid = uid
            self.isFollowing = isFollowing
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
            
            if isFollowing {
                titleLabel.text = R.string.localizable.profileFollowing()// "Following"
            } else {
                titleLabel.text = R.string.localizable.profileFollower()// "Followers"
            }
            
            view.addSubviews(views: backBtn, titleLabel)
            
            let navLayoutGuide = UILayoutGuide()
            view.addLayoutGuide(navLayoutGuide)
            navLayoutGuide.snp.makeConstraints { (maker) in
                maker.left.right.equalToSuperview()
                maker.height.equalTo(48)
                maker.top.equalTo(topLayoutGuide.snp.bottom)
            }
            
            backBtn.snp.makeConstraints { (maker) in
                maker.centerY.equalTo(navLayoutGuide)
                maker.left.equalToSuperview().offset(20)
                maker.width.height.equalTo(25)
            }
            
            titleLabel.snp.makeConstraints { (maker) in
                maker.center.equalTo(navLayoutGuide)
            }
            
            view.addSubview(tableView)
            tableView.snp.makeConstraints { (maker) in
                maker.left.right.equalToSuperview()
                maker.top.equalTo(navLayoutGuide.snp.bottom).offset(20)
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
            if isFollowing {
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
            } else {
                Request.followerList(uid: uid, skipMs: 0)
                    .subscribe(onSuccess: { [weak self](data) in
                        removeBlock()
                        guard let `self` = self, let data = data else { return }
                        self.userList = data.list ?? []
                        if self.userList.isEmpty {
                            self.addNoDataView(R.string.localizable.errorNoFollowers())
                        }
                        self.tableView.endLoadMore(data.more ?? false)
                    }, onError: { [weak self](error) in
                        removeBlock()
                        self?.addErrorView({ [weak self] in
                            self?.loadData()
                        })
                        cdPrint("followerList error: \(error.localizedDescription)")
                    }).disposed(by: bag)
            }
        }
        
        private func loadMore() {
            let skipMS = userList.last?.opTime ?? 0
            if isFollowing {
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
            } else {
                Request.followerList(uid: uid, skipMs: skipMS)
                    .subscribe(onSuccess: { [weak self](data) in
                        guard let data = data else { return }
                        let list =  data.list ?? []
                        var origenList = self?.userList
                        list.forEach({ origenList?.append($0)})
                        self?.userList = origenList ?? []
                        self?.tableView.endLoadMore(data.more ?? false)
                    }, onError: { (error) in
                        cdPrint("followerList error: \(error.localizedDescription)")
                    }).disposed(by: bag)
            }
        }
    }
}
// MARK: - UITableView
extension Social.FollowerViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withClass: Social.FollowerCell.self)
        if let user = userList.safe(indexPath.row) {
            cell.configView(with: user)
            cell.updateFollowData = { [weak self] (follow) in
                self?.userList[indexPath.row].isFollowed = follow
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let user = userList.safe(indexPath.row) {
            let vc = Social.ProfileViewController(with: user.uid)
            self.navigationController?.pushViewController(vc)
        }
    }
}

extension Social {
    
    class FollowerCell: UITableViewCell {
        
        var updateFollowData: ((Bool) -> Void)?
        var updateInviteData: ((Bool) -> Void)?
        
        let bag = DisposeBag()
        
        private lazy var avatarIV: UIImageView = {
            let iv = UIImageView()
            iv.layer.cornerRadius = 20
            iv.layer.masksToBounds = true
            return iv
        }()
        
        private lazy var usernameLabel: WalkieLabel = {
            let lb = WalkieLabel()
            lb.font = R.font.nunitoExtraBold(size: 16)
            lb.textColor = .white
            return lb
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
            return btn
        }()
        
        private var userInfo: Entity.UserProfile!
        private var roomId = ""
        private var isInvite = false
        
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
            
            contentView.addSubviews(views: avatarIV, usernameLabel, followBtn)
            
            avatarIV.snp.makeConstraints { (maker) in
                maker.left.equalToSuperview().offset(20)
                maker.centerY.equalToSuperview()
                maker.width.height.equalTo(40)
            }
            
            usernameLabel.snp.makeConstraints { (maker) in
                maker.left.equalTo(avatarIV.snp.right).offset(12)
                maker.right.equalTo(-115)
                maker.height.equalTo(30)
                maker.centerY.equalToSuperview()
            }
            
            followBtn.snp.makeConstraints { (maker) in
                maker.width.equalTo(90)
                maker.height.equalTo(32)
                maker.right.equalTo(-20)
                maker.centerY.equalToSuperview()
            }
            
            followBtn.rx.tap
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self]() in
                    guard let `self` = self else { return }
                    if self.isInvite {
                        if self.userInfo != nil {
                            self.inviteUserAction(self.userInfo)
                        }
                    } else {
                        self.followUser()
                    }
                }).disposed(by: bag)
        }
        
        func configView(with model: Entity.UserProfile) {
            self.userInfo = model
            followBtn.isHidden = false
            avatarIV.setAvatarImage(with: model.pictureUrl)
            usernameLabel.text = model.name
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
        
        func setCellDataForShare(with model: Entity.UserProfile, roomId: String) {
            
            self.userInfo = model
            self.roomId = roomId
            
            setUIForShare()
            avatarIV.setAvatarImage(with: model.pictureUrl)
            usernameLabel.text = model.name
            
            let invited = userInfo.invited ?? false
            if invited {
                grayInviteStyle()
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
        }
        
        private func yellowFollowStyle() {
            followBtn.setTitle(R.string.localizable.profileFollow(), for: .normal)
            followBtn.setTitleColor(UIColor(hex6: 0xFFF000), for: .normal)
            followBtn.layer.borderColor = UIColor(hex6: 0xFFF000).cgColor
        }
        
        private func grayInviteStyle() {
            followBtn.setTitle(R.string.localizable.socialInvited(), for: .normal)
            followBtn.setTitleColor(UIColor(hex6: 0x898989), for: .normal)
            followBtn.backgroundColor = UIColor(hex6: 0x222222)
            followBtn.layer.borderColor = UIColor(hex6: 0x222222).cgColor
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
                let removeBlock = self.superview?.raft.show(.loading)
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
        
        private func inviteUserAction(_ user: Entity.UserProfile) {
            let invited = userInfo.invited ?? false
            if !invited {
                let removeBlock = self.superview?.raft.show(.loading)
                Request.inviteUser(roomId: roomId, uid: user.uid)
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
