//
//  LeaveGameViewController.swift
//  WalkieTalkie
//
//  Created by zhang dekai on 2020/12/25.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
extension Social {
    
    class LeaveGameViewController: WalkieTalkie.ViewController {
        
        private lazy var backBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.rx.tap.observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self]() in
                    self?.navigationController?.popViewController()
                }).disposed(by: bag)
            btn.setImage(R.image.ac_profile_close(), for: .normal)
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
            let tb = UITableView(frame: .zero, style: .grouped)
            tb.dataSource = self
            tb.delegate = self
            tb.register(Social.FollowerCell.self, forCellReuseIdentifier: NSStringFromClass(Social.FollowerCell.self))
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
        
        init(with uid: Int) {
            super.init(nibName: nil, bundle: nil)
            self.uid = uid
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
            
            titleLabel.text = "Leave game"
            
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
            loadData()
        }
        
        private func loadData() {
            mainQueueDispatchAsync(after: 1) {[weak self] in
                self?.tableView.endRefresh()
            }
        }
        
        private func loadMore() {
            mainQueueDispatchAsync(after: 1) {[weak self] in
                self?.tableView.endLoadMore(false)
            }
        }
    }
}

// MARK: - UITableView
extension Social.LeaveGameViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(Social.FollowerCell.self), for: indexPath)
        if let cell = cell as? Social.FollowerCell,
           let user = userList.safe(indexPath.row) {
            cell.configView(with: user, isFollowing: false)
            cell.updateFollowData = { [weak self](follow) in
//                self?.removeLockedUser(at: indexPath.row)
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 90
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let v = UIView()
        let lable = UILabel()
        v.addSubview(lable)
        lable.snp.makeConstraints { (make) in
            make.left.equalTo(20)
            make.right.equalTo(-20)
            make.bottom.equalTo(-17)
        }
        lable.numberOfLines = 0
        lable.textColor = UIColor(hex6: 0x898989)
        lable.font = R.font.nunitoExtraBold(size: 16)
        lable.text = "Follow you crewmates \nyou can play together next time"
        
        return v
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    
    private func removeLockedUser(at index: Int) {
        let removeBlock = view.raft.show(.loading)
    }
}

extension Social.LeaveGameViewController: Modalable {
    
    func style() -> Modal.Style {
        return .customHeight
    }
    
    func height() -> CGFloat {
        return Frame.Screen.height
    }
    
    func modalPresentationStyle() -> UIModalPresentationStyle {
        return .overCurrentContext
    }
    
    func cornerRadius() -> CGFloat {
        return 0
    }
    
    func coverAlpha() -> CGFloat {
        return 0.5
    }
    
    func canAutoDismiss() -> Bool {
        return true
    }
}
