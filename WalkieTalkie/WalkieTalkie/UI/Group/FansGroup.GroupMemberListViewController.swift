//
//  FansGroup.GroupMemberListViewController.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/4/8.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension FansGroup {
    
    class GroupMemberListViewController: WalkieTalkie.ViewController {
        
        private(set) lazy var tableView: UITableView = {
            let tb = UITableView(frame: .zero, style: .grouped)
            tb.register(MemberCell.self, forCellReuseIdentifier: NSStringFromClass(MemberCell.self))
            tb.register(AddMemberCell.self, forCellReuseIdentifier: NSStringFromClass(AddMemberCell.self))
            tb.dataSource = self
            tb.delegate = self
            tb.rowHeight = 69
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
        
        private let membersRelay = BehaviorRelay<[Entity.UserProfile]>(value: [])
        private var hasMoreData = true
        private var isLoading = false
        
        private let groupInfo: Entity.GroupInfo
        
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
            fetchMembers()
        }
        
    }
    
}

extension FansGroup.GroupMemberListViewController: UITableViewDataSource {
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        if groupInfo.group.uid.isSelfUid {
            return 3
        } else {
            return 2
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch (section, groupInfo.group.uid.isSelfUid) {
        
        case(0, _):
            return 1
            
        case(1, true):
            return 1
            
        default:
            return membersRelay.value.count
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch (indexPath.section, groupInfo.group.uid.isSelfUid) {
        
        case (1, true):
            let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(AddMemberCell.self), for: indexPath)
            
            guard let addCell = cell as? AddMemberCell else {
                return cell
            }
            
            addCell.tapHandler = { [weak self] in
                guard let `self` = self else {
                    return
                }
                let vc = FansGroup.AddMemberController(groupId: self.groupInfo.group.gid, self.groupInfo.group)
                vc.newAddedMemberObservable
                    .subscribe(onNext: { (user) in
                                                
                        var members = self.membersRelay.value
                        members.insert(user, at: 0)
                        self.membersRelay.accept(members)
                        
                    })
                    .disposed(by: self.bag)
                self.navigationController?.pushViewController(vc, animated: true)
            }
            
            return cell
            
        case (let section, _):
            
            let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(MemberCell.self), for: indexPath)
            
            guard let memberCell = cell as? MemberCell else {
                return cell
            }
            
            if section == 0 {
                memberCell.bind(user: groupInfo.group.broadcaster) {
                    
                }
                
            } else if let member = membersRelay.value.safe(indexPath.row) {
                memberCell.bind(user: member) {
                    
                }
            }
            
            return cell
        }
        
    }
    
}

extension FansGroup.GroupMemberListViewController: UITableViewDelegate {
    
    // MARK: - UITableViewDelegate
    
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
        
        guard section != 2 else {
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
            l.text = "\(groupInfo.group.membersCount - 1)" + " " + R.string.localizable.amongChatGroupMembers()
            
            v.addSubview(l)
            l.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(20)
                maker.centerY.equalToSuperview()
                maker.height.equalTo(22)
            }
            
            if groupInfo.group.uid.isSelfUid {
                
                let kickButton: UIButton = {
                    let btn = SmallSizeButton(type: .custom)
                    btn.setTitle(R.string.localizable.amongChatRoomKick(), for: .normal)
                    btn.setTitleColor(UIColor(hex6: 0x898989), for: .normal)
                    btn.titleLabel?.font = R.font.nunitoExtraBold(size: 16)
                    btn.rx.controlEvent(.primaryActionTriggered)
                        .subscribe(onNext: { [weak self] (_) in
                            //TODO: - go to kick
                            guard let `self` = self else { return }
                            let selectVC = FansGroup.SelectGroupMemberViewController(with: self.groupInfo)
                            self.navigationController?.pushViewController(selectVC, animated: true)
                        })
                        .disposed(by: bag)

                    return btn
                }()
                
                v.addSubview(kickButton)
                kickButton.snp.makeConstraints { (maker) in
                    maker.centerY.equalToSuperview()
                    maker.trailing.equalToSuperview().inset(20)
                }
                
            }
            
        }
        
        return v
        
    }
    
}

extension FansGroup.GroupMemberListViewController {
    
    private func setUpLayout() {
        
        view.addSubviews(views: tableView)
        
        tableView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
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
    
    private func fetchMembers() {
        guard hasMoreData,
              !isLoading else {
            return
        }
        
        isLoading = true
        
        Request.membersOfGroup(groupInfo.group.gid,
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
    
}
