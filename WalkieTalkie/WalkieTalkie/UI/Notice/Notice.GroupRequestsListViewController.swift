//
//  Notice.GroupRequestsListViewController.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/4/26.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension Notice {
    
    class GroupRequestsListViewController: WalkieTalkie.ViewController, UnhandledNoticeStatusObservableProtocal {
        
        var hasUnhandledNotice: BehaviorRelay<Bool> {
            return hasUnhandledApply
        }
        
        private lazy var requestListView: UICollectionView = {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .vertical
            var hInset: CGFloat = 20
            var columns: Int = 1
            let interitemSpacing: CGFloat = 20
            let cellWidth = ((UIScreen.main.bounds.width - hInset * 2 - interitemSpacing * CGFloat(columns - 1)) / CGFloat(columns)).rounded(.towardZero)
            let cellHeight: CGFloat = 64
            layout.itemSize = CGSize(width: cellWidth, height: cellHeight)
            layout.minimumInteritemSpacing = interitemSpacing
            layout.minimumLineSpacing = 36
            layout.sectionInset = UIEdgeInsets(top: 12, left: hInset, bottom: 0, right: hInset)
            let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
            v.register(GroupRequestCell.self, forCellWithReuseIdentifier: NSStringFromClass(GroupRequestCell.self))
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
            v.titleLabel.text = R.string.localizable.groupRoomApplyGroupListEmpty()
            v.isHidden = true
            return v
        }()
        
        private let hasUnhandledApply = BehaviorRelay(value: false)
        
        private lazy var dataSource: [Entity.GroupApplyStat] = [] {
            didSet {
                requestListView.reloadData()
                hasUnhandledApply.accept(dataSource.count > 0)
                emptyView.isHidden = dataSource.count > 0
            }
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setUpLayout()
            setUpEvents()
            loadData()
            Logger.Action.log(.group_join_request_imp)
        }
        
        
    }
    
}

extension Notice.GroupRequestsListViewController {
    
    private func setUpLayout() {
        view.addSubviews(views: emptyView, requestListView)
        
        emptyView.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.leading.greaterThanOrEqualToSuperview().offset(40)
            maker.top.equalTo(100)
        }
        
        requestListView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        
    }
    
    private func setUpEvents() {
        
    }
    
    private func loadData() {
        Request.myGroupApplyStat()
            .subscribe(onSuccess: { [weak self] (groups) in
                self?.dataSource = groups
            }, onError: { (error) in
                
            })
            .disposed(by: bag)
    }
    
    private func gotoRequestsOfGroup(_ groupId: String) {
        let vc = FansGroup.GroupJoinRequestListViewController(with: groupId, hasNavigationBar: true)
        navigationController?.pushViewController(vc)
        vc.requestsCountObservable
            .skip(1)
            .subscribe(onNext: { [weak self] (count) in
                
                guard let idx = self?.dataSource.firstIndex(where: { $0.gid == groupId }) else { return }
                
                guard count > 0 else {
                    self?.dataSource.remove(at: idx)
                    return
                }
                
                self?.dataSource[idx].applyCount = count
                self?.requestListView.reloadItems(at: [IndexPath(item: idx, section: 0)])
                
            })
            .disposed(by: bag)
    }
    
}

extension Notice.GroupRequestsListViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(GroupRequestCell.self), for: indexPath)
        if let cell = cell as? GroupRequestCell,
           let group = dataSource.safe(indexPath.item) {
            cell.bindData(group)
        }
        return cell
    }
}

extension Notice.GroupRequestsListViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let group = dataSource.safe(indexPath.item) else {
            return
        }
        
        gotoRequestsOfGroup(group.gid)
    }
    
}


extension Notice.GroupRequestsListViewController {
    
    class GroupRequestCell: UICollectionViewCell {
        
        private lazy var groupIconContainer: UIView = {
            let v = UIView()
            v.backgroundColor = .clear
            v.addSubview(groupIconView)
            groupIconView.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
            return v
        }()
        
        private lazy var groupIconView: UIImageView = {
            let i = UIImageView()
            i.layer.cornerRadius = 12
            i.clipsToBounds = true
            i.contentMode = .scaleAspectFill
            return i
        }()
        
        private lazy var groupNameLabel: UILabel = {
            let l = UILabel()
            l.font = R.font.nunitoExtraBold(size: 20)
            l.textColor = UIColor(hex6: 0xFFFFFF)
            l.numberOfLines = 2
            l.adjustsFontSizeToFitWidth = true
            return l
        }()
        
        private lazy var accessoryIconView: UIImageView = {
            let i = UIImageView(image: R.image.ac_right_arrow())
            return i
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setUpLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setUpLayout() {
            backgroundColor = .clear
            contentView.backgroundColor = .clear
            
            contentView.addSubviews(views: groupIconContainer, groupNameLabel, accessoryIconView)
            
            groupIconContainer.snp.makeConstraints { (maker) in
                maker.leading.top.bottom.equalToSuperview()
                maker.width.equalTo(groupIconView.snp.height)
            }
            
            groupNameLabel.snp.makeConstraints { (maker) in
                maker.leading.equalTo(groupIconView.snp.trailing).offset(12)
                maker.trailing.lessThanOrEqualTo(accessoryIconView.snp.leading).offset(-12)
                maker.centerY.equalToSuperview()
            }
            
            accessoryIconView.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.trailing.equalToSuperview()
            }
            
            accessoryIconView.setContentHuggingPriority(UILayoutPriority(UILayoutPriority.defaultHigh.rawValue + 1), for: .horizontal)
            accessoryIconView.setContentCompressionResistancePriority(UILayoutPriority(UILayoutPriority.defaultHigh.rawValue + 1), for: .horizontal)
            groupNameLabel.setContentHuggingPriority(UILayoutPriority(UILayoutPriority.defaultLow.rawValue - 1), for: .horizontal)
            groupNameLabel.setContentCompressionResistancePriority(UILayoutPriority(UILayoutPriority.defaultLow.rawValue - 1), for: .horizontal)
            
        }
        
        func bindData(_ group: Entity.GroupApplyStat) {
            
            groupIconView.setImage(with: group.cover)
            groupNameLabel.text = group.name
            if let count = group.applyCount,
               count > 0 {
                groupIconContainer.badgeOn(string: "\(count)", hAlignment: .tailByTail(-8), topInset: -8, diameter: 22, borderWidth: 2.5, borderColor: UIColor(hex6: 0x121212))
            } else {
                groupIconContainer.badgeOff()
            }
        }
        
    }
    
}
