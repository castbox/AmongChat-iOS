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

extension AmongChat.Home {
    
    class FeedViewController: WalkieTalkie.ViewController {
        
        private var createButton: UIButton!
        private var tableView: UITableView!
        
        private var currentIndex = 0
//        private var previousIndex = 0
        
        private let disposeBag = DisposeBag()
        private var dataSource: [Entity.Feed] = [] {
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

        /// Set up Binding
        func setupBinding() {
            // Posts
//            viewModel.posts
//                .asObserver()
//                .observeOn(MainScheduler.instance)
//                .subscribe(onNext: { posts in
//                    self.data = posts
//                    self.tableView.reloadData()
//                }).disposed(by: disposeBag)
//
//            viewModel.isLoading
//                .asObserver()
//                .observeOn(MainScheduler.instance)
//                .subscribe(onNext: { isLoading in
//                    if isLoading {
//                        self.loadingAnimation.alpha = 1
//                        self.loadingAnimation.play()
//                    } else {
//                        self.loadingAnimation.alpha = 0
//                        self.loadingAnimation.stop()
//                    }
//                }).disposed(by: disposeBag)
//
//            viewModel.error
//                .asObserver()
//                .observeOn(MainScheduler.instance)
//                .subscribe(onNext: { err in
//                    self.showAlert(err.localizedDescription)
//                }).disposed(by: disposeBag)
//
//            ProfileViewModel.shared.cleardCache
//                .asObserver()
//                .observeOn(MainScheduler.instance)
//                .subscribe(onNext: { cleard in
//                    if cleard {
//                        //self.tableView.reloadData()
//                    }
//                }).disposed(by: disposeBag)
        }
        
        func setupObservers(){
            
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
    
    func replayVisibleItem() {
        guard isVisible else {
            return
        }
        let cell = tableView.cellForRow(at: IndexPath(row: currentIndex, section: 0)) as? FeedListCell
        cell?.replay()
    }
    
    private func loadData() {
        let removeBlock = view.raft.show(.loading)
        Request.userFeeds(Settings.loginUserId, skipMs: 0)
            .do(onSuccess: { [weak self] data in
                removeBlock()
                guard let `self` = self else { return }
                self.dataSource = data.list
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
