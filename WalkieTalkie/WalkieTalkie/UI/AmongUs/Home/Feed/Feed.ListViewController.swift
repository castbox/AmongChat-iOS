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

extension Feed {
    
    class ListViewController: WalkieTalkie.ViewController {
                
        var tableView: UITableView!
        
        lazy var viewModel = Feed.ListViewModel()
        
        private let videoEditor = VideoEditor()
        
        var feedHeight: CGFloat = 0
        
        var dataSource: [Feed.ListCellViewModel] = [] {
            didSet {
                tableView.reloadData()
            }
        }
        var currentIndex = 0
        
        private var shouldAutoPauseWhenDismiss: Bool = true
                
        // MARK: - Lifecycles
        override func viewDidLoad() {
            super.viewDidLoad()

            configureSubview()
            bindSubviewEvent()
            
//            var error: NSError?
//            VICacheManager.cleanAllCacheWithError(&error)
        }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            
            shouldAutoPauseWhenDismiss = true
            
            if let cell = tableView.visibleCells.first as? FeedListCell {
                cell.play()
            }
            //
            if dataSource.isEmpty {
                loadData()
            }
        }
        
        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            if shouldAutoPauseWhenDismiss, let cell = tableView.visibleCells.first as? FeedListCell {
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
            tableView.prefetchDataSource = self
            view.addSubviews(views: tableView)
            
            tableView.snp.makeConstraints { maker in
                maker.top.leading.trailing.equalToSuperview()
                maker.bottom.equalTo(-Frame.Height.bottomBar)
            }            
        }
        
        func bindSubviewEvent() {
            Settings.shared.loginResult.replay()
                .filterNil()
                .subscribe(onNext: { [weak self] _ in
                    self?.loadData()
                })
                .disposed(by: bag)
            
            setAudioMode()
        }
    }
}

// MARK: - Table View Extensions
extension Feed.ListViewController: UITableViewDelegate, UITableViewDataSource, UITableViewDataSourcePrefetching {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withClass: FeedListCell.self, for: indexPath)
        cell.config(with: dataSource.safe(indexPath.row))
        cell.actionHandler = { [weak self] action in
            self?.onCell(action: action, indexPath: indexPath)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return feedHeight
    }
    
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // If the cell is the first cell in the tableview, the queuePlayer automatically starts.
        // If the cell will be displayed, pause the video until the drag on the scroll view is ended
        if let cell = cell as? FeedListCell {
//            oldAndNewIndices.1 = indexPath.row
            if currentIndex != -1 {
                cell.pause()
            }
            currentIndex = indexPath.row
        }
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Pause the video if the cell is ended displaying
        if let cell = cell as? FeedListCell {
            cell.pause()
        }
    }
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            print("prefetchRowsAt: \(indexPath.row)")
        }
    }
    
    
}

// MARK: - ScrollView Extension
extension Feed.ListViewController: UIScrollViewDelegate {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        replayVisibleItem()
    }
    
}


extension Feed.ListViewController {
    func updateEmoteState(with pid: String, emoteId: String, isSelect: Bool, index: Int)  {
        guard AmongChat.Login.canDoLoginEvent(style: .authNeeded(source: .emote)) else {
            return
        }
        let resultSingle: Single<Bool>
        if isSelect {
            resultSingle = Request.feedSelectEmote(pid, emoteId: emoteId)
        } else {
            resultSingle = Request.feedUnselectEmote(pid, emoteId: emoteId)
        }
        resultSingle
            .subscribe(onSuccess: { [weak self] result in
                guard let `self` = self, let viewModel = self.dataSource.safe(index) else { return }
                viewModel.updateEmoteState(emoteId: emoteId, isSelect: isSelect)
                let cell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? FeedListCell
                cell?.update(emotes: viewModel.emotes)
                if isSelect {
                    cell?.show(emote: viewModel.emotes.first(where: { $0.id == emoteId }))
                }
            })
            .disposed(by: bag)
    }
    
    func share(feed: Entity.Feed) {
        //get tag imge
        guard let config = VICacheManager.cacheConfiguration(for: feed.url),
              config.progress == 1 else {
            return
        }
        Logger.Action.log(.feeds_item_clk, category: .share, feed.pid)
        let tagImageView = VideoShareTagView(with: feed.user.name ?? feed.user.uid.string)
        view.addSubview(tagImageView)
        guard let tagImage = tagImageView.screenshot else {
            tagImageView.removeFromSuperview()
            return
        }
        tagImageView.removeFromSuperview()
        let url = URL(fileURLWithPath: config.filePath.replacingOccurrences(of: ".mt_cfg", with: ""))
        let removeHandler = view.raft.show(.loading)
        videoEditor.addTag(image: tagImage, for: url) { [weak self] url in
            removeHandler()
            guard let `self` = self, let url = url else {
                return
            }
            cdPrint("url: \(url)")
            ShareManager.default.showActivity(items: [url], viewController: self) { [weak self] in
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
    
    func onCell(action: FeedListCell.Action, indexPath: IndexPath) {
        guard let viewModel = dataSource.safe(indexPath.row) else {
            return
        }
        
        switch action {
        case .selectEmote(let emote):
            if emote.id.isEmpty {
                let vc = Feed.EmotePickerController(Feed.EmotePickerViewModel())
                vc.didSelectItemHandler = { [weak self] emote in
                    //didn't contains voted
                    guard let `self` = self else {
                        return
                    }
                    Logger.Action.log(.feeds_item_clk, category: .emotes, emote.id)
                    if !viewModel.emotes.contains(where: { $0.id == emote.id && $0.isVoted == true }) {
                        self.updateEmoteState(with: viewModel.feed.pid, emoteId: emote.id, isSelect: true, index: indexPath.row)
                    } else {
                        let cell = self.tableView.cellForRow(at: indexPath) as? FeedListCell
                        cell?.show(emote: viewModel.emotes.first(where: { $0.id == emote.id }))
                    }
                }
                vc.showModal(in: tabBarController)
            } else {
                Logger.Action.log(.feeds_item_clk, category: .emotes, emote.id)
                updateEmoteState(with: viewModel.feed.pid, emoteId: emote.id, isSelect: !emote.isVoted, index: indexPath.row)
            }
        case .playComplete:
            self.viewModel.reportPlayFinish(viewModel.feed.pid)
        case .comment:
            guard AmongChat.Login.canDoLoginEvent(style: .authNeeded(source: .comment)) else {
                return
            }
            
            Logger.Action.log(.feeds_item_clk, category: .comments, viewModel.feed.pid)
            
            shouldAutoPauseWhenDismiss = false
            let commentList = Feed.Comments.CommentsListViewController(with: viewModel.feed.pid)
            self.presentPanModal(commentList)
        case .share:
            share(feed: viewModel.feed)
        case .more:
            let types: [AmongSheetController.ItemType]
            if Settings.loginUserId == viewModel.feed.uid {
                types = [.share, .deleteVideo, .cancel]
            } else {
                types = [.share, .notInterested, .report, .cancel]
            }
            AmongSheetController.show(items: types, in: self.tabBarController ?? self) { [weak self] item in
                guard let `self` = self else { return }
                switch item {
                case .share:
                    self.share(feed: viewModel.feed)
                case .notInterested:
                    Logger.Action.log(.feeds_item_clk, category: .not_intereasted, viewModel.feed.pid)
                    self.dataSource = self.dataSource.filter { $0.feed.pid != viewModel.feed.pid }
                    self.viewModel.reportNotIntereasted(viewModel.feed.pid)
                        .subscribe(onSuccess: { [weak self] result in
                            //
                        }) { error in
                            
                        }
                        .disposed(by: self.bag)
                case .deleteVideo:
                    Logger.Action.log(.feeds_item_clk, category: .delete, viewModel.feed.pid)
                    
                    let removeHandler = self.view.raft.show(.loading)
                    self.viewModel.feedDelete(viewModel.feed.pid)
                        .do(onDispose: {
                            removeHandler()
                        })
                        .subscribe(onSuccess: { [weak self] result in
                            guard let `self` = self else { return }
                            self.dataSource = self.dataSource.filter { $0.feed.pid != viewModel.feed.pid }
                        }) { error in
                            
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
        }
    }
    
    func setAudioMode() {
        do {
            try! AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch (let err){
            print("setAudioMode error:" + err.localizedDescription)
        }
        
    }

}
