//
//  AmongChat.Home.TopicsViewController.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/11/25.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import NotificationBannerSwift
import SwiftyUserDefaults

extension AmongChat.Home {
    
    class TopicsViewController: WalkieTalkie.ViewController {
        
        // MARK: - members
        
        private typealias TopicCell = AmongChat.Home.TopicCell
        private typealias TopicViewModel = AmongChat.Home.TopicViewModel
        private lazy var navigationView = NavigationBar()
            
        private lazy var topicCollectionView: UICollectionView = {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .vertical
            let hInset: CGFloat = 20
            let hwRatio: CGFloat = 156.0 / 335.0
            let cellWidth = UIScreen.main.bounds.width - hInset * 2
            let cellHeight = cellWidth * hwRatio
            layout.itemSize = CGSize(width: cellWidth, height: cellHeight)
            layout.minimumLineSpacing = 27
            layout.sectionInset = UIEdgeInsets(top: 27, left: hInset, bottom: Frame.Height.safeAeraBottomHeight, right: hInset)
            let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
            v.register(TopicCell.self, forCellWithReuseIdentifier: NSStringFromClass(TopicCell.self))
            v.showsVerticalScrollIndicator = false
            v.showsHorizontalScrollIndicator = false
            v.dataSource = self
            v.delegate = self
            v.backgroundColor = .clear
            v.alwaysBounceVertical = true
            return v
        }()
        
        private var hudRemoval: (() -> Void)? = nil
        
        private var enterTopicHistory: [String] {
            get { Defaults[\.amongChatEnterRoomTopicHistory] }
            set { Defaults[\.amongChatEnterRoomTopicHistory] = newValue }
        }
        
        private lazy var previousEnterHistory = Defaults[\.amongChatEnterRoomTopicHistory]
        
        private lazy var topicsDataSource: [TopicViewModel] = [] {
            didSet {
                topicCollectionView.reloadData()
            }
        }
        
        override var screenName: Logger.Screen.Node.Start {
            return .home
        }
        
        override var isHidesBottomBarWhenPushed: Bool {
            return false
        }
        
        override var contentScrollView: UIScrollView? {
            topicCollectionView
        }
        
        //MARK: - inherited
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
            setupEvent()
        }
        
    }
    
}

extension AmongChat.Home.TopicsViewController {
    
    private func updateTopics(_ dataSource: [TopicViewModel]) {
        var topicList = dataSource
        var sortedList = previousEnterHistory.map { topicId -> TopicViewModel? in
            let item = topicList.first(where: { $0.topic.topicId == topicId })
            topicList.removeFirst(where: { $0.topic.topicId == topicId })
            return item
        }
        .compactMap { $0 }
        sortedList.append(contentsOf: topicList)
        topicsDataSource = sortedList
    }
    
    private func onTap(_ topic: TopicViewModel) {
        //record
        var array = enterTopicHistory
        let topicId = topic.topic.topicId
        array.removeAll(topicId)
        array.insert(topicId, at: 0)
        enterTopicHistory = array
    }
    
    // MARK: -
    
    private func setupLayout() {
                
        view.addSubviews(views: navigationView, topicCollectionView)
        
        navigationView.snp.makeConstraints { (maker) in
            maker.top.left.right.equalToSuperview()
            maker.height.equalTo(49 + Frame.Height.safeAeraTopHeight)
        }
        
        topicCollectionView.snp.makeConstraints { (maker) in
            maker.top.equalTo(navigationView.snp.bottom)
            maker.left.right.equalToSuperview()
            maker.bottom.equalToSuperview()
        }
        
    }
    
    private func setupEvent() {
        //cache
        updateTopics(Settings.shared.amongChatHomeSummary.value?.topicList.map({ TopicViewModel(with: $0) }) ?? [])
        
        Observable.combineLatest(
            Observable<Bool>.merge(
                rx.viewWillAppear.map({ _ in true }),
                rx.viewDidDisappear.map({ _ in false })
            ),
            Observable<Void>.merge(
                rx.viewWillAppear.map({ _ in }),
                NotificationCenter.default.rx.notification(UIApplication.didBecomeActiveNotification).map({ _ in })
            )
        )
            .filter({ visible, _ in
                return visible
            })
            .throttle(.seconds(30), scheduler: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] (_) in
                self?.fetchSummaryData()
            })
            .disposed(by: bag)
                
//        rx.viewWillAppear
//            .subscribe(onNext: { [weak self] (_) in
//                self?.topicCollectionView.setContentOffset(.zero, animated: false)
//            })
//            .disposed(by: bag)
    }
    
    private func fetchSummaryData() {
        var hudRemoval: Raft.RemoveBlock? = nil
        if topicsDataSource.count == 0 {
           hudRemoval = view.raft.show(.loading, userInteractionEnabled: false)
        }
        
        Request.summary()
            .do(onDispose: {
                hudRemoval?()
            })
            .subscribe(onSuccess: { [weak self] (summary) in
                
                guard let s = summary else {
                    return
                }
                
                self?.updateTopics(s.topicList.map({ TopicViewModel(with: $0) }))
                
            }, onError: { [weak self] (error) in
                guard self?.topicsDataSource.count == 0 else {
                    return
                }
                let v = AmongChat.Home.LoadErrorView()
                self?.view.addSubview(v)
                v.snp.makeConstraints { (maker) in
                    maker.edges.equalToSuperview()
                }
                v.showUp { [weak self, weak v] in
                    v?.removeFromSuperview()
                    self?.fetchSummaryData()
                }
                
                cdPrint("")
            })
            .disposed(by: bag)
    }
}

extension AmongChat.Home.TopicsViewController: UICollectionViewDataSource {

    // MARK: - UICollectionView

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return topicsDataSource.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(TopicCell.self), for: indexPath)
        if let cell = cell as? TopicCell,
           let topic = topicsDataSource.safe(indexPath.item) {
            cell.bindViewModel(topic)
        }
        return cell
    }

}

extension AmongChat.Home.TopicsViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let topic = topicsDataSource.safe(indexPath.item) {
//            enterRoom(roomId: "hdtt7bgi", topicId: nil,/* topic.topic.topicId,*/ logSource: .matchSource)
            enterRoom(roomId: nil, topicId: topic.topic.topicId, logSource: .matchSource)
            onTap(topic)
        }
    }
    
}

extension UIViewController {
    func showKickedAlert(with role: ChatRoom.KickOutMessage.Role) {
        showAmongAlert(title: role.alertTitle, message: nil, cancelTitle: nil, confirmTitle: R.string.localizable.alertOk())
    }
}
