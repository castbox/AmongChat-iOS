//
//  FansGroup.GroupInfoViewController.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/4/7.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension FansGroup {
    
    class GroupInfoViewController: WalkieTalkie.ViewController {
        
        private lazy var navView: FansGroup.Views.NavigationBar = {
            let n = FansGroup.Views.NavigationBar()
            n.leftBtn.setImage(R.image.ac_back(), for: .normal)
            n.leftBtn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] (_) in
                    self?.navigationController?.popViewController()
                })
                .disposed(by: bag)
            n.titleLabel.text = R.string.localizable.amongChatGroupInfo()
            
            n.addSubview(settingBtn)
            settingBtn.snp.makeConstraints { (maker) in
                maker.trailing.equalToSuperview().offset(-20)
                maker.centerY.equalToSuperview()
            }
            return n
        }()
        
        private lazy var settingBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.setImage(R.image.ac_group_setting(), for: .normal)
            btn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] (_) in
                    
                })
                .disposed(by: bag)
            btn.isHidden = true
            return btn
        }()
        
        private lazy var groupHeaderView: GroupHeaderView = {
            let h = GroupHeaderView()
            h.leaveHandler = { [weak self] in
                self?.leaveGroup()
            }
            
            h.expandedHandler = { [weak self] in
                guard let `self` = self else { return }
                self.tableView.tableHeaderView?.frame.size = self.groupHeaderView.viewSize
                self.tableView.reloadData()
            }
            
            return h
        }()
        
        private lazy var tableView: UITableView = {
            let tb = UITableView(frame: .zero, style: .grouped)
            tb.register(MemberCell.self, forCellReuseIdentifier: NSStringFromClass(MemberCell.self))
            tb.register(AddMemberCell.self, forCellReuseIdentifier: NSStringFromClass(AddMemberCell.self))
            tb.dataSource = self
            tb.delegate = self
            tb.rowHeight = 69
            tb.separatorStyle = .none
            tb.backgroundColor = .clear
            groupHeaderView.frame = CGRect(origin: .zero, size: CGSize(width: Frame.Screen.width, height: 254))
            tb.tableHeaderView = groupHeaderView
            if #available(iOS 11.0, *) {
                tb.contentInsetAdjustmentBehavior = .never
            } else {
                // Fallback on earlier versions
                automaticallyAdjustsScrollViewInsets = false
            }
            return tb
        }()
        
        private lazy var applyButton: UIButton = {
            let btn = UIButton(type: .custom)
            btn.layer.cornerRadius = 24
            btn.setTitle(R.string.localizable.amongChatGroupApplyToJoin(), for: .normal)
            btn.setTitleColor(.black, for: .normal)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
            btn.backgroundColor = UIColor(hexString: "#FFF000")
            btn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] (_) in
                    self?.apply()
                })
                .disposed(by: bag)

            return btn
        }()
        
        private lazy var bottomGradientView: GradientView = {
            let v = Social.ChooseGame.bottomGradientView()
            v.addSubviews(views: applyButton)
            applyButton.snp.makeConstraints { (maker) in
                maker.centerX.equalToSuperview()
                maker.bottom.equalTo(-33)
                maker.height.equalTo(48)
                maker.leading.equalTo(20)
            }
            v.isHidden = true
            return v
        }()
        
        private let membersRelay = BehaviorRelay<[Entity.UserProfile]>(value: [])
        private var hasMoreData = true
        private var isLoading = false
        
        private let groupId: String
        private var groupInfoViewModel: GroupViewModel? = nil {
            didSet {
                
                bottomGradientView.isHidden = !(groupInfoViewModel?.userStatus == .some(.applied) || groupInfoViewModel?.userStatus == .some(.none))
                settingBtn.isHidden = !(groupInfoViewModel?.userStatus == .some(.admin) || groupInfoViewModel?.userStatus == .some(.owner))
                
            }
        }
        
        init(groupId: String) {
            self.groupId = groupId
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setUpLayout()
            setUpEvents()
            fetchInfo()
            fetchMembers()
        }
        
    }
    
}

extension FansGroup.GroupInfoViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        guard let group = groupInfoViewModel else {
            return 0
        }
        
        if group.groupInfo.group.uid.isSelfUid {
            return 3
        } else {
            return 2
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        guard let group = groupInfoViewModel else {
            return 0
        }
        
        switch (section, group.groupInfo.group.uid.isSelfUid) {
        
        case(0, _):
            return 1
        
        case(1, true):
            return 1
            
        default:
            return membersRelay.value.count
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let group = groupInfoViewModel else {
            return tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(MemberCell.self), for: indexPath)
        }
        
        switch (indexPath.section, group.groupInfo.group.uid.isSelfUid) {
        
        case (1, true):
            let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(AddMemberCell.self), for: indexPath)

            guard let addCell = cell as? AddMemberCell else {
                return cell
            }
            
            addCell.tapHandler = { [weak self] in
                guard let `self` = self else {
                    return
                }
                let vc = FansGroup.AddMemberController(groupId: self.groupId)
                self.navigationController?.pushViewController(vc, animated: true)
            }
            
            return cell
            
        case (let section, _):
            
            let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(MemberCell.self), for: indexPath)
            
            guard let memberCell = cell as? MemberCell else {
                return cell
            }
            
            if section == 0 {
                memberCell.bind(user: group.groupInfo.group.broadcaster) {
                    
                }
                
            } else if let member = membersRelay.value.safe(indexPath.row) {
                memberCell.bind(user: member) {
                    
                }
            }
            
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        if section == 0 {
            return 52
        } else if section == 1{
            return 26
        } else {
            return .leastNormalMagnitude
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 0 {
            return 24
        } else {
            return .leastNormalMagnitude
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        guard let group = groupInfoViewModel,
              section != 2 else {
            return nil
        }
        
        
        let v = UIView()
        
        if section == 0 {
            
            let l = UILabel()
            l.font = R.font.nunitoExtraBold(size: 16)
            l.textColor = UIColor(hex6: 0x898989)
            l.text = R.string.localizable.amongChatGroupAdmin()
            
            v.addSubview(l)
            l.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(20)
                maker.top.equalTo(24)
                maker.height.equalTo(22)
            }
            
        } else if section == 1 {
            
            let l = UILabel()
            l.font = R.font.nunitoExtraBold(size: 16)
            l.textColor = UIColor(hex6: 0x898989)
            l.text = "\(group.groupInfo.group.membersCount - 1)" + " " + R.string.localizable.amongChatGroupMembers()
            
            v.addSubview(l)
            l.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(20)
                maker.centerY.equalToSuperview()
                maker.height.equalTo(22)
            }
        }
        
        return v
        
    }
}

extension FansGroup.GroupInfoViewController: UITableViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let distance = scrollView.contentOffset.y
        
        groupHeaderView.enlargeTopGbHeight(extraHeight: -distance)
        
        navView.snp.updateConstraints { (maker) in
            maker.top.equalTo(topLayoutGuide.snp.bottom).offset(min(0, -distance / 3))
        }
        
        navView.alpha = 1 - distance / 49
        
    }
    
}

extension FansGroup.GroupInfoViewController {
    
    private func setUpLayout() {
        
        view.addSubviews(views: tableView, navView, bottomGradientView)
        
        tableView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        
        navView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(topLayoutGuide.snp.bottom)
            maker.height.equalTo(49)
        }
        
        bottomGradientView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(bottomLayoutGuide.snp.top)
            maker.height.equalTo(134)
        }
        
        tableView.pullToLoadMore { [weak self] in
            self?.fetchMembers()
        }
    }
    
    private func setUpEvents() {
        membersRelay
            .subscribe(onNext: { [weak self] (_) in
                self?.tableView.reloadData()
            })
            .disposed(by: bag)
        
    }
    
    private func fetchInfo() {
        
        let hudRemoval = self.view.raft.show(.loading)
        Request.groupInfo(groupId)
            .do(onDispose: {
                hudRemoval()
            })
            .subscribe(onSuccess: { [weak self] (info) in
                guard let `self` = self else { return }
                let g = GroupViewModel(groupInfo: info)
                self.groupInfoViewModel = g
                self.groupHeaderView.bindViewModel(g)
                self.tableView.tableHeaderView?.frame.size = self.groupHeaderView.viewSize
                self.tableView.reloadData()
            })
            .disposed(by: bag)
    }
    
    private func fetchMembers() {
        guard hasMoreData,
              !isLoading else {
            return
        }
        
        isLoading = true
        
        Request.membersOfGroup(groupId,
                               skipMs: membersRelay.value.last?.opTime ?? 0)
            .do(onDispose: { [weak self] () in
                self?.isLoading = false
            })
            .subscribe(onSuccess: { [weak self] (memberList) in
                
                guard let `self` = self else {
                    return
                }
                var members = self.membersRelay.value
                members.append(contentsOf: memberList.list)
                self.membersRelay.accept(members)
                self.hasMoreData = memberList.more
                self.tableView.endLoadMore(memberList.more)
            })
            .disposed(by: bag)
        
    }
    
    private func leaveGroup() {
        let hudRemoval = self.view.raft.show(.loading)
        Request.leaveGroup(groupId)
            .do(onDispose: {
                hudRemoval()
            })
            .subscribe(onSuccess: { [weak self] (_) in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: bag)
    }
    
    private func apply() {
        let hudRemoval = self.view.raft.show(.loading)
        Request.applyToJoinGroup(groupId)
            .do(onDispose: {
                hudRemoval()
            })
            .subscribe(onSuccess: { [weak self] (_) in
                self?.bottomGradientView.isHidden = true
            }, onError: { [weak self] (error) in
                self?.view.raft.autoShow(.text(error.msgOfError ?? R.string.localizable.amongChatUnknownError()))
            })
            .disposed(by: bag)
    }
    
}
