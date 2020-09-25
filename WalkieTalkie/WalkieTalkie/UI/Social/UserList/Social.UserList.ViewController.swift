//
//  Social.UserList.ViewController.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/9/1.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import SwiftyUserDefaults

extension Social {
    
    struct UserList {
        
        enum UserType {
            case following
            case follower
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
            }
        }
        
        private var userList: [UserViewModel] = [] {
            didSet {
                userList.forEach { (user) in
                    user.viewRefresh = { [weak self] in
                        self?.refreshTable()
                    }
                }
                refreshTable()
            }
        }
        
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
            bindData()
        }
        
        private func setupLayout() {
            
            view.addSubview(tableView)
            tableView.snp.makeConstraints { (maker) in
                maker.left.right.equalToSuperview()
                maker.top.equalTo(topLayoutGuide.snp.bottom)
                maker.bottom.equalTo(bottomLayoutGuide.snp.top)
            }
            
        }
        
        private func bindData() {
            
            let uidsOb: Observable<[String]>
            
            switch userType {
            case .following:
                uidsOb = Social.Module.shared.followingObservable.map({ $0.map { $0.uid } })
                
            case .follower:
                uidsOb = Social.Module.shared.followerObservable.map({ $0.map { $0.uid } })
                // subscribe following list to update friends relation
                Social.Module.shared.followingObservable
                    .subscribe(onNext: { [weak self] (_) in
                        self?.tableView.reloadData()
                    })
                    .disposed(by: bag)
            }
            
            var removeHUDBlock: (() -> Void)? = nil
            
            let usersOb = uidsOb
                .flatMap({ FireStore.shared.fetchUsers($0) })
                .map({ $0.map { UserViewModel(with: $0)} })
                
            Observable.combineLatest(uidsOb, usersOb)
                .do(onNext: { [weak self] (_) in
                    removeHUDBlock = self?.view.raft.show(.loading, userInteractionEnabled: false)
                })
                .subscribe(onNext: { [weak self] (t) in
                    removeHUDBlock?()
                    var (uids, users) = t
                    
                    users.sort(by: { (lft, rgt) -> Bool in
                        uids.firstIndex(of: lft.userId) ?? 0 <= uids.firstIndex(of: rgt.userId) ?? 0
                    })
                    
                    self?.userList = users
                    }, onError: { (_) in
                        removeHUDBlock?()
                })
                .disposed(by: bag)
        }
        
        private func refreshTable() {
            let sentList = Defaults[\.joinChannelRequestsSentKey]
            Defaults[\.joinChannelRequestsSentKey] = sentList.compactMapKeysAndValues { (t) -> (String, Double)? in
                let (_, ts) = t
                guard Date().timeIntervalSince(Date(timeIntervalSince1970: ts)) < 5 * 60 else {
                    return nil
                }
                return t
            }
            tableView.reloadData()
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
