//
//  Feed.TopicListController.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 23/06/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import SnapKit
import AVFoundation
import RxSwift


private let bottomBarMinHeight = 57 + Frame.Height.safeAeraBottomHeight

extension Feed {
    
    class TopicListController: Feed.ListViewController {
        
        private lazy var navView: NavigationBar = {
            let n = NavigationBar()
            let btn = n.leftBtn
            btn.setImage(R.image.icon_profile_back(), for: .normal)
            btn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] () in
                    self?.navigationController?.popViewController()
                })
                .disposed(by: bag)
            n.titleLabel.text = ""
            n.backgroundView.backgroundColor = .clear
            n.backgroundColor = .clear
            return n
        }()
        
        private lazy var commentInputView: Feed.Comments.CommentInputView = {
            let v = Feed.Comments.CommentInputView()
            return v
        }()
        
        private var bottomContainer: UIView!
        private var bottomBar: UIView!
                
        private var isLoadingMore: Bool = false
        private var hasMore: Bool = true
        
        private let pid: String
        private var topic: String?
        
        init(with pid: String) {
            self.pid = pid
            super.init(nibName: nil, bundle: nil)
            self.listStyle = .profile
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            feedHeight = Frame.Screen.height - bottomBarMinHeight
            super.viewDidLoad()
        }
        
        override func loadData() {
            let removeBlock = view.raft.show(.loading, hideAnimated: false)
            Request.feed(with: pid)
                .flatMap { feed -> Single<[Entity.Feed]> in
                    return Request.topicFeeds(feed.topic, exclude: [feed.pid])
                        .map { feedList -> [Entity.Feed] in
                            var list = feedList
                            list.insert(feed, at: 0)
                            return list
                        }
                }
                .subscribe(onSuccess: { [weak self] data in
                    guard let `self` = self else { return }
                    removeBlock()
                    self.topic = data.first?.topic ?? ""
                    self.tableView.alpha = 0
                    self.hasMore = data.count >= 10
                    self.feedsDataSource = data.map { Feed.ListCellViewModel(feed: $0) }
                    self.tableView.reloadData()
                    self.autoScrollToDefaultIndex()
                }, onError: { [weak self] _ in
                    removeBlock()
                    self?.addErrorView({ [weak self] in
                        self?.loadData()
                    })
                }).disposed(by: bag)
        }
        
        override func loadMore() {
            guard hasMore, let createTime = feedsDataSource.last?.feed.createTime else {
                return
            }
            isLoadingMore = true
            
            Request.topicFeeds(topic ?? "", exclude: [], skipMs: createTime)
                .do(onDispose: { [weak self] in
                    self?.isLoadingMore = false
                })
                .delay(.fromSeconds(0.2), scheduler: MainScheduler.asyncInstance)
                .subscribe(onSuccess: { [weak self] data in
                    guard let `self` = self else { return }
                    var source = data.map { Feed.ListCellViewModel(feed: $0) }
                    self.hasMore = source.count >= 20
                    guard !source.isEmpty else { return }
                    source.insert(contentsOf: self.feedsDataSource, at: 0)
                    self.feedsDataSource = source
                    //insert datasource
                    let rows = self.tableView.numberOfRows(inSection: 0)
                    let newRow = self.dataSource.count
                    self.tableView.isPagingEnabled = false
                    let indexPaths = Array(rows..<newRow).map({ IndexPath(row: $0, section: 0) })
                    self.tableView.beginUpdates()
                    self.tableView.insertRows(at: indexPaths, with: .none)
                    self.tableView.endUpdates()
                    self.tableView.isPagingEnabled = true
                }).disposed(by: bag)
        }
        
        func autoScrollToDefaultIndex() {
            replayVisibleItem()
            tableView.alpha = 1
        }
        

        override func bindSubviewEvent() {
            super.bindSubviewEvent()
            
            RxKeyboard.instance.visibleHeight.asObservable()
                .subscribe(onNext: { [weak self] keyboardVisibleHeight in
                    
                    guard let `self` = self else { return }
                    
                    self.bottomBar.snp.updateConstraints { (maker) in
                        maker.bottom.equalToSuperview().offset(-keyboardVisibleHeight)
                    }
                    self.bottomContainer.snp.updateConstraints { maker in
                        maker.bottom.equalTo(keyboardVisibleHeight > 0 ? 0 : -Frame.Height.safeAeraBottomHeight)
                    }
                    UIView.animate(withDuration: 0) {
                        self.view.layoutIfNeeded()
                    }
                })
                .disposed(by: bag)
            
            commentInputView.sendObservable
                .map({ [weak self] _ in
                    self?.commentInputView.inputTextView.text
                })
                .subscribe(onNext: { [weak self] (text) in
                    self?.sendComment()
                })
                .disposed(by: bag)
        }
        
        override func configureSubview() {
            super.configureSubview()
            
            
            bottomContainer = UIView()
            bottomContainer.backgroundColor = .clear
            
            bottomBar = UIView()
            bottomBar.backgroundColor = UIColor(hex6: 0x1C1C1C)
            
            let avatarView = AvatarImageView()
            Settings.shared.amongChatUserProfile.replay().filterNil()
                .subscribe(onNext: { (profile) in
                    avatarView.updateAvatar(with: profile)
                })
                .disposed(by: bag)
            
            
            bottomBar.addSubviews(views: bottomContainer)
            bottomContainer.snp.makeConstraints { maker in
                maker.top.leading.trailing.equalToSuperview()
                maker.bottom.equalTo(-Frame.Height.safeAeraBottomHeight)
            }
            
            bottomContainer.addSubviews(views: avatarView, commentInputView)
            
            avatarView.snp.makeConstraints { (maker) in
                maker.width.height.equalTo(40)
                maker.leading.equalToSuperview().offset(Frame.horizontalBleedWidth)
                maker.bottom.equalToSuperview().offset(-8.5)
            }
            
            commentInputView.snp.makeConstraints { (maker) in
                maker.leading.equalTo(avatarView.snp.trailing).offset(16)
                maker.trailing.equalToSuperview().offset(-Frame.horizontalBleedWidth)
                maker.top.equalToSuperview().offset(8.5)
                maker.bottom.equalToSuperview().offset(-8.5)
            }
            
            view.addSubviews(views: navView, bottomBar)
            
            tableView.snp.remakeConstraints { maker in
                maker.top.leading.trailing.equalToSuperview()
                maker.bottom.equalTo(-bottomBarMinHeight)
            }
            
            navView.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview()
                maker.top.equalTo(topLayoutGuide.snp.bottom)
            }
            
            bottomBar.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview()
                maker.bottom.equalToSuperview()
//                maker.height.greaterThanOrEqualTo(bottomBarMinHeight)
                maker.top.greaterThanOrEqualTo(navView.snp.bottom)
            }
        }
        
        override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
            super.tableView(tableView, willDisplay: cell, forRowAt: indexPath)
            
            if !isLoadingMore, dataSource.count - currentIndex < 5 {
                loadMore()
            }
        }
    }
}


extension Feed.TopicListController {
    
    private func sendComment() {
        
        guard let cell = tableView.visibleCells.first as? FeedListCell,
              let viewModel = cell.viewModel else {
            return
        }
        Logger.Action.log(.feeds_comment_send_clk)
        Request.createComment(toFeed: viewModel.feed.pid, text: commentInputView.inputTextView.text)
            .subscribe(onSuccess: { [weak self] (_) in
                self?.commentInputView.inputTextView.text = ""
                self?.commentInputView.placeholderLabel.text = R.string.localizable.feedCommentsPlaceholder()
                
                //update comment count
                viewModel.increasementCommentCount()
                cell.updateCommentCount()
                
                self?.view.raft.autoShow(.text(R.string.localizable.feedCommentsCommentSuccess()), userInteractionEnabled: false)
            }, onError: { [weak self] (error) in
                self?.view.raft.autoShow(.text(error.msgOfError ?? ""), userInteractionEnabled: false)
            })
            .disposed(by: bag)
        
    }
}

