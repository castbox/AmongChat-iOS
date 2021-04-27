//
//  Notice.GroupRequestsListViewController.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/4/26.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

extension Notice {
    
    class GroupRequestsListViewController: WalkieTalkie.ViewController {
        
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
            layout.minimumLineSpacing = 52
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
        
        private var hasMoreData = true
        private var isLoading = false
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setUpLayout()
            setUpEvents()
            loadData(initialLoad: true)
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
        
        requestListView.pullToRefresh { [weak self] in
            self?.loadData(refresh: true)
        }
        
        requestListView.pullToLoadMore { [weak self] in
            self?.loadData()
        }
    }
    
    private func setUpEvents() {
        
    }
    
    private func loadData(initialLoad: Bool = false, refresh: Bool = false) {
        
        guard hasMoreData || refresh,
              !isLoading else {
            return
        }
        
        isLoading = true
        
        
        
    }
    
    private func gotoRequestsOfGroup(_ groupInfo: Entity.GroupInfo) {
        let vc = FansGroup.GroupJoinRequestListViewController(with: groupInfo)
        navigationController?.pushViewController(vc)
    }

}

extension Notice.GroupRequestsListViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(GroupRequestCell.self), for: indexPath)
        return cell
    }
}

extension Notice.GroupRequestsListViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    }
    
}


extension Notice.GroupRequestsListViewController {
    
    class GroupRequestCell: UICollectionViewCell {
        
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
            
            contentView.addSubviews(views: groupIconView, groupNameLabel, accessoryIconView)
            
            groupIconView.snp.makeConstraints { (maker) in
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
        }
        
    }
    
}
