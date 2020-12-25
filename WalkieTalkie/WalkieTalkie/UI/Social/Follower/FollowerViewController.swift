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

class FollowerViewController: WalkieTalkie.ViewController {
    
    private lazy var backBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.addTarget(self, action: #selector(onBackBtn), for: .primaryActionTriggered)
        btn.setImage(R.image.ac_back(), for: .normal)
        return btn
    }()
    
    private lazy var titleLabel: WalkieLabel = {
        let lb = WalkieLabel()
        lb.font = R.font.nunitoExtraBold(size: 24)
        lb.text = "follower"
        lb.textColor = .white
        lb.appendKern()
        return lb
    }()
        
    private lazy var tableView: UITableView = {
        let tb = UITableView(frame: .zero, style: .plain)
        tb.dataSource = self
        tb.delegate = self
        tb.register(FollowerCell.self, forCellReuseIdentifier: NSStringFromClass(FollowerCell.self))
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
        
        if isFollowing {
            titleLabel.text = "Following"
        } else {
            titleLabel.text = "Follower"
        }
    }
    
    private func bindData() {
        self.userList = []
    }
    
    @objc
    private func onBackBtn() {
        navigationController?.popViewController()
    }
}

// MARK: - UITableView

extension FollowerViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(FollowerCell.self), for: indexPath)
        if let cell = cell as? FollowerCell,
           let user = userList.safe(indexPath.row) {
            cell.configView(with: user)
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

extension FollowerViewController {
    
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
            lb.font = R.font.nunitoExtraBold(size: 20)
            lb.textColor = .white
            return lb
        }()
        
        private lazy var followBtn: UIButton = {
            let btn = UIButton()
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 14)
            btn.setTitle(R.string.localizable.profileUnblock(), for: .normal)
            btn.setTitleColor(.white, for: .normal)
            btn.layer.masksToBounds = true
            btn.layer.cornerRadius = 16
            btn.backgroundColor = UIColor(hex6: 0xFFFFFF, alpha: 0.2)
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
                maker.right.equalTo(-100)
                maker.height.equalTo(30)
                maker.centerY.equalToSuperview()
            }
            
            followBtn.snp.makeConstraints { (maker) in
                maker.width.equalTo(78)
                maker.height.equalTo(32)
                maker.right.equalTo(-20)
                maker.centerY.equalToSuperview()
            }
            
            followBtn.rx.tap
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self]() in
                    self?.followHandle?()
                }).disposed(by: bag)
        }
        
        func configView(with model: Entity.RoomUser) {
            usernameLabel.text = model.name
            usernameLabel.appendKern()
            avatarIV.setAvatarImage(with: model.pictureUrl)
        }
    }
    
}
