//
//  Social.ProfileGroupsViewController.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/6/2.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import JXPagingView

extension Social {
    
    class ProfileGroupsViewController: WalkieTalkie.ViewController {
        
        enum Option {
            case groupsCreated
            case groupsJoined
        }
        
        private var listViewDidScrollCallback: ((UIScrollView) -> ())?
        
        private let createdGroupsRelay = BehaviorRelay<[Entity.Group]>(value: [])
        private let joinedGroupsRelay = BehaviorRelay<[Entity.Group]>(value: [])
        
        private typealias FansGroupSelfItemCell = FansGroup.Views.OwnedGroupCell
        private typealias FansGroupItemCell = FansGroup.Views.JoinedGroupCell
        private typealias SectionHeader = Social.ProfileViewController.SectionHeader
        
        private lazy var table: UICollectionView = {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .vertical
            var hInset: CGFloat = 20
            adaptToIPad {
                hInset = 40
            }
            layout.sectionInset = UIEdgeInsets(top: 16, left: 0, bottom: 56, right: 0)
            layout.minimumLineSpacing = 20
            layout.minimumInteritemSpacing = 16
            let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
            v.contentInset = UIEdgeInsets(top: 24, left: hInset, bottom: 0, right: hInset)
            v.register(cellWithClazz: FansGroupItemCell.self)
            v.register(cellWithClazz: FansGroupSelfItemCell.self)
            v.register(cellWithClazz: JoinedGroupCell.self)
            v.register(supplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withClass: SectionHeader.self)
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
        
        private lazy var options = [Option]() {
            didSet {
                table.reloadData()
                emptyView.isHidden = (options.count > 0)
            }
        }
        
        private let uid: Int
        
        init(with uid: Int) {
            self.uid = uid
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setUpLayout()
            setUpEvents()
            fetchCreatedGroups()
            fetchJoinedGroups()
        }
        
    }
    
}

extension Social.ProfileGroupsViewController {
    
    private func setUpLayout() {
        view.addSubviews(views: emptyView, table)
        
        emptyView.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.leading.greaterThanOrEqualToSuperview().offset(40)
            maker.top.equalTo(24)
        }
        
        table.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
    }
    
    private func setUpEvents() {
        
        FansGroup.GroupUpdateNotification.groupUpdated
            .subscribe(onNext: { [weak self] action, group in
                guard let `self` = self else { return }
                
                switch action {
                case .added:
                    ()
                    
                case .removed:
                    var groups = self.createdGroupsRelay.value
                    groups.removeAll(where: { $0.gid == group.gid })
                    
                    if groups.count > 0 {
                        self.createdGroupsRelay.accept(groups)
                    } else {
                        self.fetchCreatedGroups()
                    }
                    
                case .updated:
                    var groups = self.createdGroupsRelay.value
                    if let idx = groups.firstIndex(where: { $0.gid == group.gid }) {
                        groups[idx] = group
                        self.createdGroupsRelay.accept(groups)
                    }
                    
                }
            })
            .disposed(by: bag)
        
        Observable.combineLatest(createdGroupsRelay.skip(1), joinedGroupsRelay.skip(1))
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] createdGroups, joinedGroups in
                
                var options: [Option] = []
                
                if createdGroups.count > 0 {
                    options.append(.groupsCreated)
                }
                
                if joinedGroups.count > 0 {
                    options.append(.groupsJoined)
                }
                
                self?.options = options
            })
            .disposed(by: bag)
    }
    
    private func fetchCreatedGroups() {
        Request.groupListOfHost(uid, skip: 0, limit: 2)
            .subscribe(onSuccess: { [weak self] (groupList) in
                self?.createdGroupsRelay.accept(groupList)
            })
            .disposed(by: bag)
    }
    
    private func fetchJoinedGroups() {
        Request.groupListOfUserJoined(uid, skip: 0, limit: 3)
            .subscribe(onSuccess: { [weak self] (groupList) in
                self?.joinedGroupsRelay.accept( groupList.sorted(by: \.status, with: >) )
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

// MARK: - UICollectionViewDataSource
extension Social.ProfileGroupsViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return options.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        guard let op = options.safe(section) else {
            return 0
        }
        
        switch op {
        
        case .groupsCreated:
            return createdGroupsRelay.value.count
            
        case .groupsJoined:
            return joinedGroupsRelay.value.count
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let op = options[indexPath.section]
        
        switch op {
        
        case .groupsCreated:
            
            let group = createdGroupsRelay.value[indexPath.row]
            
            if uid.isSelfUid {
                let cell = collectionView.dequeueReusableCell(withClazz: FansGroupSelfItemCell.self, for: indexPath)
                cell.tagView.isHidden = true
                cell.bindData(group)  { [weak self] action in
                    guard let `self` = self else { return }
                    switch action {
                    case .edit:
                        self.gotoEditGroup(group.gid)
                        Logger.Action.log(.profile_group_clk, categoryValue: "edit")
                    case .start:
                        self.enter(group: group, logSource: .init(.profile), apiSource: nil)
                        Logger.Action.log(.profile_group_clk, categoryValue: "start")
                    }
                }
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withClazz: FansGroupItemCell.self, for: indexPath)
                cell.bindData(group)
                return cell
            }
            
        case .groupsJoined:
            let cell = collectionView.dequeueReusableCell(withClazz: JoinedGroupCell.self, for: indexPath)
            cell.bindData(joinedGroupsRelay.value[indexPath.item])
            return cell
        }
        
    }
}

// MARK: - UICollectionViewDelegate

extension Social.ProfileGroupsViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        if let op = options.safe(indexPath.section) {
            switch op {
            
            case .groupsJoined:
                let group = joinedGroupsRelay.value[indexPath.item]
                if group.status == 1 {
                    enter(group: group, logSource: .init(.profile), apiSource: nil)
                } else {
                    let vc = FansGroup.GroupInfoViewController(groupId: group.gid)
                    navigationController?.pushViewController(vc, animated: true)
                }
                
            case .groupsCreated:
                Logger.Action.log( uid.isSelfUid ? .profile_group_clk : .profile_other_group_clk, categoryValue: "group")
                guard let group = createdGroupsRelay.value.safe(indexPath.row) else {
                    return
                }
                if group.status == 1 {
                    enter(group: group, logSource: nil, apiSource: nil)
                } else {
                    
                    let vc = FansGroup.GroupInfoViewController(groupId: group.gid)
                    navigationController?.pushViewController(vc, animated: true)
                }
                
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            
            let op = options[indexPath.section]
            
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withClass: SectionHeader.self, for: indexPath)
            
            switch op {
            
            case .groupsCreated:
                header.actionButton.isHidden = false
                
                if uid.isSelfUid {
                    header.titleLabel.text = R.string.localizable.amongChatGroupGroupsOwnedByMe()
                } else {
                    header.titleLabel.text = R.string.localizable.amongChatGroupGroupsCreated()
                }
                
                header.actionButton.setTitle(R.string.localizable.socialSeeAll(), for: .normal)
                header.actionButton.setTitleColor(UIColor(hex6: 0x898989), for: .normal)
                header.actionButton.setImage(nil, for: .normal)
                header.actionButton.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
                header.actionHandler = { [weak self] () in
                    Logger.Action.log(.profile_group_clk, categoryValue: "see_all")
                    guard let `self` = self else { return }
                    let listVC = FansGroup.GroupListViewController(source: .createdGroups(self.uid))
                    self.navigationController?.pushViewController(listVC, animated: true)
                }
                
            case .groupsJoined:
                header.actionButton.isHidden = false
                header.titleLabel.text = R.string.localizable.amongChatGroupGroupsJoined()
                
                header.actionButton.setTitle(R.string.localizable.socialSeeAll(), for: .normal)
                header.actionButton.setTitleColor(UIColor(hex6: 0x898989), for: .normal)
                header.actionButton.setImage(nil, for: .normal)
                header.actionButton.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
                header.actionHandler = { [weak self] () in
                    Logger.Action.log(.profile_group_clk, categoryValue: "see_all")
                    guard let `self` = self else { return }
                    let listVC = FansGroup.GroupListViewController(source: .joinedGroups(self.uid))
                    self.navigationController?.pushViewController(listVC, animated: true)
                }
                
            }
            
            return header
            
        default:
            return UICollectionReusableView()
        }
        
    }
    
}

extension Social.ProfileGroupsViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        guard let op = options.safe(indexPath.section) else {
            return .zero
        }
        
        let padding: CGFloat = collectionView.contentInset.left + collectionView.contentInset.right
        
        switch op {
        
        case .groupsCreated:
            
            var columns: Int = 1
            adaptToIPad {
                columns = 2
            }
            let interitemSpacing: CGFloat = 20
            let hwRatio: CGFloat = 129.0 / 335.0
            
            let cellWidth = ((UIScreen.main.bounds.width - padding - interitemSpacing * CGFloat(columns - 1)) / CGFloat(columns)).rounded(.towardZero)
            let cellHeight = ceil(cellWidth * hwRatio)
            
            return CGSize(width: cellWidth, height: cellHeight)
            
        case .groupsJoined:
            
            var columns: Int = 3
            adaptToIPad {
                columns = 6
            }
            let interitemSpacing: CGFloat = 16
            let hwRatio: CGFloat = 1
            
            let cellWidth = ((UIScreen.main.bounds.width - padding - interitemSpacing * CGFloat(columns - 1)) / CGFloat(columns)).rounded(.towardZero)
            let cellHeight = ceil(cellWidth * hwRatio)
            
            return CGSize(width: cellWidth, height: cellHeight)
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let op = options[section]
        
        switch op {
        
        case .groupsCreated:
            
            if createdGroupsRelay.value.count > 0 {
                return CGSize(width: Frame.Screen.width, height: 27)
            } else {
                return .zero
            }
            
        case .groupsJoined:
            
            if joinedGroupsRelay.value.count > 0 {
                return CGSize(width: Frame.Screen.width, height: 27)
            } else {
                return .zero
            }
            
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return .zero
    }
    
}

extension Social.ProfileGroupsViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        listViewDidScrollCallback?(scrollView)
    }
    
}

extension Social.ProfileGroupsViewController: JXPagingViewListViewDelegate {
    
    func listView() -> UIView {
        return view
    }
    
    func listViewDidScrollCallback(callback: @escaping (UIScrollView) -> ()) {
        listViewDidScrollCallback = callback
    }
    
    func listScrollView() -> UIScrollView {
        return table
    }    
}
