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
        
        private typealias FansGroupSelfItemCell = FansGroup.Views.OwnedGroupCell
        private typealias FansGroupItemCell = FansGroup.Views.JoinedGroupCell
        
        private lazy var groupListView: UICollectionView = {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .vertical
            var hInset: CGFloat = 20
            var columns: Int = 1
            adaptToIPad {
                hInset = 40
                columns = 2
            }
            let interitemSpacing: CGFloat = 20
            let hwRatio: CGFloat = 129.0 / 335.0
            let cellWidth = (UIScreen.main.bounds.width - hInset * 2 - interitemSpacing * CGFloat(columns - 1)) / CGFloat(columns)
            let cellHeight = ceil(cellWidth * hwRatio)
            layout.itemSize = CGSize(width: cellWidth, height: cellHeight)
            layout.minimumInteritemSpacing = interitemSpacing
            layout.minimumLineSpacing = 20
            layout.sectionInset = UIEdgeInsets(top: 2, left: hInset, bottom: 100, right: hInset)
            let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
            v.register(cellWithClass: FansGroupSelfItemCell.self)
            v.register(cellWithClass: FansGroupItemCell.self)
            v.showsVerticalScrollIndicator = false
            v.showsHorizontalScrollIndicator = false
            v.dataSource = self
            v.delegate = self
            v.backgroundColor = .clear
            v.alwaysBounceVertical = true
            return v
        }()
        
        private lazy var emptyView: FansGroup.Views.EmptyDataView = {
            let v = FansGroup.Views.EmptyDataView()
            v.titleLabel.text = R.string.localizable.amongChatGroupListEmpty()
            v.isHidden = true
            return v
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
            loadData(initialLoad: true)
        }
        
    }
    
}

extension FansGroup.GroupListViewController {
    
    private func setUpLayout() {
        view.addSubviews(views: emptyView, groupListView)
        
        emptyView.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.leading.greaterThanOrEqualToSuperview().offset(40)
            maker.top.equalTo(100)
        }
        
        switch source {
        case .myGroups, .allGroups:
            groupListView.snp.makeConstraints { (maker) in
                maker.top.leading.trailing.equalToSuperview()
                maker.bottom.equalTo(bottomLayoutGuide.snp.top)
            }
            
        case .createdGroups, .joinedGroups:
            view.addSubview(navView)
            
            navView.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview()
                maker.top.equalTo(topLayoutGuide.snp.bottom)
                maker.height.equalTo(49)
            }
            
            groupListView.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview()
                maker.bottom.equalTo(bottomLayoutGuide.snp.top)
                maker.top.equalTo(navView.snp.bottom)
            }
        }
        
        groupListView.pullToRefresh { [weak self] in
            self?.loadData(refresh: true)
        }
        
        groupListView.pullToLoadMore { [weak self] in
            self?.loadData()
        }
    }
    
    private func setUpEvents() {
        groupsRelay
            .skip(1)
            .subscribe(onNext: { [weak self] (groups) in
                self?.emptyView.isHidden = groups.count > 0
                self?.groupListView.isHidden = !(groups.count > 0)
                self?.groupListView.reloadData()
            })
            .disposed(by: bag)
        
        FansGroup.GroupUpdateNotification.groupUpdated
            .subscribe(onNext: { [weak self] action, group in
                guard let `self` = self else { return }
                
                switch action {
                case .added:
                    var groups = self.groupsRelay.value
                    groups.removeAll(where: { $0.group.gid == group.gid })
                    groups.insert(GroupViewModel(group: group), at: 0)
                    self.groupsRelay.accept(groups)
                    
                case .removed:
                    var groups = self.groupsRelay.value
                    groups.removeAll(where: { $0.group.gid == group.gid })
                    self.groupsRelay.accept(groups)
                    
                case .updated:
                    var groups = self.groupsRelay.value
                    if let idx = groups.firstIndex(where: { $0.group.gid == group.gid }) {
                        let updatedGroup = GroupViewModel(group: group)
                        groups[idx] = updatedGroup
                        self.groupsRelay.accept(groups)
                    }
                    
                }
            })
            .disposed(by: bag)
        
    }
                
    private func loadData(initialLoad: Bool = false, refresh: Bool = false) {
        
        guard hasMoreData || refresh,
              !isLoading else {
            return
        }
        
        isLoading = true
        
        let loader: Single<[Entity.Group]>
        
        let skip: Int = refresh ? 0 : groupsRelay.value.count
        
        switch source {
        case .myGroups:
            loader = Request.myGroupList(skip: skip)
        case .allGroups:
            loader = Request.groupList(skip: skip)
        case .createdGroups(let uid):
            loader = Request.groupListOfHost(uid, skip: skip)
        case .joinedGroups(let uid):
            loader = Request.groupListOfUserJoined(uid, skip: skip)
        }
        
        var hudRemoval: (() -> Void)? = nil
        if initialLoad {
            hudRemoval = self.view.raft.show(.loading)
        }
        
        loader
            .do(onDispose: { [weak self] () in
                self?.isLoading = false
                hudRemoval?()
            })
            .subscribe(onSuccess: { [weak self] (groupList) in
                
                guard let `self` = self else {
                    return
                }
                var groups = self.groupsRelay.value
                if refresh {
                    groups.removeAll()
                }
                groups.removeAll { (group) -> Bool in
                    groupList.contains { $0.gid == group.group.gid }
                }
                groups.append(contentsOf: groupList.map({ GroupViewModel(group: $0) }))
                self.groupsRelay.accept(groups)
                self.hasMoreData = groupList.count > 0
                self.groupListView.endLoadMore(self.hasMoreData)
            })
            .disposed(by: bag)
    }
    
    private func gotoEditGroup(_ groupId: String) {
        
        let hudRemoval = view.raft.show(.loading)
        
        FansGroup.GroupEditViewController.groupEditVC(groupId)
            .do(onDispose: {
                hudRemoval()
            })
            .subscribe(onSuccess: { [weak self] (vc) in
                self?.navigationController?.pushViewController(vc, animated: true)
            }, onError: { [weak self] (error) in
                self?.view.raft.autoShow(.text(error.msgOfError ?? R.string.localizable.amongChatUnknownError()))
            })
            .disposed(by: bag)
        
    }
}

extension FansGroup.GroupListViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return groupsRelay.value.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let group = groupsRelay.value.safe(indexPath.row) else {
            let cell = collectionView.dequeueReusableCell(withClass: FansGroupItemCell.self, for: indexPath)
            return cell
        }
        
        if group.isOwnedByMe {
            let cell = collectionView.dequeueReusableCell(withClass: FansGroupSelfItemCell.self, for: indexPath)
            cell.bindData(group.group) { [weak self] action in
                guard let `self` = self else { return }
                switch action {
                case .edit:
                    self.gotoEditGroup(group.group.gid)
                case .start:
                    self.enter(group: group.group, logSource: .init(.my_group), apiSource: nil)
                }
            }
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withClass: FansGroupItemCell.self, for: indexPath)
            cell.bindData(group.group)
            return cell
        }
        
    }
}

extension FansGroup.GroupListViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard let group = groupsRelay.value.safe(indexPath.row) else {
            return
        }
        if group.group.status == 1 {
            enter(group: group.group, logSource: .init(.explore), apiSource: nil)
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
