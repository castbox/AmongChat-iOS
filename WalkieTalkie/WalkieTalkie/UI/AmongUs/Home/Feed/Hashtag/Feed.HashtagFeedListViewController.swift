//
//  Feed.HashtagFeedListViewController.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/7/13.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension Feed {
    
    class HashtagFeedListViewController: WalkieTalkie.ViewController {
        
        private lazy var topicBg: UIImageView = {
            let i = UIImageView()
            i.contentMode = .scaleAspectFill
            if let topic = Settings.shared.globalSetting.value?.feedTopics.first(where: { $0.topicId == feed.topic }) {
                i.setImage(with: topic.bg)
            }
            return i
        }()
        
        private lazy var navView: NavigationBar = {
            let n = NavigationBar()
            let btn = n.leftBtn
            btn.setImage(R.image.ac_back(), for: .normal)
            btn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] () in
                    self?.navigationController?.popViewController()
                })
                .disposed(by: bag)
            
            let rightBtn = SmallSizeButton(type: .custom)
            
            rightBtn.rx.tap
                .subscribe(onNext: { [weak self] in
                    guard let `self` = self else { return }
                    AmongChat.Login.doLogedInEvent(style: .authNeeded(source: .create_feed)) { [weak self] in
                        let vc = Feed.SelectVideoViewController(with: self?.feed.topic)
                        self?.navigationController?.pushViewController(vc)
                    }
                })
                .disposed(by: bag)
            
            rightBtn.setImage(R.image.iconVideoCreate(), for: .normal)
            n.addSubviews(views: rightBtn)
            
            rightBtn.snp.makeConstraints { maker in
                maker.trailing.equalToSuperview().inset(Frame.horizontalBleedWidth)
                maker.centerY.equalToSuperview()
            }
            
            return n
        }()
        
        private lazy var hashtagView: UIView = {
            let v = UIView()
            let i = UIImageView(image: R.image.iconFeedTagPrefix())
            let label = UILabel()
            label.font = R.font.nunitoExtraBold(size: 20)
            label.textColor = .white
            v.addSubviews(views: i, label)
            i.snp.makeConstraints { maker in
                maker.leading.centerY.equalToSuperview()
            }
            label.snp.makeConstraints { maker in
                maker.top.bottom.trailing.equalToSuperview()
                maker.height.equalTo(27)
                maker.leading.equalTo(i.snp.trailing).offset(4)
            }
            label.text = feed.topicName
            return v
        }()
        
        private lazy var viewCountLabel: UILabel = {
            let label = UILabel()
            label.font = R.font.nunitoBold(size: 16)
            label.textColor = UIColor(hex6: 0xFFFFFF, alpha: 0.5)
            return label
        }()
        
        private lazy var feedCollectionView: UICollectionView = {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .vertical
            var hInset: CGFloat = Frame.horizontalBleedWidth
            var columns: Int = 3
            let interitemSpacing: CGFloat = 8
            let cellWidth = ((UIScreen.main.bounds.width - hInset * 2 - interitemSpacing * CGFloat(columns - 1)) / CGFloat(columns)).rounded(.towardZero)
            let hwRatio: CGFloat = 142.0 / 106.5
            let cellHeight: CGFloat = (cellWidth * hwRatio).rounded(.up)
            layout.itemSize = CGSize(width: cellWidth, height: cellHeight)
            layout.minimumInteritemSpacing = interitemSpacing
            layout.minimumLineSpacing = 8
            layout.sectionInset = UIEdgeInsets(top: 0, left: hInset, bottom: Frame.Height.safeAeraBottomHeight, right: hInset)
            
            let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
            v.register(cellWithClazz: FeedCell.self)
            v.showsVerticalScrollIndicator = false
            v.showsHorizontalScrollIndicator = false
            v.dataSource = self
            v.delegate = self
            v.backgroundColor = .clear
            v.alwaysBounceVertical = true
            return v
        }()
        
        private lazy var feedsDataSource: [Feed.ListCellViewModel] = [] {
            didSet {
                feedCollectionView.reloadData()
            }
        }
        
        private var pageData: Entity.AllTopicFeedList? = nil {
            didSet {
                guard let data = pageData else { return }
                viewCountLabel.text = R.string.localizable.amongChatTopicFeedListViewCount(data.totalPlayCount.stringWithSeperator())
            }
        }
        
        private var hasMoreData = true
        private var isLoading = false
        
        private let feed: Entity.Feed
        
        init(with feed: Entity.Feed) {
            self.feed = feed
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            Logger.Action.log(.feeds_topic_imp)
            
            setUpLayout()
            loadData(initialLoad: true)
        }
        
    }
    
}

extension Feed.HashtagFeedListViewController {
    
    private func setUpLayout() {
        
        view.addSubviews(views: topicBg, navView, hashtagView, viewCountLabel, feedCollectionView)
        
        topicBg.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.height.equalTo(topicBg.snp.width).multipliedBy(240.0 / 375.0)
        }
        
        navView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(Frame.Height.safeAeraTopHeight)
        }
        
        hashtagView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(Frame.horizontalBleedWidth)
            maker.top.equalTo(navView.snp.bottom).offset(24)
            maker.trailing.lessThanOrEqualToSuperview().offset(-Frame.horizontalBleedWidth)
        }
        
        viewCountLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(Frame.horizontalBleedWidth)
            maker.height.equalTo(22)
            maker.top.equalTo(hashtagView.snp.bottom).offset(8)
        }
        
        feedCollectionView.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.equalToSuperview()
            maker.top.equalTo(viewCountLabel.snp.bottom).offset(24)
        }
        
        feedCollectionView.pullToLoadMore { [weak self] in
            self?.loadData()
        }
        
    }
    
    private func loadData(initialLoad: Bool = false, refresh: Bool = false) {
        
        guard hasMoreData || refresh,
              !isLoading else {
            return
        }
        
        isLoading = true
        
        var hudRemoval: (() -> Void)? = nil
        if initialLoad {
            hudRemoval = self.view.raft.show(.loading)
        }
        
        let pageSize = Int(20)
        
        Request.allTopicFeeds(topic: feed.topic, limit: pageSize, skipIdx: pageData?.skipIdx ?? 0)
            .do(onDispose: { [weak self] () in
                self?.isLoading = false
                hudRemoval?()
            })
            .subscribe(onSuccess: { [weak self] data in
                guard let `self` = self else { return }
                self.pageData = data
                let source = data.list.map { Feed.ListCellViewModel(feed: $0) }
                self.hasMoreData = source.count >= pageSize
                self.feedsDataSource.append(contentsOf: source)
                self.feedCollectionView.endLoadMore(self.hasMoreData)
            }, onError: { (error) in
            })
            .disposed(by: bag)
    }
    
}

extension Feed.HashtagFeedListViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return feedsDataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withClazz: FeedCell.self, for: indexPath)
        if let feed = feedsDataSource.safe(indexPath.item) {
            cell.bindData(with: feed)            
        }
        return cell
    }
    
}

extension Feed.HashtagFeedListViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let feed = feedsDataSource.safe(indexPath.item) else {
            return
        }
        
        let vc = Social.ProfileFeedController(with: feed.feed, dataSource: feedsDataSource.map({ $0.feed }), index: indexPath.item)
        navigationController?.pushViewController(vc)
    }
    
}
