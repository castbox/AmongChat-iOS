//
//  Feed.RecommendViewController.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 01/06/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import Foundation
import SnapKit
import AVFoundation
import RxSwift

extension Feed {
    class RecommendViewController: Feed.ListViewController {
        private var createButton: UIButton!
        
        private lazy var activityIV: UIImageView = {
            let i = UIImageView()
            i.contentMode = .scaleAspectFill
            i.isHidden = true
            i.isUserInteractionEnabled = true
            i.clipsToBounds = true
            let tap = UITapGestureRecognizer()
            i.addGestureRecognizer(tap)
            tap.rx.event
                .subscribe(onNext: { _ in
                    guard let activity = FireRemote.shared.value.feedActivityInfo else { return }
                    Routes.handle(activity.url)
                    Logger.Action.log(.feeds_activity_clk, categoryValue: nil, activity.url)
                })
                .disposed(by: bag)
            return i
        }()
        
        private lazy var activityContainer: UIView = {
            let v = UIView()
            v.backgroundColor = .clear
            v.addSubviews(views: activityIV)
            activityIV.snp.makeConstraints { maker in
                maker.trailing.equalTo(-8)
                maker.top.equalTo(16)
                maker.leading.bottom.equalToSuperview()
                maker.height.equalTo(76)
                maker.width.equalTo(105)
            }
            return v
        }()
        
        private var isLoadingMore: Bool = false
        private var hasMore: Bool = true
        
        override var screenName: Logger.Screen.Node.Start {
            .feeds
        }
        
        override var isHidesBottomBarWhenPushed: Bool {
            return false
        }
        
        override func viewDidLoad() {
            //
            feedHeight = Frame.Screen.height - Frame.Height.bottomBar
            super.viewDidLoad()
        }
        
        override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
            super.tableView(tableView, willDisplay: cell, forRowAt: indexPath)
            
            if !isLoadingMore, dataSource.count - currentIndex < 5 {
                loadMore()
            }
        }
        
        override func loadData() {
            let removeBlock = view.raft.show(.loading, hideAnimated: false)
            Request.recommendFeeds(excludePids: []) //Settings.loginUserId
                .do(onSuccess: { [weak self] data in
                    guard let `self` = self else { return }
                    removeBlock()
                    self.tableView.alpha = 0
                    self.feedsDataSource = data?.map { Feed.ListCellViewModel(feed: $0) } ?? []
                    self.tableView.reloadData()
                    self.tableView.layoutIfNeeded()
                    self.tableView.alpha = 1
                }, onError: { _ in
                    removeBlock()
                })
                .delay(.fromSeconds(0.2), scheduler: MainScheduler.asyncInstance)
                .subscribe(onSuccess: { [weak self] data in
                    //play first
                    self?.replayVisibleItem()
                }, onError: { [weak self](error) in
                    self?.addErrorView({ [weak self] in
                        self?.loadData()
                    })
                }).disposed(by: bag)
        }
        
        override func loadMore() {
//            let removeBlock = view.raft.show(.loading)
            //exclutepids
            guard hasMore else {
                return
            }
            isLoadingMore = true
            
            let maxIndex = dataSource.count - 1
            let excludePids = dataSource[currentIndex...maxIndex]
                .compactMap { $0 as? FeedCellViewModel }
                .map { $0.feed.pid }
            
            cdPrint("excludePid: \(excludePids)")
            
            Request.recommendFeeds(excludePids: excludePids) //Settings.loginUserId
                .do(onDispose: { [weak self] in
                    self?.isLoadingMore = false
//                    removeBlock()
                })
                .delay(.fromSeconds(0.2), scheduler: MainScheduler.asyncInstance)
                .subscribe(onSuccess: { [weak self] data in
                    guard let `self` = self else { return }
                    var source = data?.map { Feed.ListCellViewModel(feed: $0) } ?? []
                    self.hasMore = source.count >= 10
                    guard !source.isEmpty else { return }
                    source.insert(contentsOf: self.feedsDataSource, at: 0)
                    self.feedsDataSource = source
                    //insert datasource
                    let rows = self.tableView.numberOfRows(inSection: 0)
                    let newRow = self.dataSource.count
                    guard newRow > rows else { return }
                    self.tableView.isPagingEnabled = false
                    let indexPaths = Array(rows..<newRow).map({ IndexPath(row: $0, section: 0) })
                    self.tableView.beginUpdates()
                    self.tableView.insertRows(at: indexPaths, with: .none)
                    self.tableView.endUpdates()
                    self.tableView.isPagingEnabled = true
                }, onError: { [weak self](error) in
//                    self?.addErrorView({ [weak self] in
//                        self?.loadData()
//                    })
                }).disposed(by: bag)
        }
        
        override func bindSubviewEvent() {
            super.bindSubviewEvent()
            
            createButton.rx.tap
                .subscribe(onNext: { [weak self] in
                    guard let `self` = self else { return }
                    AmongChat.Login.doLogedInEvent(style: .authNeeded(source: .create_feed)) { [weak self] in
                        Logger.Action.log(.feeds_create_clk)
                        let vc = Feed.SelectVideoViewController()
                        self?.navigationController?.pushViewController(vc)
                    }
                })
                .disposed(by: bag)
            
            Observable.combineLatest(FireRemote.shared.remoteValue().map({ $0.value.feedActivityInfo }), rx.viewDidAppear.take(1))
                .observeOn(MainScheduler.asyncInstance)
                .subscribe(onNext: { [weak self] activity, _ in
                    self?.activityIV.isHidden = activity?.img.isEmpty ?? true
                    self?.activityIV.setImage(with: activity?.img)
                    
                    if activity != nil {
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
                            self?.activityIV.setImage(with: activity?.imgSmall)
                            self?.activityIV.snp.updateConstraints({ maker in
                                maker.height.equalTo(40)
                                maker.width.equalTo(40)
                                maker.trailing.equalTo(-14)
                            })
                            
                            UIView.animate(withDuration: 0.25) {
                                self?.activityContainer.layoutIfNeeded()
                            }
                        }
                        
                    }
                    
                })
                .disposed(by: bag)
        }
        
        override func configureSubview() {
            super.configureSubview()
            createButton = SmallSizeButton(type: .custom)
            createButton.setImage(R.image.iconVideoCreate(), for: .normal)

            view.addSubviews(views: createButton, activityContainer)
            
            createButton.snp.makeConstraints { maker in
                maker.top.equalTo(Frame.Height.safeAeraTopHeight + 4.5)
                maker.trailing.equalTo(-14)
                maker.width.height.equalTo(42)
            }
            
            activityContainer.snp.makeConstraints { maker in
                maker.trailing.equalToSuperview()
                maker.top.equalTo(createButton.snp.bottom)
            }
        }
        
//        static func preload() {
//            let removeBlock = view.raft.show(.loading, hideAnimated: false)
//            Request.recommendFeeds(excludePids: []) //Settings.loginUserId
//                .do(onSuccess: { [weak self] data in
//                    guard let `self` = self else { return }
//                    removeBlock()
//                    self.tableView.alpha = 0
//                    self.dataSource = data?.map { Feed.ListCellViewModel(feed: $0) } ?? []
//                    self.tableView.reloadData()
//                    self.tableView.layoutIfNeeded()
//                    self.tableView.alpha = 1
//                }, onError: { _ in
//                    removeBlock()
//                })
//                .delay(.fromSeconds(0.2), scheduler: MainScheduler.asyncInstance)
//                .subscribe(onSuccess: { [weak self] data in
//                    //play first
//                    self?.replayVisibleItem()
//                }, onError: { [weak self](error) in
//                    self?.addErrorView({ [weak self] in
//                        self?.loadData()
//                    })
//                }).disposed(by: bag)
//        }
    }
}
