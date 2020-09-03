//
//  Social.UserList.ViewController.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/9/1.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

extension Social {
    
    struct UserList {
        
        enum UserType {
            case following
            case follower
            case blocked
        }
        
    }
}

extension Social.UserList {
    
    class ViewController: WalkieTalkie.ViewController, UITableViewDataSource, UITableViewDelegate {
        
        private lazy var tableView: UITableView = {
            let tb = UITableView(frame: .zero, style: .plain)
            tb.dataSource = self
            tb.delegate = self
            tb.register(self.cellClass, forCellReuseIdentifier: self.cellReuseId)
            tb.separatorStyle = .none
            tb.backgroundColor = UIColor(hex6: 0xFFD52E, alpha: 1.0)
            return tb
        }()
        
        private var cellReuseId: String {
            return NSStringFromClass(cellClass)
        }
        
        private var cellClass: AnyClass {
            switch userType {
            case .following:
                return FollowingUserCell.self
            case .follower:
                return FollowerUserCell.self
            case .blocked:
                return BlockedUserCell.self
            }
        }
        
        private var userList: [UserViewModel] = []
        
        private let userType: UserType
        
        init(with type: UserType) {
            userType = type
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
                
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
            fetchData()
        }
        
        private func setupLayout() {
            
            view.addSubview(tableView)
            tableView.snp.makeConstraints { (maker) in
                maker.left.right.equalToSuperview()
                maker.top.equalTo(topLayoutGuide.snp.bottom)
                maker.bottom.equalTo(bottomLayoutGuide.snp.top)
            }
            
        }
        
        private func fetchData() {
            
            let uids: [String]
            
            switch userType {
            case .following:
                uids = Social.Module.shared.followingValue.map { $0.uid }
            case .follower:
                uids = Social.Module.shared.followerValue.map{ $0.uid }
            case .blocked:
                uids = Social.Module.shared.blockedValue
            }
            
            let removeHUDBlock = view.raft.show(.loading, userInteractionEnabled: false)
            let removeBlock = { [weak self] in
                self?.view.isUserInteractionEnabled = true
                removeHUDBlock()
            }
            
            FireStore.shared.fetchUsers(uids)
                .subscribe(onSuccess: { [weak self] (users) in
                    removeBlock()
                    guard let `self` = self else { return }
                    self.userList = users.map { UserViewModel(with: $0) }
                    self.tableView.reloadData()
                    }, onError: { (_) in
                        removeBlock()
                })
                .disposed(by: bag)
        }

                
        // MARK: - UITableView
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return userList.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseId, for: indexPath)
            cell.backgroundColor = .clear
            if let cell = cell as? SocialUserListView,
                let user = userList.safe(indexPath.row) {
                cell.configView(with: user)
                
            }
            
            return cell
        }
        
        func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            return 64
        }
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            tableView.deselectRow(at: indexPath, animated: true)
            
            guard let user = userList.safe(indexPath.row) else { return }
            
            let modal = ActionModal(with: user, userType: userType)
            modal.showModal(in: parent ?? self)
        }
        
    }
    
}
