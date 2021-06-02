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

extension Social {
    
    class ProfileFeedsViewController: WalkieTalkie.ViewController {
        
        enum Option {
            case tiktok
            case feed
        }
        
        private typealias SectionHeader = Social.ProfileViewController.SectionHeader
        private typealias ProfileTableCell = Social.ProfileViewController.ProfileTableCell
        
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
            v.contentInset = UIEdgeInsets(top: 0, left: hInset, bottom: 0, right: hInset)
            v.register(cellWithClazz: ProfileTableCell.self)
            v.register(cellWithClazz: FeedCell.self)
            v.register(cellWithClazz: CreateFeedCell.self)
            v.register(supplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withClass: SectionHeader.self)
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
        
        private lazy var options: [Option] = {
            if uid.isSelfUid {
                return [.feed, .tiktok]
            } else {
                return [.feed]
            }
        }()
        
        private lazy var feeds = [Entity.Feed]() {
            didSet {
                table.reloadData()
                if !uid.isSelfUid {
                    emptyView.isHidden = (feeds.count > 0)
                }
            }
        }
        
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
                
                #if DEBUG
                self.feeds = []
                #endif
            })
            .disposed(by: bag)
    }
    
}

// MARK: - UICollectionViewDataSource
extension Social.ProfileFeedsViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return options.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        guard let op = options.safe(section) else {
            return 0
        }
        
        switch op {
        
        case .tiktok:
            return 1
            
        case .feed:
            
            if uid.isSelfUid {
                return max(1, feeds.count)
            } else {
                return feeds.count
            }
            
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let op = options[indexPath.section]
        
        switch op {
        
        case .tiktok:
            let cell = collectionView.dequeueReusableCell(withClazz: ProfileTableCell.self, for: indexPath)
            cell.leftIconIV.image = R.image.ac_social_tiktok()
            cell.titleLabel.text = R.string.localizable.profileShareTiktokTitle()
            return cell
            
        case .feed:
            if let feed = feeds.safe(indexPath.item) {
                let cell = collectionView.dequeueReusableCell(withClazz: FeedCell.self, for: indexPath)
                cell.configCell(with: feed)
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withClazz: CreateFeedCell.self, for: indexPath)
                cell.createAction = { [weak self] in
                    let vc = Feed.SelectVideoViewController()
                    self?.navigationController?.pushViewController(vc)
                }
                return cell
            }
            
        }
        
    }
}

extension Social.ProfileFeedsViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if let op = options.safe(indexPath.section) {
            switch op {
            
            case .tiktok:
                Logger.Action.log(.profile_tiktok_amongchat_tag_clk)
                guard let url = URL(string: "https://www.tiktok.com/tag/amongchat") else {
                    return
                }
                UIApplication.shared.open(url, options: [:]) { _ in
                    
                }
                
            case .feed:
                //TODO: open feed
                ()
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            
            let op = options[indexPath.section]
            
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withClass: SectionHeader.self, for: indexPath)
            
            switch op {
            
            case .tiktok:
                header.titleLabel.text = R.string.localizable.amongChatProfileMakeTiktokVideo()
                header.actionButton.isHidden = true
                
                
            case .feed:
                ()
                
            }
            
            return header
            
        default:
            return UICollectionReusableView()
        }
        
    }
    
}

extension Social.ProfileFeedsViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        guard let op = options.safe(indexPath.section) else {
            return .zero
        }
        
        let padding: CGFloat = collectionView.contentInset.left + collectionView.contentInset.right
        
        switch op {
        
        case .tiktok:
            return CGSize(width: Frame.Screen.width - padding, height: 68)
            
        case .feed:
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
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let op = options[section]
        
        switch op {
        case .feed:
            return .zero
            
        case .tiktok:
            return CGSize(width: Frame.Screen.width, height: 27)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return .zero
    }
    
}

extension Social.ProfileFeedsViewController: ProfileDataView {
    var scrollView: UIScrollView {
        return table
    }
    
}
