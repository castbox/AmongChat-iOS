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
import VIMediaCache
import Alamofire
import MBProgressHUD

extension Feed {
    
    enum ListStyle {
        case recommend
        case profile
    }
    
    class ListViewController: WalkieTalkie.ViewController {
        
        typealias NetworkConnectionType = NetworkReachabilityManager.NetworkReachabilityStatus.ConnectionType
        
        var tableView: UITableView!
        
        lazy var viewModel = Feed.ListViewModel()
        
        private let videoEditor = VideoEditor()
        
        var feedHeight: CGFloat = 0
        
        var dataSource: [Feed.ListCellViewModel] = []
        
        var currentIndex = 0
        
        var listStyle: ListStyle = .recommend
        
        private var shouldAutoPauseWhenDismiss: Bool = true
        private var scrollDisposeBag: Disposable?
        private var previousNetworkType: NetworkConnectionType?
        // MARK: - Lifecycles
        override func viewDidLoad() {
            super.viewDidLoad()
            
            configureSubview()
            bindSubviewEvent()
        }
                
        func onViewWillAppear() {
            shouldAutoPauseWhenDismiss = true
            
            if dataSource.isEmpty {
                loadData()
            }
        }
        
        func onViewDidAppear() {
            guard UIApplication.topViewController() == self else {
                return
            }
            autoPlayVisibleVideoIfCould()
        }
        
        func onViewWillDisappear() {
            guard shouldAutoPauseWhenDismiss else {
                return
            }
            autoPauseVisibleVideoIfCould()
//            if shouldAutoPauseWhenDismiss,
//               let cell = tableView.visibleCells.first as? FeedListCell,
//               !cell.isUserPaused {
//                cell.pause()
//            }
        }
        
        func autoPlayVisibleVideoIfCould() {
            if !dataSource.isEmpty,
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
        
        func replayVisibleItem() {
            guard isVisible else {
                return
            }
            if let cell = tableView.cellForRow(at: IndexPath(row: currentIndex, section: 0)) as? FeedListCell {
                cell.replay()
                viewModel.reportPlay(cell.viewModel?.feed.pid)
            } else {
                if let cell = tableView.visibleCells.first as? FeedListCell {
                    cell.replay()
                    viewModel.reportPlay(cell.viewModel?.feed.pid)
                }
            }
        }
        func bindSubviewEvent() {
            SZAVPlayerCache.shared.setup(maxCacheSize: 100)

            Observable.merge(rx.viewWillAppear.asObservable(),
                             Settings.shared.loginResult.replay().map { _ in })
                .debounce(.seconds(1), scheduler: MainScheduler.asyncInstance)
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
        let cell = tableView.dequeueReusableCell(withClass: FeedListCell.self, for: indexPath)
        cdPrint("tableView cellForRowAt index: \(indexPath.row)")

        let viewModel = dataSource.safe(indexPath.row)
        cell.config(with: viewModel, listStyle: listStyle)
        cell.actionHandler = { [weak self] action in
            self?.onCell(action: action, viewModel: viewModel)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return feedHeight
    }
    
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // If the cell is the first cell in the tableview, the queuePlayer automatically starts.
        // If the cell will be displayed, pause the video until the drag on the scroll view is ended
//        cdPrint("tableView willDisplay row: \(indexPath.row)")
        if let cell = cell as? FeedListCell {
            if currentIndex != -1 {
                cell.pause()
            }
            currentIndex = indexPath.row
        }
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Pause the video if the cell is ended displaying
//        cdPrint("tableView didEndDisplaying row: \(indexPath.row)")
        if let cell = cell as? FeedListCell {
            cell.pause()
            //report
            let viewModel = dataSource.safe(indexPath.row)
            Logger.Action.log(.feeds_play_finish_progress, category: nil, viewModel?.feed.pid, lroundf(cell.playProgress * 10))
        }
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
        guard let viewModel = self.dataSource.safe(index) else {
            return
        }
        viewModel.updateEmoteState(emoteId: emoteId, isSelect: isSelect)
        let cell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? FeedListCell
        cell?.updateEmotes(with: viewModel)
        if isSelect {
            cell?.show(emote: viewModel.emotes.first(where: { $0.id == emoteId }))
        }
    }
    
    func increaseShareCount(with index: Int) {
        guard let viewModel = self.dataSource.safe(index) else {
            return
        }
        viewModel.feed.shareCount = viewModel.feed.shareCountValue + 1
        let cell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? FeedListCell
        cell?.updateShareCount()
    }
    
    func downloadVideo(viewModel: Feed.ListCellViewModel?) {
        guard let viewModel = viewModel else {
            return
        }
        let feed = viewModel.feed
        let hudHandler = view.raft.show(.loading)
//        let hud = view.raft.topHud()
//        hud?.mode = .annularDeterminate
//        hud?.label.text = "Loading"
//        hud?.progress = 0
        self.viewModel.download(fileUrl: feed.url.absoluteString) { [weak self] progress in
//            hud?.progress = progress.float
            cdPrint("progress: \(progress)")
        } completionHandler: { [weak self] fileUrl in
            hudHandler()
            guard let `self` = self, let url = fileUrl else {
                return
            }
            self.share(viewModel: viewModel, fileUrl: url)
        }

    }
    
    func share(viewModel: Feed.ListCellViewModel, fileUrl: URL) {
        guard let index = dataSource.firstIndex(where: { $0.isEqual(viewModel) }) else {
            FileManager.removefile(filePath: fileUrl.path)
            return
        }
        let feed = viewModel.feed
        Logger.Action.log(.feeds_item_clk, category: .share, feed.pid)
        let tagImageView = VideoShareTagView(with: feed.user.name ?? feed.user.uid.string)
        view.addSubview(tagImageView)
        guard let tagImage = tagImageView.screenshot else {
            tagImageView.removeFromSuperview()
            FileManager.removefile(filePath: fileUrl.path)
            return
        }
        tagImageView.removeFromSuperview()
    
        let removeHandler = view.raft.show(.loading)
        videoEditor.addTag(image: tagImage, for: fileUrl) { [weak self] url in
            FileManager.removefile(filePath: fileUrl.path)
            removeHandler()
            guard let `self` = self, let url = url else {
                return
            }
            cdPrint("url: \(url)")
            ShareManager.default.showActivity(items: [url], viewController: self) { [weak self] in
                self?.increaseShareCount(with: index)
                self?.viewModel.reportShare(feed.pid)
                //cancel or finish, remove
                do {
                    try FileManager.default.removeItem(at: url)
                } catch {
                    cdPrint("FileManager.default.removeItem: \(error)")
                }
            }
        }
    }
    
//    func share(viewModel: Feed.ListCellViewModel?) {
//        guard let viewModel = viewModel, let index = dataSource.firstIndex(where: { $0.isEqual(viewModel) }) else {
//            return
//        }
//        let feed = viewModel.feed
//        //get tag imge
//        let uniqueId = SZAVPlayerFileSystem.uniqueID(url: feed.url)
//        guard SZAVPlayerCache.shared.isFullyCached(uniqueID: uniqueId),
//              let localFileName = SZAVPlayerDatabase.shared.localFileInfos(uniqueID: uniqueId).first?.localFileName else {
//            return
//        }
//
//        let filePath = SZAVPlayerFileSystem.localFilePath(fileName: localFileName)
//        Logger.Action.log(.feeds_item_clk, category: .share, feed.pid)
//        let tagImageView = VideoShareTagView(with: feed.user.name ?? feed.user.uid.string)
//        view.addSubview(tagImageView)
//        guard let tagImage = tagImageView.screenshot else {
//            tagImageView.removeFromSuperview()
//            return
//        }
//        tagImageView.removeFromSuperview()
//        let url = filePath
//        let removeHandler = view.raft.show(.loading)
//        videoEditor.addTag(image: tagImage, for: url) { [weak self] url in
//            removeHandler()
//            guard let `self` = self, let url = url else {
//                return
//            }
//            cdPrint("url: \(url)")
//            ShareManager.default.showActivity(items: [url], viewController: self) { [weak self] in
//                self?.increaseShareCount(with: index)
//                self?.viewModel.reportShare(feed.pid)
//                //cancel or finish, remove
//                do {
//                    try FileManager.default.removeItem(at: url)
//                } catch {
//                    cdPrint("FileManager.default.removeItem: \(error)")
//                }
//            }
//        }
//    }
    
    func showCommentList(with feedId: String, commentsInfo: Entity.FeedRedirectInfo.CommentsInfo? = nil, count: Int) {
        shouldAutoPauseWhenDismiss = false
        let commentList = Feed.Comments.CommentsListViewController(with: feedId, commentsInfo: commentsInfo, commentsCount: count)
        commentList.commentsCountObservable
            .subscribe(onNext: { [weak self] (count) in
                //TODO: update comment count
                guard let `self` = self, let index = self.dataSource.firstIndex(where: { $0.feed.pid == feedId }) else { return }
                let viewModel = self.dataSource[index]
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
        guard let viewModel = viewModel, let index = dataSource.firstIndex(where: { $0.isEqual(viewModel) }) else {
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
            downloadVideo(viewModel: viewModel)
            
        case .userProfile(let uid):
            guard Settings.loginUserId != uid else {
                return
            }
            Routes.handle("/profile/\(uid)")
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
        }
    }
        
    func onSheet(action: AmongSheetController.ItemType, viewModel: Feed.ListCellViewModel?) {
        guard let viewModel = viewModel, let index = dataSource.firstIndex(where: { $0.isEqual(viewModel) }) else {
            return
        }
        
        let indexPath = IndexPath(row: index, section: 0)
        
        switch action {
        case .share:
            downloadVideo(viewModel: viewModel)
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
                    guard let `self` = self else { return }
//                    self.dataSource = self.dataSource.filter { $0.feed.pid != viewModel.feed.pid }
                    self.deleteRow(at: viewModel)
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
    
    func deleteRow(at viewModel: Feed.ListCellViewModel?) {
        guard let viewModel = viewModel, let index = dataSource.firstIndex(where: { $0.isEqual(viewModel) }) else {
            return
        }
//        guard let viewModel = dataSource.safe(indexPath.row) else {
//            return
//        }
        let indexPath = IndexPath(row: index, section: 0)
        let nextIndex = IndexPath(row: indexPath.row + 1, section: 0)
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
            dataSource = self.dataSource.filter { $0.feed.pid != viewModel.feed.pid }
//            tableView.reloadData()
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
//        if self.navigationController?.viewControllers.count > 1 {
//            return self
//        } else {
//            return UIApplication.tabBarController
//        }
    }
}
