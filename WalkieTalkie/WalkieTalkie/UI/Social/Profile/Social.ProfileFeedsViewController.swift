//
//  Social.ProfileFeedsViewController.swift
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
    
    class ProfileFeedsViewController: WalkieTalkie.ViewController {
        
        private var listViewDidScrollCallback: ((UIScrollView) -> ())?
        
        private lazy var table: UICollectionView = {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .vertical
            var hInset: CGFloat = 20
            adaptToIPad {
                hInset = 40
            }
            layout.sectionInset = UIEdgeInsets(top: 16, left: 0, bottom: 56, right: 0)
            layout.minimumLineSpacing = 8
            layout.minimumInteritemSpacing = 8
            let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
            v.contentInset = UIEdgeInsets(top: 8, left: hInset, bottom: 0, right: hInset)
            v.register(cellWithClazz: FeedCell.self)
            v.register(cellWithClazz: CreateFeedCell.self)
            v.showsVerticalScrollIndicator = false
            v.showsHorizontalScrollIndicator = false
            v.dataSource = self
            v.delegate = self
            v.backgroundColor = .clear
            v.alwaysBounceVertical = true
            if #available(iOS 11.0, *) {
                v.contentInsetAdjustmentBehavior = .never
            } else {
                automaticallyAdjustsScrollViewInsets = false
            }
            return v
        }()
        
        private lazy var emptyView: FansGroup.Views.EmptyDataView = {
            let v = FansGroup.Views.EmptyDataView()
            v.titleLabel.text = R.string.localizable.profileFeedNoVideos()
            v.isHidden = true
            return v
        }()
        
        private lazy var feeds = [Entity.Feed]() {
            didSet {
                table.reloadData()
                if !uid.isSelfUid {
                    emptyView.isHidden = (feeds.count > 0)
                }
                liveFeeds = feeds.compactMap({ feed in
                    guard feed.statusType == .live else { return nil }
                    return feed
                })
            }
        }
        
        private var liveFeeds = [Entity.Feed]()
        
        private var hasMore: Bool = true
        private var isLoading = false
        
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
            loadFeeds()
        }
        
    }
    
}

extension Social.ProfileFeedsViewController {
    
    
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
        
        table.pullToLoadMore { [weak self] in
            self?.loadFeeds()
        }
    }
    
    private func loadFeeds() {
        
        guard hasMore,
              !isLoading else {
            return
        }
        
        isLoading = true
        
        let skipMs = feeds.last?.createTime ?? 0
        
        let request: Single<Entity.FeedList>
        
        if uid.isSelfUid {
            request = Request.myFeeds(skipMs: skipMs)
        } else {
            request = Request.userFeeds(uid, skipMs: skipMs)
        }
        
        request
            .do(onDispose: { [weak self] in
                self?.isLoading = false
            })
            .subscribe(onSuccess: { [weak self] (feedList) in
                guard let `self` = self else { return }
                self.feeds.append(contentsOf: feedList.list)
                self.hasMore = feedList.more
                self.table.endLoadMore(feedList.more)                
            })
            .disposed(by: bag)
    }
    
}

// MARK: - UICollectionViewDataSource
extension Social.ProfileFeedsViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if uid.isSelfUid {
            return max(1, feeds.count)
        } else {
            return feeds.count
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let feed = feeds.safe(indexPath.item) {
            let cell = collectionView.dequeueReusableCell(withClazz: FeedCell.self, for: indexPath)
            cell.configCell(with: feed)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withClazz: CreateFeedCell.self, for: indexPath)
            cell.createAction = { [weak self] in
                let vc = Feed.SelectVideoViewController()
                self?.navigationController?.pushViewController(vc)
                Logger.Action.log(.profile_feed_create_clk)
            }
            return cell
        }
    }
}

extension Social.ProfileFeedsViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let feed = feeds.safe(indexPath.item),
              feed.statusType == .live else {
            return
        }
        
        let liveIdx = liveFeeds.firstIndex { $0.pid == feed.pid } ?? 0
        let vc = Social.ProfileFeedController(with: uid, dataSource: liveFeeds, index: liveIdx)
        UIApplication.topViewController()?.navigationController?.pushViewController(vc)
    }
    
}

extension Social.ProfileFeedsViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let padding: CGFloat = collectionView.contentInset.left + collectionView.contentInset.right
        
        if let _ = feeds.safe(indexPath.item) {
            let columns: Int = 3
            let interitemSpacing: CGFloat = 8
            let hwRatio: CGFloat = 142.0 / 107.0
            
            let cellWidth = ((UIScreen.main.bounds.width - padding - interitemSpacing * CGFloat(columns - 1)) / CGFloat(columns)).rounded(.towardZero)
            let cellHeight = ceil(cellWidth * hwRatio)
            
            return CGSize(width: cellWidth, height: cellHeight)
        } else {
            return CGSize(width: UIScreen.main.bounds.width - padding, height: 267)
        }
        
    }
}

extension Social.ProfileFeedsViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        listViewDidScrollCallback?(scrollView)
    }
    
}

extension Social.ProfileFeedsViewController: JXPagingViewListViewDelegate {
    
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
