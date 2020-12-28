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
            tb.register(Social.FollowerCell.self, forCellReuseIdentifier: NSStringFromClass(Social.FollowerCell.self))
            tb.separatorStyle = .none
            tb.backgroundColor = .clear
            return tb
        }()
        
        private var userList: [Entity.RoomUser] = [] {
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
            bindData()
        }
        
        private func setupLayout() {
            isNavigationBarHiddenWhenAppear = true
            view.backgroundColor = UIColor.theme(.backgroundBlack)
            
            if isFollowing {
                titleLabel.text = "following"
            } else {
                titleLabel.text = "follower"
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
        
        private func bindData() {
            
            self.userList = []
        }
        
        private func loadData() {
            let removeBlock = view.raft.show(.loading)
            if isFollowing {
                Request.followingList(uid: uid, skipMs: 0)
                    .subscribe(onSuccess: { [weak self](data) in
                        removeBlock()
                        
                        self?.tableView.endRefresh()
                    }, onError: { (error) in
                        removeBlock()
                    }).disposed(by: bag)
            } else {
                Request.followerList(uid: uid, skipMs: 0)
                    .subscribe(onSuccess: { [weak self](data) in
                        removeBlock()
                        
                        self?.tableView.endRefresh()
                    }, onError: { (error) in
                        removeBlock()
                    }).disposed(by: bag)
            }
        }
        
        private func loadMore() {
            let removeBlock = view.raft.show(.loading)
            if isFollowing {
                Request.followingList(uid: uid, skipMs: 0)
                    .subscribe(onSuccess: { [weak self](data) in
                        removeBlock()
                        
                        self?.tableView.endRefresh()
                    }, onError: { (error) in
                        removeBlock()
                    }).disposed(by: bag)
            } else {
                Request.followerList(uid: uid, skipMs: 0)
                    .subscribe(onSuccess: { [weak self](data) in
                        removeBlock()
                        
                        self?.tableView.endRefresh()
                    }, onError: { (error) in
                        removeBlock()
                    }).disposed(by: bag)
            }
        }
    }
}
// MARK: - UITableView
extension Social.FollowerViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 20//userList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(Social.FollowerCell.self), for: indexPath)
        if let cell = cell as? Social.FollowerCell,
           let user = userList.safe(indexPath.row) {
            cell.configView(with: user, isFollowing: isFollowing)
            cell.followHandle = { [weak self] in
                self?.removeLockedUser(at: indexPath.row)
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
    
    private func removeLockedUser(at index: Int) {
        let removeBlock = view.raft.show(.loading)
        
    }
}

extension Social {
    
    class FollowerCell: UITableViewCell {
        
        var followHandle: (() -> Void)?
        
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
                    self?.followHandle?()
                }).disposed(by: bag)
            
            avatarIV.setAvatarImage(with: "")
            usernameLabel.text = "hello Kitty"
        }
        
        func configView(with model: Entity.RoomUser, isFollowing: Bool) {
            if isFollowing {
                followBtn.isHidden = true
            } else {
                followBtn.isHidden = false
            }
            avatarIV.setAvatarImage(with: model.pictureUrl)
            usernameLabel.text = model.name
        }
        
        func setCellDataForShare(with model: Entity.RoomUser) {
            setUIForShare()
            avatarIV.setAvatarImage(with: model.pictureUrl)
            usernameLabel.text = model.name
        }
        
        
        private func setUIForShare() {
            followBtn.backgroundColor = UIColor(hex6: 0xFFF000)
            followBtn.snp.updateConstraints { (maker) in
                maker.width.equalTo(78)
            }
        }
    }
}
