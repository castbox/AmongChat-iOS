//
//  Notice.SystemNoticeViewController.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/4/26.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

extension Notice {
    
    class SystemNoticeViewController: WalkieTalkie.ViewController {
        
        private lazy var systemNoticeListView: UICollectionView = {
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
            v.register(MessageCell.self, forCellWithReuseIdentifier: NSStringFromClass(MessageCell.self))
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

extension Notice.SystemNoticeViewController {
    
    private func setUpLayout() {
        view.addSubviews(views: emptyView, systemNoticeListView)
        
        emptyView.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.leading.greaterThanOrEqualToSuperview().offset(40)
            maker.top.equalTo(100)
        }
        
        systemNoticeListView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        
        systemNoticeListView.pullToRefresh { [weak self] in
            self?.loadData(refresh: true)
        }
        
        systemNoticeListView.pullToLoadMore { [weak self] in
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
    
}

extension Notice.SystemNoticeViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(MessageCell.self), for: indexPath)
        return cell
    }
}

extension Notice.SystemNoticeViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    }
    
}
