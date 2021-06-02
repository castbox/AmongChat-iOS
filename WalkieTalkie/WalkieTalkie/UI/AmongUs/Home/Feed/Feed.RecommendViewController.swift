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
        
        override var isHidesBottomBarWhenPushed: Bool {
            return false
        }
        
        override func viewDidLoad() {
            //
            feedHeight = Frame.Screen.height - Frame.Height.bottomBar
            super.viewDidLoad()
        }
        
        override func loadData()
//        {
//            let removeBlock = view.raft.show(.loading)
//            Request.userFeeds(Settings.loginUserId, skipMs: 0) //Settings.loginUserId
//                .do(onSuccess: { [weak self] data in
//                    removeBlock()
//                    guard let `self` = self else { return }
//                    self.dataSource = data.list.map { Feed.ListCellViewModel(feed: $0) }
//                }, onDispose: {
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
        {
            let removeBlock = view.raft.show(.loading)
            Request.recommendFeeds(excludePids: []) //Settings.loginUserId
                .do(onSuccess: { [weak self] data in
                    removeBlock()
                    guard let `self` = self else { return }
                    self.dataSource = data?.map { Feed.ListCellViewModel(feed: $0) } ?? []
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
        
        override func bindSubviewEvent() {
            super.bindSubviewEvent()
            
            createButton.rx.tap
                .subscribe(onNext: { [weak self] in
                    guard AmongChat.Login.canDoLoginEvent(style: .authNeeded(source: .create_feed)) else {
                        return
                    }
                    Logger.Action.log(.feeds_create_clk)
                    let vc = Feed.SelectVideoViewController()
                    self?.navigationController?.pushViewController(vc)
                })
                .disposed(by: bag)
        }
        
        override func configureSubview() {
            super.configureSubview()
            createButton = SmallSizeButton(type: .custom)
            createButton.setImage(R.image.iconVideoCreate(), for: .normal)

            view.addSubviews(views: createButton)
            
            createButton.snp.makeConstraints { maker in
                maker.top.equalTo(Frame.Height.safeAeraTopHeight + 4.5)
                maker.trailing.equalTo(-20)
                maker.width.height.equalTo(42)
            }
        }
    }
}
