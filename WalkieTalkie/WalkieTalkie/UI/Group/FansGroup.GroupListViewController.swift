//
//  FansGroup.GroupListViewController.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/4/6.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension FansGroup {
    
    class GroupListViewController: WalkieTalkie.ViewController {
        
        enum Source {
            case myGroups
            case allGroups
            case joinedGroups(Int)
            case createdGroups(Int)
        }
        
        private lazy var navView: FansGroup.Views.NavigationBar = {
            let n = FansGroup.Views.NavigationBar()
            n.leftBtn.setImage(R.image.ac_back(), for: .normal)
            n.leftBtn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] (_) in
                    self?.navigationController?.popViewController()
                })
                .disposed(by: bag)
            
            switch source {
            case .createdGroups(let uid):
                
                if uid.isSelfUid {
                    n.titleLabel.text = R.string.localizable.amongChatGroupGroupsOwnedByMe()
                } else {
                    n.titleLabel.text = R.string.localizable.amongChatGroupGroupsCreated()
                }
                
            case .joinedGroups:
                n.titleLabel.text = R.string.localizable.amongChatGroupGroupsJoined()
            default:
                ()
            }
            
            return n
        }()
        
        private lazy var tableView: UITableView = {
            let tb = UITableView(frame: .zero, style: .grouped)
            tb.register(nibWithCellClass: FansGroupSelfItemCell.self)
            tb.register(nibWithCellClass: FansGroupItemCell.self)
            tb.dataSource = self
            tb.delegate = self
            tb.rowHeight = 149
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
        
        private let groupsRelay = BehaviorRelay<[GroupViewModel]>(value: [])
        private var hasMoreData = true
        private var isLoading = false
        
        private let source: Source
        
        init(source: Source) {
            self.source = source
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setUpLayout()
            setUpEvents()
            loadData()
        }
        
    }
    
}

extension FansGroup.GroupListViewController {
    
    private func setUpLayout() {
        view.addSubview(tableView)
        
        switch source {
        case .myGroups, .allGroups:
            tableView.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
            
        case .createdGroups, .joinedGroups:
            view.addSubview(navView)
            
            navView.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview()
                maker.top.equalTo(topLayoutGuide.snp.bottom)
                maker.height.equalTo(49)
            }
            
            tableView.snp.makeConstraints { (maker) in
                maker.leading.bottom.trailing.equalToSuperview()
                maker.top.equalTo(navView.snp.bottom)
            }
        }
        
        tableView.pullToLoadMore { [weak self] in
            self?.loadData()
        }
    }
    
    private func setUpEvents() {
        groupsRelay
            .subscribe(onNext: { [weak self] (_) in
                self?.tableView.reloadData()
            })
            .disposed(by: bag)

    }
                
    private func loadData() {
        
        guard hasMoreData,
              !isLoading else {
            return
        }
        
        isLoading = true
        
        let loader: Single<[Entity.Group]>
        
        switch source {
        case .myGroups:
            loader = Request.myGroupList(skip: groupsRelay.value.count)
        case .allGroups:
            loader = Request.groupList(skip: groupsRelay.value.count)
        case .createdGroups(let uid):
            loader = Request.groupListOfHost(uid, skip: groupsRelay.value.count)
        case .joinedGroups(let uid):
            loader = Request.groupListOfUserJoined(uid, skip: groupsRelay.value.count)
        }
        
        loader
            .do(onDispose: { [weak self] () in
                self?.isLoading = false
            })
            .subscribe(onSuccess: { [weak self] (groupList) in
                
                guard let `self` = self else {
                    return
                }
                var groups = self.groupsRelay.value
                groups.append(contentsOf: groupList.map({ GroupViewModel(group: $0) }))
                self.groupsRelay.accept(groups)
                self.hasMoreData = groupList.count > 0
                self.tableView.endLoadMore(self.hasMoreData)
            })
            .disposed(by: bag)
    }

}

extension FansGroup.GroupListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groupsRelay.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let group = groupsRelay.value.safe(indexPath.row) else {
            let cell = tableView.dequeueReusableCell(withClass: FansGroupItemCell.self, for: indexPath)
            return cell
        }
        
        if group.isOwnedByMe {
            let cell = tableView.dequeueReusableCell(withClass: FansGroupSelfItemCell.self, for: indexPath)
            cell.bindData(group.group) { [weak self] action in
                switch action {
                case .edit:
                    ()
                case .start:
                    self?.enterRoom(group: group.group, logSource: .matchSource, apiSource: nil)
                }
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withClass: FansGroupItemCell.self, for: indexPath)
            cell.bindData(group.group)
            return cell
        }
        
    }
}

extension FansGroup.GroupListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let group = groupsRelay.value.safe(indexPath.row) else {
            return
        }
        if group.group.status == 1 {
            enterRoom(group: group.group, logSource: nil, apiSource: nil)
        } else {
            
            let vc = FansGroup.GroupInfoViewController(groupId: group.group.gid)
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
}

extension FansGroup.GroupListViewController {
    
    class GroupViewModel {
        
        let group: Entity.Group
        
        init(group: Entity.Group) {
            self.group = group
        }
        
        var isOwnedByMe: Bool {
            guard let uid = Settings.shared.loginResult.value?.uid else {
                return false
            }
            return group.uid == uid
        }
        
    }
    
}
