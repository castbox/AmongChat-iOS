//
//  Feed.ListViewController.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 25/05/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import SnapKit
import AVFoundation
import RxSwift

import Alamofire
import MBProgressHUD

extension Feed {
    
    enum ListStyle {
        case recommend
        case profile
    }
    
    class DataPlaceholder: NSObject {
        enum PlaceholderType {
            case ad
//            case followIns
//            case premium
//            case promotion
        }
        let type: PlaceholderType
        
        init(type: PlaceholderType) {
            self.type = type
            super.init()
        }
    }
    
    class ListViewController: WalkieTalkie.ViewController {
        
        typealias NetworkConnectionType = NetworkReachabilityManager.NetworkReachabilityStatus.ConnectionType
        
        typealias FeedCellViewModel = Feed.ListCellViewModel
        
        var tableView: UITableView!
        
        lazy var viewModel = Feed.ListViewModel()
        
        private let videoEditor = VideoEditor()
        
        var feedHeight: CGFloat = 0
        
        //feeds
        var feedsDataSource: [Feed.ListCellViewModel] = [] {
            didSet {
                buildDataSourceModels()
            }
        }
        
        var dataSource: [Any] = []
        
        var currentIndex = 0 {
            didSet {
                /*
                 * refresh ad when an ad is being slided
                 */
                let old = dataSource.safe(oldValue)
                let new = dataSource.safe(currentIndex)
                
                switch (old, new) {
                case (let placeholder as DataPlaceholder, _ as FeedCellViewModel):
                    switch placeholder.type {
                    case .ad:
                        loadNativeAdIfCould()
                    default:
                        break
                    }
                    
                default:
                    break
                }
                
            }
        }
        
        var listStyle: ListStyle = .recommend
        
        private var shouldAutoPauseWhenDismiss: Bool = true
        private var scrollDisposeBag: Disposable?
        private var previousNetworkType: NetworkConnectionType?
        private var isViewAppear: Bool = false
        
        private var adPositionInterval: Int = 4
        private var adView: UIView? {
            didSet {
                switch (oldValue, adView) {
                case (.none, .some(_)):
                    //
                    let oldIndex = dataSource.count
                    let adIndexs = buildDataSourceModels()
                        .map { IndexPath(row: $0, section: 0) }
                    if oldIndex < dataSource.count {
                        //新插入
                        tableView.beginUpdates()
                        tableView.insertRows(at: adIndexs, with: .none)
                        tableView.endUpdates()
                    } else {
                        tableView.reloadData()
                        replayVisibleItem(false)
                    }
                case (.some(_), .some(_)):
                    if let _ = tableView.cellForRow(at: IndexPath(item: currentIndex, section: 0)) as? FeedNativeAdCell {
                        self.tableView.reloadRows(at: [IndexPath(item: currentIndex, section: 0)], with: .none)
                    }
                default:
                    break
                }
            }
        }
        
        @discardableResult
        private func buildDataSourceModels() -> [Int] {
            dataSource.removeAll()
            var adPlaceholderIndex: [Int] = []
            if ableToShowAd {
                let adPlaceholder = DataPlaceholder(type: .ad)
                feedsDataSource.enumerated().forEach { (idx, ele) in
                    if idx > currentIndex,
                        idx % adPositionInterval == 0 {
                        dataSource.append(adPlaceholder)
                        adPlaceholderIndex.append(idx)
                    }
                    dataSource.append(ele)
                }
            } else {
                dataSource.append(contentsOf: feedsDataSource)
            }
            return adPlaceholderIndex
        }
        
        private var ableToShowAd: Bool {
            return Ad.shouldShow() && adView != nil
        }
        
//        private var cellBeginShowTime: TimeInterval = 0
        private var cellBeginShowTimeMap: [Int: TimeInterval] = [:]
        
        var updateFeedForAction: ((_ action: AmongSheetController.ItemType, _ feed: Entity.Feed) -> Void)? = nil
        
        // MARK: - Lifecycles
        override func viewDidLoad() {
            super.viewDidLoad()
            
            configureSubview()
            bindSubviewEvent()
            
        }
                
        func onViewWillAppear() {
            shouldAutoPauseWhenDismiss = true
            isViewAppear = true
            if dataSource.isEmpty {
                loadData()
            }
        }
        
        func onViewDidAppear() {
            loadNativeAdIfCould()
            guard UIApplication.topViewController() == self,
                  isViewAppear else {
                return
            }
            autoPlayVisibleVideoIfCould()
        }
        
        func onViewWillDisappear() {
            isViewAppear = false
            guard shouldAutoPauseWhenDismiss else {
                return
            }
            autoPauseVisibleVideoIfCould()
        }
        
        func autoPlayVisibleVideoIfCould() {
            if !feedsDataSource.isEmpty,
               let cell = tableView.visibleCells.first as? FeedListCell,
               !cell.isUserPaused {
                cell.play()
            }
        }
        
        func autoPauseVisibleVideoIfCould() {
            if let cell = tableView.visibleCells.first as? FeedListCell,
               !cell.isUserPaused {
                cell.pause()
            }
        }
        
        func loadData() {
            
        }
        
        func loadMore() {
            
        }
        
        func replayVisibleItem(_ replay: Bool = true) {
            guard isViewAppear else {
                return
            }
            if let cell = tableView.cellForRow(at: IndexPath(row: currentIndex, section: 0)) as? FeedListCell {
                if replay {
                    cell.replay()
                } else {
                    cell.play()
                }
                viewModel.reportPlay(cell.viewModel?.feed.pid)
            } else {
                if let cell = tableView.visibleCells.first as? FeedListCell {
                    if replay {
                        cell.replay()
                    } else {
                        cell.play()
                    }
                    viewModel.reportPlay(cell.viewModel?.feed.pid)
                }
            }
        }
        
        func bindSubviewEvent() {
            rx.viewWillAppear.asObservable()
                .subscribe(onNext: { [weak self] _ in
                    self?.onViewWillAppear()
                })
                .disposed(by: bag)
            
            Observable.merge(rx.viewDidAppear.asObservable(),
                             NotificationCenter.default.rx.notification(UIApplication.didBecomeActiveNotification)
                                .map { _ in })
                .observeOn(MainScheduler.asyncInstance)
                .subscribe(onNext: { [weak self] _ in
                    self?.onViewDidAppear()
                })
                .disposed(by: bag)
            
            Observable.merge(rx.viewWillDisappear.asObservable(),
                             NotificationCenter.default.rx.notification(UIApplication.willResignActiveNotification)
                                .map { _ in })
                .observeOn(MainScheduler.asyncInstance)
                .subscribe(onNext: { [weak self] _ in
                    self?.onViewWillDisappear()
                })
                .disposed(by: bag)
            
            NetworkReachabilityManager.default?.startListening(onUpdatePerforming: { [weak self] status in
                switch status {
                case .unknown:
                    self?.previousNetworkType = nil
                /// The network is not reachable.
                case .notReachable:
                    self?.previousNetworkType = nil
                /// The network is reachable on the associated `ConnectionType`.
                case .reachable(let type):
                    switch type {
                    case .cellular:
                        if self?.previousNetworkType == nil || self?.previousNetworkType == .ethernetOrWiFi {
                            self?.view.raft.autoShow(.text(R.string.localizable.feedPlayNoWifiTips()), interval: 3)
                        }
                    case .ethernetOrWiFi:
                        ()
                    }
                    self?.previousNetworkType = type
                    cdPrint("NetworkReachabilityManager reachable type: \(type)")
                }
            })
            
            Ad.NativeManager.shared.adViewObservable()
                .asDriver(onErrorJustReturn: nil)
                .drive(onNext: { [weak self] (adView) in
                    guard let `self` = self,
                        Settings.shared.isProValue.value == false,
                        let adView = adView else { return }
                    self.adView = adView
                })
                .disposed(by: bag)
            
            Settings.shared.isProValue.replay()
                .asDriver(onErrorJustReturn: false)
                .distinctUntilChanged()
                .skip(1)
                .drive(onNext: { [weak self] (_) in
                    self?.buildDataSourceModels()
                    self?.tableView.reloadData()
                })
                .disposed(by: bag)
        }
        
        
        func configureSubview() {
            
            tableView = UITableView()
            tableView.backgroundColor = .clear
            tableView.tableFooterView = UIView()
            tableView.isPagingEnabled = true
            if #available(iOS 11.0, *) {
                tableView.contentInsetAdjustmentBehavior = .never
            }
            tableView.showsVerticalScrollIndicator = false
            tableView.separatorStyle = .none
            tableView.register(nibWithCellClass: FeedListCell.self)
            tableView.register(nibWithCellClass: FeedNativeAdCell.self)
            tableView.delegate = self
            tableView.dataSource = self
            tableView.estimatedRowHeight = feedHeight
            tableView.estimatedSectionHeaderHeight = 0
            tableView.estimatedSectionFooterHeight = 0
            view.addSubviews(views: tableView)
            
            tableView.snp.makeConstraints { maker in
                maker.top.leading.trailing.equalToSuperview()
                maker.bottom.equalTo(-Frame.Height.bottomBar)
            }
        }
        
    }
}

// MARK: - Table View Extensions
extension Feed.ListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        let item = dataSource.safe(indexPath.row)
        if let _ = item as? Feed.DataPlaceholder {
            let adCell = tableView.dequeueReusableCell(withClass: FeedNativeAdCell.self, for: indexPath)
            adCell.adView = adView
            if let viewModel = dataSource.safe(indexPath.row - 1) as? Feed.ListCellViewModel {
                let emotes = viewModel.emotes.map({
                    return Entity.FeedEmote(id: $0.id, count: $0.count, isVoted: $0.isVoted, img: $0.img, url: $0.url, width: $0.width)
                })
                adCell.updateEmotes(with: emotes)
                adCell.actionHandler = { [weak adCell] action in
                    
                    switch action {
                    case .selectEmote(let emote):
                        Logger.Action.log(.feeds_nad_emote_clk)
                        
                        emote.isVoted = !emote.isVoted
                        
                        emote.count = emote.isVoted ? emote.count + 1 : emote.count - 1
                        
                        var variableEmotes = emotes
                        
                        if let idx = variableEmotes.firstIndex(where: { $0.id == emote.id }) {
                            variableEmotes[idx] = emote
                        }
                        
                        variableEmotes.removeAll { $0.count <= 0 }
                        
                        adCell?.updateEmotes(with: variableEmotes)
                        
                    default:
                        ()
                    }
                    
                }
            }
            Ad.NativeManager.shared.didShow(adView: adView, in: self) {
                //
            }
            cell = adCell
        } else {
            let feedCell = tableView.dequeueReusableCell(withClass: FeedListCell.self, for: indexPath)
            cdPrint("tableView cellForRowAt index: \(indexPath.row)")
            if let viewModel = item as? Feed.ListCellViewModel {
                feedCell.config(with: viewModel, listStyle: listStyle)
                feedCell.actionHandler = { [weak self] action in
                    self?.onCell(action: action, viewModel: viewModel)
                }
            }
            cell = feedCell
        }
        if indexPath.item > 0,
            indexPath.item % adPositionInterval == 0 {
            loadNativeAdIfCould()
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return feedHeight
    }
    
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // If the cell is the first cell in the tableview, the queuePlayer automatically starts.
        // If the cell will be displayed, pause the video until the drag on the scroll view is ended
        cdPrint("tableView willDisplay row: \(indexPath.row)")
        //记录展示时间
        cellBeginShowTimeMap[indexPath.row] = Date().timeIntervalSince1970
        
        if let cell = cell as? FeedListCell {
            if currentIndex != -1 {
                cell.pause()
            }
        } else if cell is FeedNativeAdCell {
            Logger.Action.log(.feeds_nad_show)
        }
        currentIndex = indexPath.row
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Pause the video if the cell is ended displaying
        cdPrint("tableView didEndDisplaying row: \(indexPath.row)")
        let cellBeginShowTime = cellBeginShowTimeMap[indexPath.row] ?? Date().timeIntervalSince1970
        let cellShowTime = Date().timeIntervalSince1970 - cellBeginShowTime
        let showTimeValue = cellShowTime * 10
        
        if let cell = cell as? FeedListCell {
            cell.pause()
            //report
            let viewModel = dataSource.safe(indexPath.row) as? Feed.ListCellViewModel
            Logger.Action.log(.feeds_play_finish_progress, category: nil, viewModel?.feed.pid, lroundf(cell.playProgress * 10))
            Logger.Action.log(.feeds_hide, category: nil, viewModel?.feed.pid, min(6000, showTimeValue.int))
        } else if cell is FeedNativeAdCell {
            Logger.Action.log(.feeds_nad_hide, category: nil, nil, min(6000, showTimeValue.int))
        }
        cellBeginShowTimeMap.removeValue(forKey: indexPath.row)
    }
}

extension Feed.ListViewController: UIScrollViewDelegate {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        replayVisibleItem()
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        
    }
}


extension Feed.ListViewController {
    func loadNativeAdIfCould() {
        adPositionInterval = FireRemote.shared.value.feedsAdInterval
        if adPositionInterval == 0 {
            adPositionInterval = 1
        }
        guard adPositionInterval > 1 else {
            return
        }
    }
    
    func removeAllAd(at placeholder: Feed.DataPlaceholder) {
        let nilableIndex = self.dataSource.firstIndex(where: { item in
            guard let item = item as? Feed.DataPlaceholder else {
                return false
            }
            return item.isEqual(placeholder)
        })
        guard let index = nilableIndex else {
            return
        }
        let indexPath = IndexPath(row: index, section: 0)
        dataSource = dataSource.filter { $0 is FeedCellViewModel }
        self.tableView.reloadData { [weak self] in
            let newCell = self?.tableView.cellForRow(at: indexPath) as? FeedListCell
            newCell?.play()
        }
//        if currentIndex >= dataSource.count {
//            currentIndex = dataSource.count - 1
//        }
//        replayVisibleItem(false)
    }
    
    func updateEmoteState(with pid: String, emoteId: String, isSelect: Bool, index: Int)  {
        
        updateCellEmote(with: emoteId, isSelect: isSelect, index: index)

        let resultSingle: Single<Bool>
        if isSelect {
            resultSingle = Request.feedSelectEmote(pid, emoteId: emoteId)
        } else {
            resultSingle = Request.feedUnselectEmote(pid, emoteId: emoteId)
        }

        resultSingle
            .subscribe()
            .disposed(by: bag)
    }
    
    func updateCellEmote(with emoteId: String, isSelect: Bool, index: Int) {
        guard let viewModel = self.dataSource.safe(index) as? FeedCellViewModel else {
            return
        }
        viewModel.updateEmoteState(emoteId: emoteId, isSelect: isSelect)
        let cell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? FeedListCell
        cell?.updateEmotes(with: viewModel)
        if isSelect {
            cell?.show(emote: viewModel.emotes.first(where: { $0.id == emoteId }))
        }
    }
    
    func onShareSuccess(with viewModel: Feed.ListCellViewModel) {
        viewModel.feed.shareCount = viewModel.feed.shareCountValue + 1
        self.viewModel.reportShare(viewModel.feed.pid)
        
        guard let index = dataSourceIndex(for: viewModel) else {
            return
        }
        let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? FeedListCell
        cell?.updateShareCount()
    }
    
    func showShareView(with viewModel: Feed.ListCellViewModel?) {
        guard let viewModel = viewModel else {
            return
        }
        let feedShare = Feed.ShareController(with: viewModel.feed)
        feedShare.showModal(in: self.tabBarController ?? self)
        feedShare.dismissHandler = { [weak self] action in
            switch action {
            case .error(let string):
                guard let string = string,
                      !string.isEmpty else {
                    self?.view.raft.autoShow(.text(R.string.localizable.feedShareSent()))
                    self?.onShareSuccess(with: viewModel)
                    return
                }
                self?.view.raft.autoShow(.text(string))
            case .share(let source):
                self?.onShareBar(select: source, viewModel: viewModel)
            case .moreSelectUser(let users):
                self?.onShareToMessages(with: viewModel, users: users)
            }
        }
    }
    
    func onShareToMessages(with viewModel: Feed.ListCellViewModel, users: [Entity.UserProfile]) {
        AmongChat.Login.doLogedInEvent(style: .authNeeded(source: .chat)) { [weak self] in
            let selectVC = Feed.Share.SelectFriendsViewController(with: viewModel.feed, initialSelected: users)
            selectVC.modalPresentationStyle = .fullScreen
            self?.present(selectVC, animated: true)
            selectVC.didSharedCallback = { [weak self] result in
                switch result {
                case .success(_):
                    self?.view.raft.autoShow(.text(R.string.localizable.feedShareSent()))
                    self?.onShareSuccess(with: viewModel)
                    Logger.Action.log(.feeds_share_sent, categoryValue: "", viewModel.feed.pid)
                case .failure(let error):
                    self?.view.raft.autoShow(.text(error.localizedDescription))
                }
            }
        }
    }
    
    func onShareBar(select item: Feed.ShareBar.ShareSource, viewModel: Feed.ListCellViewModel) {
        
        let feed = viewModel.feed
        let shareUrl = "https://among.chat/feeds/\(feed.pid)"

        if item == .message {
            onShareToMessages(with: viewModel, users: [])
        } else if item == .more {
            //make dynamic
            let removeHandler = view.raft.show(.loading)
            
            let content = ShareManager.Content(type: .feed, targetType: .more, content: R.string.localizable.feedThirdShareContent(""), url: shareUrl)
            ShareManager.default.share(with: content, .more, viewController: self) { [weak self] in
                removeHandler()
                self?.onShareSuccess(with: viewModel)
            }
        } else {
            let removeHandler = view.raft.show(.loading)
            ShareManager.makeDynamicLinks(with: shareUrl, for: .message) { [weak self] dynamicUrl in
                removeHandler()
                guard let url = dynamicUrl else { return }
                let shareText = R.string.localizable.feedThirdShareContent(url)
                switch item {
                case .sms:
                    self?.sendSMS(body: shareText)
                    self?.onShareSuccess(with: viewModel)
                case .copyLink:
                    shareText.copyToPasteboardWithHaptic()
                    self?.onShareSuccess(with: viewModel)
                default:
                    ()
                }
            }
        }
    }
    
    func showCommentList(with feedId: String, commentsInfo: Entity.FeedRedirectInfo.CommentsInfo? = nil, count: Int) {
        shouldAutoPauseWhenDismiss = false
        let commentList = Feed.Comments.CommentsListViewController(with: feedId, commentsInfo: commentsInfo, commentsCount: count)
        commentList.commentsCountObservable
            .subscribe(onNext: { [weak self] (count) in
                //TODO: update comment count
                guard let `self` = self else { return }
                let nilableIndex = self.dataSource.firstIndex(where: { item in
                    guard let item = item as? FeedCellViewModel else {
                        return false
                    }
                    return item.feed.pid == feedId
                })
                guard let index = nilableIndex, let viewModel = self.dataSource[index] as? FeedCellViewModel else {
                    return
                }
                viewModel.updateCommentCount(count)
                let cell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? FeedListCell
                cell?.updateCommentCount()
            })
            .disposed(by: bag)
        let nav = NavigationViewController(rootViewController: commentList)
        nav.modalPresentationStyle = .overCurrentContext
        topController()?.present(nav, animated: true)
        
        commentList.rx.dismiss
            .subscribe(onNext: { [weak self] result in
                guard let `self` = self else { return }
                self.onViewWillAppear()
            })
            .disposed(by: commentList.bag)
        
        Observable.merge(nav.rx.popViewController.map { true },
                         nav.rx.pushViewController.map { false })
            .subscribe(onNext: { [weak self, weak nav] result in
                guard let `self` = self, let nav = nav else { return }
                if result, nav.viewControllers.count == 1 {
                    //play
                    self.autoPlayVisibleVideoIfCould()
                } else {
                    self.autoPauseVisibleVideoIfCould()
                }
                cdPrint("self.isVisible: \(self.isVisible)")
            })
            .disposed(by: commentList.bag)

    }

    func onCell(action: FeedListCell.Action, viewModel: Feed.ListCellViewModel?) {
        let nilableIndex = dataSource.firstIndex(where: { item in
            guard let item = item as? FeedCellViewModel else {
                return false
            }
            return item.isEqual(viewModel)
        })
        guard let viewModel = viewModel, let index = nilableIndex else {
            return
        }
        let indexPath = IndexPath(row: index, section: 0)
        switch action {
        case .selectEmote(let emote):
            HapticFeedback.Impact.light()
            
            if emote.id.isEmpty {
                let vc = Feed.EmotePickerController(Feed.EmotePickerViewModel())
                vc.didSelectItemHandler = { [weak self] emote in
                    //didn't contains voted
                    guard let `self` = self else {
                        return
                    }
                    HapticFeedback.Impact.light()
                    Logger.Action.log(.feeds_item_clk, category: .emotes, emote.id)
                    AmongChat.Login.doLogedInEvent(style: .authNeeded(source: .emote)) { [weak self] in
                        guard let `self` = self else { return }
                        if !viewModel.emotes.contains(where: { $0.id == emote.id && $0.isVoted == true }) {
                            self.updateEmoteState(with: viewModel.feed.pid, emoteId: emote.id, isSelect: true, index: indexPath.row)
                        } else {
                            let cell = self.tableView.cellForRow(at: indexPath) as? FeedListCell
                            cell?.show(emote: viewModel.emotes.first(where: { $0.id == emote.id }))
                        }
                    }
                }
                vc.showModal(in: topController())
            } else {
                Logger.Action.log(.feeds_item_clk, category: .emotes, emote.id)
                AmongChat.Login.doLogedInEvent(style: .authNeeded(source: .emote)) { [weak self] in
                    guard let `self` = self else { return }
                    
                    self.updateEmoteState(with: viewModel.feed.pid, emoteId: emote.id, isSelect: !emote.isVoted, index: indexPath.row)
                }
            }
        case .playComplete:
            self.viewModel.reportPlayFinish(viewModel.feed.pid)
            
        case .comment:
            Logger.Action.log(.feeds_item_clk, category: .comments, viewModel.feed.pid)
            self.showCommentList(with: viewModel.feed.pid, commentsInfo: nil, count: viewModel.feed.cmtCount)
        case .share:
            HapticFeedback.Impact.light()
            showShareView(with: viewModel)
            
        case .userProfile(let uid):
            guard Settings.loginUserId != uid else {
                return
            }
            let vc = Social.ProfileViewController(with: uid)
            vc.followedHandle = { [weak self] (followed) in
                viewModel.feed.user.isFollowed = followed
                self?.tableView.reloadRows(at: [indexPath], with: .none)
            }
            navigationController?.pushViewController(vc)
            
        case .more:
            let types: [AmongSheetController.ItemType]
            if Settings.loginUserId == viewModel.feed.uid {
                types = [.share, .deleteVideo, .cancel]
            } else {
                types = [.share, .notInterested, .report, .cancel]
            }
            AmongSheetController.show(items: types, in: self.tabBarController ?? self) { [weak self] item in
                self?.onSheet(action: item, viewModel: viewModel)
            }
            
        case .follow(let callback):
            Logger.Action.log(.feeds_item_clk, category: .follow, viewModel.feed.pid)
            
            Request.follow(uid: viewModel.feed.user.uid, type: "follow")
                .do(onSuccess: { success in
                    guard success else { return }
                    viewModel.feed.user.isFollowed = true
                })
                .subscribe(onSuccess: callback)
                .disposed(by: bag)
            
        case .hashTag:
            Logger.Action.log(.feeds_item_topic_clk, categoryValue: viewModel.feed.topicName, viewModel.feed.pid)
            
            let vc = Feed.HashtagFeedListViewController(with: viewModel.feed)
            navigationController?.pushViewController(vc)
        }
    }
        
    func onSheet(action: AmongSheetController.ItemType, viewModel: Feed.ListCellViewModel?) {
        
        guard let viewModel = viewModel, let index = dataSourceIndex(for: viewModel) else {
            return
        }
        
        let indexPath = IndexPath(row: index, section: 0)
        
        switch action {
        case .share:
            showShareView(with: viewModel)
        case .notInterested:
            Logger.Action.log(.feeds_item_clk, category: .not_intereasted, viewModel.feed.pid)
            //pause
            
            let cell = self.tableView.cellForRow(at: indexPath) as? FeedListCell
            cell?.pause()
            
            deleteRow(at: viewModel)
            HapticFeedback.Impact.success()
            
            self.viewModel.reportNotIntereasted(viewModel.feed.pid)
                .subscribe()
                .disposed(by: self.bag)
        case .deleteVideo:
            Logger.Action.log(.feeds_item_clk, category: .delete, viewModel.feed.pid)
            let cell = self.tableView.cellForRow(at: indexPath) as? FeedListCell
            cell?.pause()
            let removeHandler = self.view.raft.show(.loading, hideAnimated: false)
            self.viewModel.feedDelete(viewModel.feed.pid)
                .subscribe(onSuccess: { [weak self] result in
                    removeHandler()
                    self?.deleteRow(at: viewModel)
                    //TODO: - delete update
                    self?.updateFeedForAction?(action, viewModel.feed)
                    HapticFeedback.Impact.success()
                }) { error in
                    removeHandler()
                }
                .disposed(by: self.bag)
        case .report:
            Logger.Action.log(.feeds_item_clk, category: .report, viewModel.feed.pid)
            
            Report.ViewController.showReport(on: self, uid: viewModel.feed.pid, type: .post, roomId: "") { [weak self] in
                self?.view.raft.autoShow(.text(R.string.localizable.reportSuccess()))
            }
        default:
            ()
        }
    }
    
    func dataSourceIndex(for viewModel: Feed.ListCellViewModel) -> Int? {
        return self.dataSource.firstIndex(where: { item in
            guard let item = item as? FeedCellViewModel else {
                return false
            }
            return item.isEqual(viewModel)
        })
    }
    
    func deleteRow(at viewModel: Feed.ListCellViewModel?) {
        
        guard let viewModel = viewModel, let index = dataSourceIndex(for: viewModel) else {
            return
        }
        let indexPath = IndexPath(row: index, section: 0)
        //        let nextIndex = IndexPath(row: indexPath.row + 1, section: 0)
        //        if nextIndex.row < dataSource.count - 1 {
        //            scrollDisposeBag?.dispose()
        //            scrollDisposeBag = self.rx.methodInvoked(#selector(self.scrollViewDidEndScrollingAnimation(_:)))
        //                .subscribe(onNext: { [weak self] _ in
        //                    guard let `self` = self else { return }
        //                    //                    cell?.backgroundColor = .red
        //                    //                    cell?.alpha = 0
        //                    cdPrint("tableView will delete row: \(indexPath.row)")
        ////                    let nextCell = self.tableView.cellForRow(at: nextIndex) as? FeedListCell
        ////                    nextCell?.play()
        //                    var dataSource = self.dataSource
        //                    dataSource.remove(at: indexPath.row)
        //                    self.dataSource = dataSource
        //                    if 1 == 1 {
        //                        self.tableView.reloadData { [weak self] in
        //                            let newCell = self?.tableView.cellForRow(at: indexPath) as? FeedListCell
        //                            newCell?.play()
        //                        }
        //                    } else {
        //                        self.tableView.beginUpdates()
        //                        self.tableView.deleteRows(at: [indexPath], with: .none)
        //                        self.tableView.endUpdates()
        //                        UIView.performWithoutAnimation {
        //                            self.tableView.layoutIfNeeded()
        //                        }
        //                    }
        //                    //                    self.tableView.layer.removeAllAnimations()
        //                    cdPrint("tableView did delete row: \(indexPath.row)")
        //                    self.scrollDisposeBag?.dispose()
        //                })
        //            scrollDisposeBag?.disposed(by: self.bag)
        //            cdPrint("tableView scroll to row: \(nextIndex.row)")
        //            tableView.scrollToRow(at: nextIndex, at: .top, animated: true)
        //        } else {
        
        
        feedsDataSource = feedsDataSource.filter { item in
            guard let item = item as? FeedCellViewModel else {
                return false
            }
            return item.feed.pid != viewModel.feed.pid
        }
        
        self.tableView.reloadData { [weak self] in
            let newCell = self?.tableView.cellForRow(at: indexPath) as? FeedListCell
            newCell?.play()
        }
        if dataSource.isEmpty {
            if listStyle == .profile {
                navigationController?.popViewController()
            } else {
                loadData()
            }
        }
        //        }
        
    }
    
    func topController() -> UIViewController? {
        return tabBarController ?? self
    }
}
