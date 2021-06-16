//
//  ProfileFeedViewController.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 01/06/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import SnapKit
import AVFoundation
import RxSwift


private let bottomBarMinHeight = 57 + Frame.Height.safeAeraBottomHeight

extension Social {
    
    class ProfileFeedController: Feed.ListViewController {
        enum Style {
            case single //单 feed
            case `default`
        }
        
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
        
        private var playCountView: UIView!
        private var playCountLabel: UILabel!
        
        private var isLoadingMore: Bool = false
        private var hasMore: Bool = true
        
        private let uid: Int
        private let defaultIndex: Int
        private let feedRedirectInfo: Entity.FeedRedirectInfo?
        
        
        private var style: Style {
            feedRedirectInfo == nil ? .default : .single
        }
        
        init(with uid: Int, index: Int = 0) {
            self.uid = uid
            self.defaultIndex = index
            self.feedRedirectInfo = nil
            super.init(nibName: nil, bundle: nil)
            self.listStyle = .profile
        }
        
        init(with uid: Int, feedRedirectInfo: Entity.FeedRedirectInfo) {
            self.uid = uid
            self.defaultIndex = 0
            self.feedRedirectInfo = feedRedirectInfo
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
            if let feed = feedRedirectInfo?.post {
                tableView.alpha = 0
                feedsDataSource = [feed].map { Feed.ListCellViewModel(feed: $0) }
                tableView.reloadData()
                autoScrollToDefaultIndex()
            } else {
                let removeBlock = view.raft.show(.loading, hideAnimated: false)
                Request.userFeeds(uid, skipMs: 0) //Settings.loginUserId
                    .subscribe(onSuccess: { [weak self] data in
                        guard let `self` = self else { return }
                        removeBlock()
                        self.tableView.alpha = 0
                        self.feedsDataSource = data.list.map { Feed.ListCellViewModel(feed: $0) }
                        self.tableView.reloadData()
                        self.autoScrollToDefaultIndex()
                    }, onError: { [weak self] _ in
                        removeBlock()
                        self?.addErrorView({ [weak self] in
                            self?.loadData()
                        })
                    }).disposed(by: bag)
            }
        }
        
        override func loadMore() {
//            let removeBlock = view.raft.show(.loading)
            //exclutepids
            guard style == .default,
                  hasMore else {
                return
            }
            isLoadingMore = true
            let maxIndex = dataSource.count - 1
//            cdPrint("excludePid: \(excludePids)")
            Request.userFeeds(uid, skipMs: dataSource.count.int64) //Settings.loginUserId
                .do(onDispose: { [weak self] in
                    self?.isLoadingMore = false
//                    removeBlock()
                })
                .delay(.fromSeconds(0.2), scheduler: MainScheduler.asyncInstance)
                .subscribe(onSuccess: { [weak self] data in
                    guard let `self` = self else { return }
                    var source = data.list.map { Feed.ListCellViewModel(feed: $0) }
                    self.hasMore = source.count >= 10
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
                }, onError: { [weak self](error) in
//                    self?.addErrorView({ [weak self] in
//                        self?.loadData()
//                    })
                }).disposed(by: bag)
        }
        
        func autoScrollToDefaultIndex() {
            if defaultIndex > 0 {
                if defaultIndex < dataSource.count {
                    let indexPath = IndexPath(row: defaultIndex, section: 0)
                    tableView.scrollToRow(at: indexPath, at: .none, animated: false)
                    tableView.layoutIfNeeded()
                }
            }
            replayVisibleItem()
            tableView.alpha = 1
        }
        
        override func replayVisibleItem(_ replay: Bool = true) {
            super.replayVisibleItem(replay)
            let visibleCell: FeedListCell?
            
            if let cell = tableView.cellForRow(at: IndexPath(row: currentIndex, section: 0)) as? FeedListCell {
                visibleCell = cell
            } else {
                if let cell = tableView.visibleCells.first as? FeedListCell {
                    visibleCell = cell
                } else {
                    visibleCell = nil
                }
            }
            guard let feed = visibleCell?.viewModel?.feed,
                  uid == Settings.loginUserId else {
                return
            }
            playCountLabel.text = feed.playCountValue.string
            playCountView.fadeIn(duration: 0.2)
        }
        
        override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
            guard uid == Settings.loginUserId else {
                return
            }
            playCountView.fadeOut(duration: 0.2)
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
            
            //show comment
            if let feed = feedRedirectInfo?.post,
               let commentInfo = feedRedirectInfo?.commentsInfo {
                //show comment
                self.showCommentList(with: feed.pid, commentsInfo: commentInfo, count: feed.cmtCount)
            }
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
            
            playCountView = UIView()
            playCountLabel = UILabel()
            playCountLabel.font = R.font.nunitoExtraBold(size: 16)
            playCountLabel.textColor = .white
            
            let playCountIcon = UIImageView(image: R.image.iconProfileFeedPlayCount())
            playCountView.addSubviews(views: playCountIcon, playCountLabel)
            playCountIcon.snp.makeConstraints { maker in
                maker.leading.top.bottom.equalToSuperview()
            }
            
            playCountLabel.snp.makeConstraints { maker in
                maker.leading.equalTo(playCountIcon.snp.trailing).offset(8)
                maker.trailing.equalToSuperview()
                maker.height.equalToSuperview()
            }
            
            playCountView.isHidden = Settings.loginUserId != uid
            
            avatarView.isHidden = !playCountView.isHidden
            commentInputView.isHidden = !playCountView.isHidden
            
            bottomBar.addSubviews(views: bottomContainer)
            bottomContainer.snp.makeConstraints { maker in
                maker.top.leading.trailing.equalToSuperview()
                maker.bottom.equalTo(-Frame.Height.safeAeraBottomHeight)
            }
            
            bottomContainer.addSubviews(views: avatarView, commentInputView, playCountView)
            
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
            
            playCountView.snp.makeConstraints { maker in
                maker.leading.equalTo(24)
                maker.top.equalTo(17.5)
                maker.height.equalTo(24)
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
    }
}


extension Social.ProfileFeedController {
    
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
