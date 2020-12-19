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

extension Social {
    struct BlockedUserList {}
}

extension Social.BlockedUserList {
    
    class ViewController: WalkieTalkie.ViewController {
        
        private lazy var backBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.addTarget(self, action: #selector(onBackBtn), for: .primaryActionTriggered)
            btn.setImage(R.image.ac_profile_back(), for: .normal)
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
            tb.backgroundColor = .clear//UIColor(hex6: 0xFFD52E, alpha: 1.0)
            return tb
        }()
        
        private var userList: [ChannelUserViewModel] = [] {
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
            view.backgroundColor = UIColor.theme(.backgroundBlack)//UIColor(hex6: 0xFFD52E, alpha: 1.0)

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
                maker.left.equalToSuperview().offset(15)
                maker.width.height.equalTo(25)
            }
            
            titleLabel.snp.makeConstraints { (maker) in
                maker.center.equalTo(navLayoutGuide)
            }
            
            view.addSubview(tableView)
            tableView.snp.makeConstraints { (maker) in
                maker.left.right.equalToSuperview()
                maker.top.equalTo(navLayoutGuide.snp.bottom).offset(25)
                maker.bottom.equalTo(bottomLayoutGuide.snp.top)
            }
            
        }
        
        private func bindData() {
            
            var removeHUDBlock: (() -> Void)? = nil
            
            Social.Module.shared.blockedObservable
                .map({ Set($0) })
                .distinctUntilChanged()
                .map({ Array($0) })
                .do(onNext: { [weak self] (_) in
                    removeHUDBlock = self?.view.raft.show(.loading, userInteractionEnabled: false)
                })
                .flatMap({ FireStore.shared.fetchUsers($0) })
                .map ({ (users) -> [ChannelUserViewModel] in
                    var viewModels = users.map {
                        ChannelUserViewModel(with: ChannelUser.randomUser(uid: $0.profile.uidInt), firestoreUser: $0)
                    }
                    
                    //老版本用户
                    let oldUsers = ChannelUserListViewModel.shared.blockedUsers.filter({ (cUser) -> Bool in
                        !users.contains { (fUser) -> Bool in
                            fUser.profile.uid == cUser.uid
                        }
                    })
                        .map { ChannelUserViewModel(with: $0, firestoreUser: nil) }
                    
                    viewModels.append(contentsOf: oldUsers)
                    
                    return viewModels
                })
                .subscribe(onNext: { [weak self] (users) in
                    removeHUDBlock?()
                    self?.userList = users
                    }, onError: { (_) in
                        removeHUDBlock?()
                })
                .disposed(by: bag)
        }
        
        @objc
        private func onBackBtn() {
            navigationController?.popViewController()
        }
    }
    
}

extension Social.BlockedUserList.ViewController: UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - UITableView
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(BlockedUserCell.self), for: indexPath)
        cell.backgroundColor = .clear
        if let cell = cell as? BlockedUserCell,
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
        
        let modal = Social.BlockedUserList.ActionModal(with: user)
        modal.showModal(in: parent ?? self)
        modal.unblockedCallback = { [weak self] in
            self?.userList.remove(at: indexPath.row)
            self?.tableView.reloadData()
        }
    }

    
}
