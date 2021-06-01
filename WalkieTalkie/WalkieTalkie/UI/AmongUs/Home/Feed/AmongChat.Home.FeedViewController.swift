//
//  AmongChat.Home.FeedViewController.swift
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
    class CellViewModel { //: Equatable
//        static func == (lhs: Feed.CellViewModel, rhs: Feed.CellViewModel) -> Bool {
//            lhs.feed.pid == rhs.feed.pid
//        }
        
        var feed: Entity.Feed {
            didSet {
                updateEmotes()
            }
        }
        
        var emotes: [Entity.FeedEmote] = []
        
        init(feed: Entity.Feed) {
            self.feed = feed
            updateEmotes()
        }
        
        func updateEmoteState(emoteId: String, isSelect: Bool) {
            if isSelect {
                //当前列表有
                if let emote = feed.emotes.first(where: { $0.id == emoteId }) {
                    emote.count += 1
                    emote.isVoted = true
                } else {
                    //无，则添加
                    feed.emotes.append(Entity.FeedEmote(id: emoteId, count: 1, isVoted: true))
                }
            } else {
                //unselected
                if let emote = feed.emotes.first(where: { $0.id == emoteId }) {
                    emote.count -= 1
                    emote.isVoted = false
                    feed.emotes = feed.emotes.filter { $0.count > 0 }
                }
            }
            updateEmotes()
        }
        
        func updateEmotes() {
            let feedEmotes = Settings.shared.globalSetting.value?.feedEmotes ?? []
            
            var emotes = feed.emotes.map { item -> Entity.FeedEmote in
                let emote = item
                //calculate width
                let countWidth = item.count.string.boundingRect(with: CGSize(width: 100, height: 20), font: R.font.nunitoExtraBold(size: 14)!).width
                emote.width = countWidth + 60
                guard let feedEmote = feedEmotes.first(where: { $0.id == item.id }) else {
                    return emote
                }
                emote.url = feedEmote.resource
                emote.img = feedEmote.img
                return emote
            }.sorted { $0.count > $1.count }
            
            emotes.insert(Entity.FeedEmote(id: "", count: 0, isVoted: false, width: 60), at: 0)
            
            self.emotes = emotes
        }
    }
}

extension Feed {
    class ViewModel {
        
    }
}

extension AmongChat.Home {
    
    class FeedViewController: WalkieTalkie.ViewController {
        
        private var createButton: UIButton!
        private var tableView: UITableView!
        
        private var currentIndex = 0
//        private var previousIndex = 0
        private let videoEditor = VideoEditor()
        private let disposeBag = DisposeBag()
        private var dataSource: [Feed.CellViewModel] = [] {
            didSet {
                tableView.reloadData()
            }
        }
        
        override var isHidesBottomBarWhenPushed: Bool {
            return false
        }
        
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
            if let cell = tableView.visibleCells.first as? FeedListCell {
                cell.play()
            }
        }
        
        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            if let cell = tableView.visibleCells.first as? FeedListCell {
                cell.pause()
            }
        }

    }
}

// MARK: - Table View Extensions
extension AmongChat.Home.FeedViewController: UITableViewDelegate, UITableViewDataSource, UITableViewDataSourcePrefetching {
    
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
        if self.tabBarController != nil {
            return Frame.Screen.height - Frame.Height.bottomBar
        }
        return tableView.frame.height
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
//        for indexPath in indexPaths {
//            print(indexPath.row)
//        }
    }
    
    
}

// MARK: - ScrollView Extension
extension AmongChat.Home.FeedViewController: UIScrollViewDelegate {
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        replayVisibleItem()
    }
    
}


extension AmongChat.Home.FeedViewController {
    func updateEmoteState(with pid: String, emoteId: String, isSelect: Bool, index: Int)  {
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
            ShareManager.default.showActivity(items: [url], viewController: self) {
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
                    if !viewModel.emotes.contains(where: { $0.id == emote.id && $0.isVoted == true }) {
                        self.updateEmoteState(with: viewModel.feed.pid, emoteId: emote.id, isSelect: true, index: indexPath.row)
                    } else {
                        let cell = self.tableView.cellForRow(at: indexPath) as? FeedListCell
                        cell?.show(emote: viewModel.emotes.first(where: { $0.id == emote.id }))
                    }
                }
                vc.showModal(in: tabBarController)
            } else {
                updateEmoteState(with: viewModel.feed.pid, emoteId: emote.id, isSelect: !emote.isVoted, index: indexPath.row)
            }
        case .comment:
            ()
        case .share:
            share(feed: viewModel.feed)
        case .more:
            AmongSheetController.show(items: [.share, .notInterested, .report, .cancel], in: self.tabBarController ?? self) { [weak self] item in
                guard let `self` = self else { return }
                switch item {
                case .share:
                    self.share(feed: viewModel.feed)
                case .notInterested:
                    ()
                case .report:
                    Report.ViewController.showReport(on: self, uid: viewModel.feed.pid, type: .post, roomId: "") { [weak self] in
                        self?.view.raft.autoShow(.text(R.string.localizable.reportSuccess()))
                    }
                default:
                    ()
                }
            }
        }
    }
    
    func replayVisibleItem() {
        guard isVisible else {
            return
        }
        if let cell = tableView.cellForRow(at: IndexPath(row: currentIndex, section: 0)) as? FeedListCell {
            cell.replay()
        } else {
            if let cell = tableView.visibleCells.first as? FeedListCell {
                cell.replay()
            }
        }
    }
    
    private func loadData() {
        let removeBlock = view.raft.show(.loading)
        Request.userFeeds(Settings.loginUserId, skipMs: 0)
            .do(onSuccess: { [weak self] data in
                removeBlock()
                guard let `self` = self else { return }
                self.dataSource = data.list.map { Feed.CellViewModel(feed: $0) }
            }, onDispose: {
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
    
    private func loadMore() {
//        let removeBlock = view.raft.show(.loading)
//        let skipMS = dataSource.last?.msg.opTime ?? 0
//        Request.interactiveMsgs(opType, skipMs: skipMS)
//            .subscribe(onSuccess: { [weak self](data) in
//                removeBlock()
//                guard let `self` = self else { return }
//                let list = data.list.map { InteractiveMessageCellViewModel(msg: $0) }
//                var origenList = self.dataSource
//                list.forEach({ origenList.append($0)})
//                self.dataSource = origenList
//                self.tableView.endLoadMore(data.more ?? false)
//            }, onError: { (error) in
//                removeBlock()
//            }).disposed(by: bag)
    }
    
    func setAudioMode() {
        do {
            try! AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch (let err){
            print("setAudioMode error:" + err.localizedDescription)
        }
        
    }

    func configureSubview() {
        
        createButton = SmallSizeButton(type: .custom)
        createButton.setImage(R.image.iconVideoCreate(), for: .normal)
        
        tableView = UITableView()
        tableView.backgroundColor = .black
//        tableView.translatesAutoresizingMaskIntoConstraints = false  // Enable Auto Layout
        tableView.tableFooterView = UIView()
        tableView.isPagingEnabled = true
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        }
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .none
        view.addSubviews(views: tableView, createButton)
        tableView.register(nibWithCellClass: FeedListCell.self)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.prefetchDataSource = self
        
        tableView.snp.makeConstraints { maker in
            maker.top.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(-Frame.Height.bottomBar)
        }
        
        createButton.snp.makeConstraints { maker in
            maker.top.equalTo(Frame.Height.safeAeraTopHeight + 4.5)
            maker.trailing.equalTo(-20)
            maker.width.height.equalTo(42)
        }
    }
    
    func bindSubviewEvent() {
        loadData()
        setAudioMode()

        createButton.rx.tap
            .subscribe(onNext: { [weak self] in
                let vc = Feed.SelectVideoViewController()
                self?.navigationController?.pushViewController(vc)
            })
            .disposed(by: bag)
    }
}
