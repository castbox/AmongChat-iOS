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
            btn.addTarget(self, action: #selector(onBackBtn), for: .primaryActionTriggered)
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
            tb.backgroundColor = .clear//UIColor(hex6: 0xFFD52E, alpha: 1.0)
            return tb
        }()
        
        private var userList: [Entity.RoomUser] = [] {
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
                maker.left.equalToSuperview().offset(15)
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
            
        }
        
        private func bindData() {
            self.userList = Defaults[\.blockedUsersV2Key]
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
            cell.unlockHandle = { [weak self] in
                self?.removeLockedUser(at: indexPath.row)
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
    
    private func removeLockedUser(at index: Int) {
        userList.remove(at: index)
        tableView.reloadData()
        Defaults[\.blockedUsersV2Key] = userList
    }
    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        tableView.deselectRow(at: indexPath, animated: true)
//
//        guard let user = userList.safe(indexPath.row) else { return }
//
//        let modal = Social.BlockedUserList.ActionModal(with: user)
//        modal.showModal(in: parent ?? self)
//        modal.unblockedCallback = { [weak self] in
//            self?.userList.remove(at: indexPath.row)
//            self?.tableView.reloadData()
//        }
//    }
}
