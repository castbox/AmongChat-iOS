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
import JXPagingView

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
            tb.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
            return tb
        }()
        
        private let membersRelay = BehaviorRelay<[Entity.UserProfile]>(value: [])
        private var hasMoreData = true
        private var isLoading = false
        
        private let groupInfo: Entity.GroupInfo
        var showKick = false
        
        private var listViewDidScrollCallback: ((UIScrollView) -> ())?
        
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
                Logger.Action.log(.group_info_clk, categoryValue: self?.groupInfo.group.topicId, "add_member")
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
                memberCell.bind(user: groupInfo.group.broadcaster)
                
            } else if let member = membersRelay.value.safe(indexPath.row) {
                memberCell.bind(user: member)
            }
            
            return cell
        }
        
    }
    
}

extension FansGroup.GroupMemberListViewController: UITableViewDelegate {
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        if section == 0 || section == 1{
            return 29
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
            l.font = R.font.nunitoExtraBold(size: 18)
            l.textColor = UIColor(hex6: 0x898989)
            l.text = R.string.localizable.amongChatGroupAdmin()
            
            v.addSubview(l)
            l.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(Frame.horizontalBleedWidth)
                maker.centerY.equalToSuperview()
                maker.height.equalTo(25)
            }
            
        } else if section == 1 {
            
            let l = UILabel()
            l.font = R.font.nunitoExtraBold(size: 18)
            l.textColor = UIColor(hex6: 0x898989)
            l.text = "\(groupInfo.group.membersCount)" + " " + R.string.localizable.amongChatGroupMembers()
            
            v.addSubview(l)
            l.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(Frame.horizontalBleedWidth)
                maker.centerY.equalToSuperview()
                maker.height.equalTo(25)
            }
            
            if showKick {
                
                let kickButton: UIButton = {
                    let btn = SmallSizeButton(type: .custom)
                    btn.setImage(R.image.ac_group_kick_member(), for: .normal)
                    btn.rx.controlEvent(.primaryActionTriggered)
                        .subscribe(onNext: { [weak self] (_) in
                            //MARK: - go to kick
                            Logger.Action.log(.group_info_clk, categoryValue: self?.groupInfo.group.topicId, "kick")
                            guard let `self` = self else { return }
                            let selectVC = FansGroup.SelectGroupMemberViewController(with: self.groupInfo)
                            selectVC.kickedMembersObservable
                                .subscribe(onNext: { (uids) in
                                    var members = self.membersRelay.value
                                    uids.forEach { (uid) in
                                        members.removeAll { $0.uid == uid }
                                    }
                                    self.membersRelay.accept(members)
                                })
                                .disposed(by: self.bag)
                            
                            self.navigationController?.pushViewController(selectVC, animated: true)
                        })
                        .disposed(by: bag)

                    return btn
                }()
                
                v.addSubview(kickButton)
                kickButton.snp.makeConstraints { (maker) in
                    maker.centerY.equalToSuperview()
                    maker.trailing.equalToSuperview().inset(Frame.horizontalBleedWidth)
                }
                
            }
            
        }
        
        return v
        
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let v = UIView()
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

extension FansGroup.GroupMemberListViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        listViewDidScrollCallback?(scrollView)
    }
    
}

extension FansGroup.GroupMemberListViewController: JXPagingViewListViewDelegate {
    
    func listView() -> UIView {
        return view
    }

    func listViewDidScrollCallback(callback: @escaping (UIScrollView) -> ()) {
        listViewDidScrollCallback = callback
    }

    func listScrollView() -> UIScrollView {
        return tableView
    }
    
}
