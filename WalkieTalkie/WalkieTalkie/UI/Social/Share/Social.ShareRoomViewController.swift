//
//  Social.ShareRoomViewController.swift
//  WalkieTalkie
//
//  Created by zhang dekai on 2020/12/25.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension Social {
    
    class ShareRoomViewController: WalkieTalkie.ViewController {
        
        private lazy var tableView: UITableView = {
            let tb = UITableView(frame: .zero, style: .plain)
            tb.dataSource = self
            tb.delegate = self
            tb.register(Social.FollowerCell.self, forCellReuseIdentifier: NSStringFromClass(Social.FollowerCell.self))
            tb.separatorStyle = .none
            tb.backgroundColor = .clear
            return tb
        }()
        
        private lazy var headerView = ShareHeaderView()
        
        private var userList: [Entity.RoomUser] = [] {
            didSet {
                tableView.reloadData()
            }
        }
        
        private var linkUrl = ""
        private var uid = 0
        
        init(with linkUrl: String, uid: Int) {
            super.init(nibName: nil, bundle: nil)
            self.linkUrl = linkUrl
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
            
            view.backgroundColor = UIColor.theme(.backgroundBlack)
            
            
            view.addSubview(tableView)
            tableView.snp.makeConstraints { (maker) in
                maker.top.left.right.equalToSuperview()
                maker.height.equalTo(500)
            }
            
            tableView.pullToLoadMore { [weak self] in
                self?.loadMore()
            }
            
            let line = UIView()
            line.backgroundColor = UIColor(hex6: 0xFFFFFF,alpha: 0.2)
            line.layer.masksToBounds = true
            line.layer.cornerRadius = 2
            view.addSubviews(views: line)
            line.snp.makeConstraints { (make) in
                make.top.equalTo(8)
                make.centerX.equalToSuperview()
                make.width.equalTo(36)
                make.height.equalTo(4)
            }
            
            headerView.frame = CGRect(x: 0, y: 0, width: Frame.Screen.width, height: 195)
            tableView.tableHeaderView = headerView
            
            headerView.smsHandle = {
                
            }
            
            headerView.copyLinkHandle = {
                
            }
        }
        
        private func bindData() {
            self.userList = []
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
extension Social.ShareRoomViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 20//userList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(Social.FollowerCell.self), for: indexPath)
        if let cell = cell as? Social.FollowerCell,
           let user = userList.safe(indexPath.row) {
            cell.setCellDataForShare(with: user)
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
extension Social.ShareRoomViewController {
    
    private class ShareHeaderView: UIView {
        
        let bag = DisposeBag()
        
        var smsHandle:(()-> Void)?
        var copyLinkHandle:(()-> Void)?
        
        private lazy var smsBtn: LinkButton = {
            let btn = LinkButton(with: UIImage(named: "ac_room_share"), title: "SMS")
            return btn
        }()
        
        private lazy var copyLinkBtn:LinkButton = {
            let btn = LinkButton(with: UIImage(named: "ac_room_copylink"), title: "Copy link")
            return btn
        }()
        
        private lazy var inviteLabel: WalkieLabel = {
            let lb = WalkieLabel()
            lb.font = R.font.nunitoExtraBold(size: 20)
            lb.text = "Invite friends"
            lb.textColor = .white
            return lb
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            addSubviews(views: smsBtn, copyLinkBtn, inviteLabel)
            
            smsBtn.snp.makeConstraints { (make) in
                make.left.equalTo(20)
                make.top.equalTo(40)
                make.width.equalTo(40)
                make.height.equalTo(68)
            }
            
            copyLinkBtn.snp.makeConstraints { (make) in
                make.left.equalTo(smsBtn.snp.right).offset(40)
                make.top.equalTo(40)
                make.width.equalTo(70)
                make.height.equalTo(68)
            }
            
            inviteLabel.snp.makeConstraints { (make) in
                make.left.equalTo(20)
                make.top.equalTo(smsBtn.snp.bottom).offset(40)
            }
            
            smsBtn.rx.tap
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self]() in
                    self?.smsHandle?()
                }).disposed(by: bag)
            
            copyLinkBtn.rx.tap
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self]() in
                    self?.copyLinkHandle?()
                }).disposed(by: bag)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    private class LinkButton: UIButton {
        
        private lazy var iconImageV = UIImageView()
        
        private lazy var subtitleLabel: WalkieLabel = {
            let lb = WalkieLabel()
            lb.textAlignment = .center
            lb.font = R.font.nunitoBold(size: 14)
            lb.textColor = .white
            return lb
        }()
        
        init(with icon: UIImage?, title: String) {
            super.init(frame: .zero)
            
            addSubviews(views: iconImageV, subtitleLabel)
            iconImageV.snp.makeConstraints { (maker) in
                maker.top.centerX.equalToSuperview()
                maker.height.width.equalTo(40)
            }
            
            subtitleLabel.snp.makeConstraints { (maker) in
                maker.top.equalTo(iconImageV.snp.bottom).offset(5)
                maker.centerX.equalToSuperview()
            }
            
            iconImageV.image = icon
            subtitleLabel.text = title
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
}
extension Social.ShareRoomViewController: Modalable {
    
    func style() -> Modal.Style {
        return .customHeight
    }
    
    func height() -> CGFloat {
        return 500
    }
    
    func modalPresentationStyle() -> UIModalPresentationStyle {
        return .overCurrentContext
    }
    
    func cornerRadius() -> CGFloat {
        return 20
    }
    
    func coverAlpha() -> CGFloat {
        return 0.5
    }
    
    func canAutoDismiss() -> Bool {
        return true
    }
}
