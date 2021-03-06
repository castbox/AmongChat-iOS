//
//  Social.BlockedUserViewController.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/9/1.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SwiftyUserDefaults

extension Social {
    struct BlockedUserList {}
}

extension Social.BlockedUserList {
    
    class ViewController: WalkieTalkie.ViewController {
                
        private lazy var navView: NavigationBar = {
            let n = NavigationBar()
            let btn = n.leftBtn
            btn.rx.tap.observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self]() in
                    self?.navigationController?.popViewController()
                }).disposed(by: bag)
            btn.setImage(R.image.ac_back(), for: .normal)
            let lb = n.titleLabel
            lb.text = R.string.localizable.socialBlockedUserTitle()
            return n
        }()
        
        private typealias BlockedUserCell = Widgets.BlockedUserCell
        
        private lazy var tableView: UITableView = {
            let tb = UITableView(frame: .zero, style: .plain)
            tb.dataSource = self
            tb.delegate = self
            tb.register(cellWithClass: BlockedUserCell.self)
            tb.separatorStyle = .none
            tb.backgroundColor = .clear
            return tb
        }()
        
        private var userList: [Entity.UserProfile] = [] {
            didSet {
                tableView.reloadData()
            }
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
            loadData()
        }
        
        private func setupLayout() {
            
            isNavigationBarHiddenWhenAppear = true
            view.backgroundColor = UIColor.theme(.backgroundBlack)
            
            view.addSubviews(views: navView)
            
            navView.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview()
                maker.top.equalTo(topLayoutGuide.snp.bottom)
            }
            
            view.addSubview(tableView)
            tableView.snp.makeConstraints { (maker) in
                maker.left.right.equalToSuperview()
                maker.top.equalTo(navView.snp.bottom).offset(20)
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
            let uid = Settings.shared.amongChatUserProfile.value?.uid ?? 0
            Request.blockList(uid: uid, skipMs: 0)
                .subscribe(onSuccess: { [weak self](data) in
                    removeBlock()
                    guard let `self` = self else { return }
                    self.userList = data?.list ?? []
                    if self.userList.isEmpty {
                        self.addNoDataView(R.string.localizable.errorNoBlocker())
                    }
                    self.tableView.endLoadMore(data?.more ?? false)
                }, onError: { [weak self](error) in
                    removeBlock()
                    self?.addErrorView({ [weak self] in
                        self?.loadData()
                    })
                }).disposed(by: bag)
        }
        
        private func loadMore() {
            let removeBlock = view.raft.show(.loading)
            let uid = Settings.shared.amongChatUserProfile.value?.uid ?? 0
            let skipMS = userList.last?.opTime ?? 0
            Request.blockList(uid: uid, skipMs: skipMS)
                .subscribe(onSuccess: { [weak self](data) in
                    removeBlock()
                    guard let `self` = self else { return }
                    let list =  data?.list ?? []
                    var origenList = self.userList
                    list.forEach({ origenList.append($0)})
                    self.userList = origenList
                    self.tableView.endLoadMore(data?.more ?? false)
                }, onError: { (error) in
                    removeBlock()
                }).disposed(by: bag)
        }
    }
}

// MARK: - UITableView
extension Social.BlockedUserList.ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withClass: BlockedUserCell.self)

        if let user = userList.safe(indexPath.row) {
            cell.configView(with: user)
            cell.unlockHandle = { [weak self] in
                self?.unblockUser(index: indexPath.row)
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
            let vc = Social.ProfileViewController(with: user.uid)
            navigationController?.pushViewController(vc)
        }
    }
    
    private func unblockUser(index: Int) {
        let removeBlock = view.raft.show(.loading)
        let uid = userList.safe(index)?.uid ?? 0
        Request.unFollow(uid: uid, type: "block")
            .subscribe(onSuccess: { [weak self](success) in
                if success {
                    self?.handleUnblock(at: index, uid: uid)
                }
                removeBlock()
            }, onError: { (error) in
                removeBlock()
            }).disposed(by: bag)
    }
    
    private func handleUnblock(at index: Int, uid: Int) {
        userList.remove(at: index)
        var blockedUsers = Defaults[\.blockedUsersV2Key]
        blockedUsers.removeElement(ifExists: { $0.uid == uid })
        Defaults[\.blockedUsersV2Key] = blockedUsers
        tableView.reloadData()
    }
}
