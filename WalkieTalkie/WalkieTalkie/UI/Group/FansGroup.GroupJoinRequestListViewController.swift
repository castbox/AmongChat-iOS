//
//  FansGroup.GroupJoinRequestListViewController.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/4/9.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension FansGroup {
    
    class GroupJoinRequestListViewController: WalkieTalkie.ViewController {
        
        private(set) lazy var tableView: UITableView = {
            let tb = UITableView(frame: .zero, style: .grouped)
            tb.register(nibWithCellClass: AmongGroupJoinRequestCell.self)
            tb.dataSource = self
            tb.delegate = self
            tb.rowHeight = 124
            tb.separatorStyle = .none
            tb.backgroundColor = .clear
            if #available(iOS 11.0, *) {
                tb.contentInsetAdjustmentBehavior = .never
            } else {
                // Fallback on earlier versions
                automaticallyAdjustsScrollViewInsets = false
            }
            return tb
        }()
        
        private lazy var emptyView: FansGroup.Views.EmptyDataView = {
            let v = FansGroup.Views.EmptyDataView()
            v.titleLabel.text = R.string.localizable.groupRoomApplyGroupListEmpty()
            v.isHidden = true
            return v
        }()
        
        private let usersRelay = BehaviorRelay<[Entity.UserProfile]>(value: [])
        private var hasMoreData = true
        private var isLoading = false
        
        private let groupInfo: Entity.GroupInfo
        
        var requestsCountObservable: Observable<Int> {
            return usersRelay.map { $0.count }.asObservable()
        }
        
        init(with groupInfo: Entity.GroupInfo) {
            self.groupInfo = groupInfo
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setUpLayout()
            setUpEvents()
            fetchRequests()
        }
        
    }
    
}

extension FansGroup.GroupJoinRequestListViewController: UITableViewDataSource {
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usersRelay.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withClass: AmongGroupJoinRequestCell.self)
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        if let user = usersRelay.value.safe(indexPath.row) {
            cell.profile = user
            cell.actionHandler = { [weak self] action in
                switch action {
                case .accept:
                    self?.handleJoinRequest(for: user.uid, accept: true)
                case .reject:
                    self?.handleJoinRequest(for: user.uid, accept: false)
                case .ignore:
                    ()
                }
            }
        }
        return cell
    }
    
}

extension FansGroup.GroupJoinRequestListViewController: UITableViewDelegate {
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let user = usersRelay.value.safe(indexPath.row) {
            let vc = Social.ProfileViewController(with: user.uid)
            vc.followedHandle = { [weak self](followed) in
                guard let `self` = self else { return }
            }
            self.navigationController?.pushViewController(vc)
        }
    }
}

extension FansGroup.GroupJoinRequestListViewController {
    
    private func setUpLayout() {
        
        view.addSubviews(views: emptyView, tableView)
        
        emptyView.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.leading.greaterThanOrEqualToSuperview().offset(40)
            maker.top.equalTo(100)
        }
        
        tableView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        
        tableView.pullToLoadMore { [weak self] in
            self?.fetchRequests()
        }
    }
    
    private func setUpEvents() {
        usersRelay
            .subscribe(onNext: { [weak self] (requests) in
                self?.emptyView.isHidden = requests.count > 0
                self?.tableView.isHidden = !(requests.count > 0)
                self?.tableView.reloadData()
            })
            .disposed(by: bag)
    }
    
    private func fetchRequests() {
        guard hasMoreData,
              !isLoading else {
            return
        }
        
        isLoading = true
        
        Request.appliedUsersOfGroup(groupInfo.group.gid,
                                    skipMs: usersRelay.value.last?.opTime ?? 0)
            .do(onDispose: { [weak self] () in
                self?.isLoading = false
            })
            .subscribe(onSuccess: { [weak self] (groupUserList) in
                
                guard let `self` = self else {
                    return
                }
                var members = self.usersRelay.value
                members.append(contentsOf: groupUserList.list)
                self.usersRelay.accept(members)
                self.hasMoreData = groupUserList.more
                self.tableView.endLoadMore(groupUserList.more)
            })
            .disposed(by: bag)
        
    }
    
    private func handleJoinRequest(for uid: Int, accept: Bool) {
        let removeBlock = view.raft.show(.loading)
        Request.handleGroupApply(of: uid, groupId: groupInfo.group.gid, accept: accept)
            .do(onDispose: { () in
                removeBlock()
            })
            .subscribe(onSuccess: { [weak self] result in
                guard let `self` = self else { return }
                //remove
                
                var users = self.usersRelay.value
                users.removeAll { $0.uid == uid }
                self.usersRelay.accept(users)
                
            }, onError: { (error) in
                
            }).disposed(by: bag)
    }

}
