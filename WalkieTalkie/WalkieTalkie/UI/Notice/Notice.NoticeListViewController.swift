//
//  Notice.NoticeListViewController.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/4/26.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension Notice {
    
    class NoticeListViewController: WalkieTalkie.ViewController {
        
        private typealias SocialMessageCell = Notice.Views.SocialMessageCell
        private typealias SystemMessageCell = Notice.Views.SystemMessageCell

        private lazy var noticeListView: UICollectionView = {
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
            v.register(SocialMessageCell.self, forCellWithReuseIdentifier: NSStringFromClass(SocialMessageCell.self))
            v.register(SystemMessageCell.self, forCellWithReuseIdentifier: NSStringFromClass(SystemMessageCell.self))
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
        
        let hasUnreadNotice = BehaviorRelay(value: false)
                
        var dataSource: [Entity.Notice] = [] {
            didSet {
                noticeVMList = dataSource.enumerated().map({ [weak self] (idx, notice) in
                    NoticeViewModel(with: notice) {
                        self?.noticeListView.reloadItems(at: [IndexPath(item: idx, section: 0)])
                    }
                    
                })
            }
        }
        
        private var noticeVMList: [Notice.NoticeViewModel] = [] {
            didSet {
                noticeListView.reloadData()
                emptyView.isHidden = noticeVMList.count > 0
                noticeListView.endRefresh()
            }
        }
        
        var refreshHandler: (() -> Void)? = nil
                
        override func viewDidLoad() {
            super.viewDidLoad()
            setUpLayout()
            setUpEvents()
        }
        
    }
    
}

extension Notice.NoticeListViewController {
    
    private func setUpLayout() {
        view.addSubviews(views: emptyView, noticeListView)
        
        emptyView.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.leading.greaterThanOrEqualToSuperview().offset(40)
            maker.top.equalTo(100)
        }
        
        noticeListView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        
        noticeListView.pullToRefresh { [weak self] in
            self?.refreshHandler?()
        }
    }
    
    private func setUpEvents() {
        rx.viewDidAppear
            .subscribe(onNext: { [weak self] (_) in
                self?.hasUnreadNotice.accept(false)
            })
            .disposed(by: bag)
    }
    
}

extension Notice.NoticeListViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return noticeVMList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let notice = noticeVMList.safe(indexPath.item) else {
            return UICollectionViewCell()
        }
        
        let cell: UICollectionViewCell
        
        switch notice.notice.message.messageType {
        case .TxtMsg, .ImgMsg, .ImgTxtMsg, .TxtImgMsg:
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(SystemMessageCell.self), for: indexPath)
            
            if let cell = cell as? SystemMessageCell {
                cell.bindNoticeData(notice)
            }

        case .SocialMsg:
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(SocialMessageCell.self), for: indexPath)
            
            if let cell = cell as? SocialMessageCell {
                cell.bindNoticeData(notice)
            }
            
        }
        
        return cell
    }
}

extension Notice.NoticeListViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        guard let notice = noticeVMList.safe(indexPath.item) else {
            return .zero
        }

        return notice.itemsSize
    }
    
}

extension Notice.NoticeListViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let notice = noticeVMList.safe(indexPath.item) else {
            return
        }
        
        notice.action()
    }
    
}
