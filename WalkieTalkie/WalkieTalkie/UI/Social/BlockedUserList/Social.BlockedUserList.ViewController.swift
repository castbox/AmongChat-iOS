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
            lb.text = R.string.localizable.socialBlockedUserTitle()
            lb.textColor = .white
            lb.appendKern()
            return lb
        }()
        
        private typealias BlockedUserCell = Widgets.BlockedUserCell
        
        private lazy var tableView: UITableView = {
            let tb = UITableView(frame: .zero, style: .plain)
            tb.dataSource = self
            tb.delegate = self
            tb.register(BlockedUserCell.self, forCellReuseIdentifier: NSStringFromClass(BlockedUserCell.self))
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
            tableView.pullToRefresh { [weak self] in
                self?.loadData()
            }
            tableView.pullToLoadMore { [weak self] in
                self?.loadMore()
            }
        }
        
        private func bindData() {
            loadData()
        }
        
        private func loadData() {
            let removeBlock = view.raft.show(.loading)
            let uid = Settings.shared.amongChatUserProfile.value?.uid ?? 0
            Request.blockList(uid: uid, skipMs: 0)
                .subscribe(onSuccess: { [weak self](data) in
                    removeBlock()
                    guard let `self` = self else { return }
                    self.userList = data?.list ?? []
                    self.tableView.endLoadMore(data?.more ?? false)
                }, onError: { (error) in
                    removeBlock()
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
        
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(BlockedUserCell.self), for: indexPath)
        cell.backgroundColor = .clear
        if let cell = cell as? BlockedUserCell,
           let user = userList.safe(indexPath.row) {
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
    
    func unblockUser(index: Int) {
        let removeBlock = view.raft.show(.loading)
        let uid = userList.safe(index)?.uid ?? 0
        Request.unFollow(uid: uid, type: "block")
            .subscribe(onSuccess: { [weak self](success) in
                if success {
                    self?.userList.remove(at: index)
                    var blockedUsers = Defaults[\.blockedUsersV2Key]
                    blockedUsers.removeElement(ifExists: { $0.uid == uid })
                    Defaults[\.blockedUsersV2Key] = blockedUsers
                    self?.tableView.reloadData()
                }
                removeBlock()
            }, onError: { (error) in
                removeBlock()
            }).disposed(by: bag)
    }
}
