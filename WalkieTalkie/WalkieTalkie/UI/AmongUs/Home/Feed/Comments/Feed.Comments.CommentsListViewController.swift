//
//  Feed.Comments.CommentsListViewController.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/5/27.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import PullToDismiss

extension Feed.Comments {
    
    class CommentsListViewController: WalkieTalkie.ViewController {
        
        private lazy var container: UIView = {
            let v = UIView()
            v.layer.shadowOpacity = 1
            v.layer.shadowRadius = 20
            v.layer.shadowOffset = CGSize(width: 0, height: 6)
            v.layer.shadowColor = UIColor(hex6: 0x000000, alpha: 0.16).cgColor
            return v
        }()
        
        private lazy var dismissView: UIView = {
            let v = UIView()
            let dismissTap = UITapGestureRecognizer()
            v.addGestureRecognizer(dismissTap)
            dismissTap.rx.event
                .subscribe(onNext: { [weak self] (gr) in
                    self?.dismiss(animated: true)
                })
                .disposed(by: bag)
            return v
        }()
        
        private lazy var muskView: UIView = {
            let v = UIView()
            v.backgroundColor = UIColor(hex6: 0x000000, alpha: 0.5)
            v.isHidden = true
            return v
        }()
        
        private lazy var titleLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 16)
            lb.textColor = UIColor.white
            return lb
        }()
        
        private lazy var topBar: UIView = {
            let v = UIView()
            v.backgroundColor = UIColor(hex6: 0x222222)
            
            let bar: UIView = {
                let v = UIView()
                v.backgroundColor = UIColor(hex6: 0xFFFFFF, alpha: 0.2)
                v.layer.cornerRadius = 2
                v.clipsToBounds = true
                return v
            }()
            
            v.addSubviews(views: bar, titleLabel)
            
            bar.snp.makeConstraints { (maker) in
                maker.top.equalTo(8)
                maker.height.equalTo(4)
                maker.width.equalTo(36)
                maker.centerX.equalToSuperview()
            }
            
            titleLabel.snp.makeConstraints { (maker) in
                maker.centerX.equalToSuperview()
                maker.leading.greaterThanOrEqualToSuperview().inset(Frame.horizontalBleedWidth)
                maker.top.equalTo(20)
            }
            
            return v
        }()
        
        private lazy var emptyView: FansGroup.Views.EmptyDataView = {
            let v = FansGroup.Views.EmptyDataView()
            v.titleLabel.text = R.string.localizable.amongChatNoticeEmptyTip()
            v.isHidden = true
            return v
        }()
        
        private lazy var commentListView: UICollectionView = {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .vertical
            layout.minimumLineSpacing = 16
            let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
            v.register(cellWithClazz: CommentCell.self)
            v.register(cellWithClazz: ReplyCell.self)
            v.register(cellWithClazz: ExpandReplyCell.self)
            v.showsVerticalScrollIndicator = false
            v.showsHorizontalScrollIndicator = false
            v.dataSource = self
            v.delegate = self
            v.backgroundColor = UIColor(hex6: 0x222222)
            v.alwaysBounceVertical = true
            v.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 98, right: 0)
            return v
        }()
        
        private var pullToDismiss: PullToDismiss?
        
        private lazy var commentInputView: CommentInputView = {
            let v = CommentInputView()
            return v
        }()
        
        private lazy var bottomBar: UIView = {
            let v = UIView()
            v.backgroundColor = UIColor(hex6: 0x1C1C1C)
            let a = AvatarImageView()
            Settings.shared.amongChatUserProfile.replay().filterNil()
                .subscribe(onNext: { (profile) in
                    a.updateAvatar(with: profile)
                })
                .disposed(by: bag)
            let line = UIView()
            line.backgroundColor = UIColor(hex6: 0xFFFFFF, alpha: 0.06)
            v.addSubviews(views: line, a, commentInputView)
            line.snp.makeConstraints { (maker) in
                maker.leading.top.trailing.equalToSuperview()
                maker.height.equalTo(1)
            }
            a.snp.makeConstraints { (maker) in
                maker.width.height.equalTo(40)
                maker.leading.equalToSuperview().offset(Frame.horizontalBleedWidth)
                maker.bottom.equalTo(commentInputView)
            }
            
            commentInputView.snp.makeConstraints { (maker) in
                maker.leading.equalTo(a.snp.trailing).offset(16)
                maker.trailing.equalToSuperview().offset(-Frame.horizontalBleedWidth)
                maker.top.equalToSuperview().offset(12)
                maker.bottom.equalToSuperview().offset(-(12 + Frame.Height.safeAeraBottomHeight))
            }
            return v
        }()
        
        private let commentListVM: CommentListViewModel
        private lazy var comments: [CommentViewModel] = [] {
            didSet {
                commentListView.reloadData()
                titleLabel.text = R.string.localizable.feedCommentsListTitle("\(comments.count)")
                emptyView.isHidden = (comments.count > 0)
                if comments.count > 0 {
                    commentListView.pullToLoadMore { [weak self] in
                        guard let `self` = self else { return }
                        self.commentListVM.loadComments()
                            .do(onSuccess: { (_) in
                                self.commentListView.endLoadMore(self.commentListVM.hasMore)
                            })
                            .subscribe(onError: { (error) in
                                
                            })
                            .disposed(by: self.bag)
                    }
                } else {
                    commentListView.mj_footer = nil
                }
            }
        }
        
        private lazy var commentsReplyDisposable = [Disposable]() {
            didSet {
                oldValue.forEach { $0.dispose() }
            }
        }
        
        private var replyComment: CommentViewModel? = nil
        private var replyReply: ReplyViewModel? = nil
        private var positionBlock: (() -> Void)? = nil
        private var replyToIndexPath: IndexPath? = nil
        
        init(with feedId: String, commentsInfo: Entity.FeedRedirectInfo.CommentsInfo? = nil) {
            self.commentListVM = CommentListViewModel(with: feedId, commentsInfo: commentsInfo)
            super.init(nibName: nil, bundle: nil)
            if let commentsInfo = commentsInfo {
                positionBlock = { [weak self] in
                    let commentIdx: Int = commentsInfo.index ?? 0
                    let replyIdx: Int = (commentsInfo.indexReply ?? -1) + 1
                    let positioningIndexPath = IndexPath(item: replyIdx, section: commentIdx)
                    self?.commentListView.scrollToItem(at: positioningIndexPath, at: .top, animated: true)
                    let cell = self?.commentListView.cellForItem(at: positioningIndexPath)
                    UIView.animate(withDuration: 0.2, delay: 0, options: .transitionCurlUp, animations: {
                        cell?.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                    }, completion: { (_) in
                        cell?.transform = .identity
                    })
                }
            }
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setUpLayout()
            setUpEvents()
        }
        
        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            topBar.addCorner(with: 20)
        }
        
    }
    
}

extension Feed.Comments.CommentsListViewController {
    
    private func setUpLayout() {
        
        view.backgroundColor = .clear
        
        view.addSubviews(views: dismissView, container, muskView)
        
        dismissView.snp.makeConstraints { (maker) in
            maker.leading.top.trailing.equalToSuperview()
            maker.bottom.equalTo(container.snp.top)
        }
        
        container.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalToSuperview().offset(0)
            maker.height.equalTo(view.snp.height).multipliedBy(0.75)
        }
        
        container.addSubviews(views: topBar, commentListView, emptyView, bottomBar)
        
        emptyView.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.leading.greaterThanOrEqualToSuperview().offset(40)
            maker.top.equalTo(topBar.snp.bottom).offset(40)
        }
        
        topBar.snp.makeConstraints { (maker) in
            maker.leading.top.trailing.equalToSuperview()
            maker.height.equalTo(50)
        }
        
        commentListView.snp.makeConstraints { (maker) in
            maker.leading.trailing.bottom.equalToSuperview()
            maker.top.equalTo(topBar.snp.bottom).offset(-0.5)
        }
        
        bottomBar.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalToSuperview().offset(0)
            maker.top.greaterThanOrEqualTo(topBar.snp.bottom)
        }
        
        muskView.snp.makeConstraints { (maker) in
            maker.leading.top.trailing.equalToSuperview()
            maker.bottom.equalTo(bottomBar.snp.top)
        }
        
        if let positioning = positionBlock {
            
            Observable.combineLatest(rx.viewDidAppear,
                                     commentListView.rx.observe(CGSize.self, "contentSize")
                                        .filterNil()
                                        .filter({ $0 != .zero }))
                .take(1)
                .subscribe(onNext: { (_) in
                    positioning()
                })
                .disposed(by: bag)
            
        } else {
            commentListVM.loadComments()
                .subscribe(onSuccess: { (_) in
                    
                }, onError: { (error) in
                    
                })
                .disposed(by: bag)
        }
        
        pullToDismiss = PullToDismiss(scrollView: commentListView)
        pullToDismiss?.delegate = self
        pullToDismiss?.backgroundEffect = nil
        pullToDismiss?.edgeShadow = nil
        pullToDismiss?.dismissableHeightPercentage = 0.4
        
    }
    
    private func setUpEvents() {
        
        commentListVM.commentsObservable
            .subscribe(onNext: { [weak self] (comments) in
                self?.comments = comments
                self?.commentsReplyDisposable = comments.enumerated().map { idx, comment in
                    comment.repliesObservable.subscribe(onNext: { (_) in
                        self?.commentListView.reloadSections(IndexSet([idx]))
                    })
                }
            })
            .disposed(by: bag)
        
        RxKeyboard.instance.visibleHeight.asObservable()
            .subscribe(onNext: { [weak self] keyboardVisibleHeight in
                
                guard let `self` = self else { return }
                
                self.dismissView.isUserInteractionEnabled = keyboardVisibleHeight <= 0
                self.muskView.isHidden = keyboardVisibleHeight <= 0
                
                guard keyboardVisibleHeight > 0 else {
                    self.bottomBar.snp.updateConstraints { (maker) in
                        maker.bottom.equalToSuperview().offset(0)
                    }
                    return
                }
                
                self.bottomBar.snp.updateConstraints { (maker) in
                    maker.bottom.equalToSuperview().offset(-keyboardVisibleHeight + Frame.Height.safeAeraBottomHeight)
                }
                
                UIView.animate(withDuration: RxKeyboard.instance.animationDuration) {
                    self.view.layoutIfNeeded()
                }
                //回复的条目滚动到键盘上方
                guard let replyIndexPath = self.replyToIndexPath,
                      let replyCell = self.commentListView.cellForItem(at: replyIndexPath) else { return }
                
                let rect = self.commentListView.convert(replyCell.frame, to: self.view)
                let distance = Frame.Screen.height - (keyboardVisibleHeight + 64 + 8) - rect.maxY
                
                guard distance < 0 else { return }
                
                UIView.animate(withDuration: RxKeyboard.instance.animationDuration) {
                    self.commentListView.contentOffset.y = self.commentListView.contentOffset.y - distance
                }
                //end
            })
            .disposed(by: bag)
        
        commentInputView.sendObservable
            .map({ [weak self] _ in
                self?.commentInputView.inputTextView.text
            })
            .subscribe(onNext: { [weak self] (text) in
                guard let `self` = self else { return }
                AmongChat.Login.doLogedInEvent(style: .authNeeded(source: .comment)) { [weak self] in
                    self?.sendComment()
                }
            })
            .disposed(by: bag)
        
    }
    
    private func sendComment() {
        
        let action: Single<Void>
        
        if let reply = replyReply,
           let comment = replyComment {
            action = comment.replyToReply(reply, text: commentInputView.inputTextView.text)
        } else if let comment = replyComment {
            action = comment.replyToComment(comment, text: commentInputView.inputTextView.text)
        } else {
            action = commentListVM.addComment(text: commentInputView.inputTextView.text)
        }
        
        let hudRemoval = view.raft.show(.loading)
        action
            .do(onDispose: {
                hudRemoval()
            })
            .subscribe(onSuccess: { [weak self] (_) in
                self?.replyComment = nil
                self?.replyReply = nil
                self?.commentInputView.inputTextView.text = ""
                self?.commentInputView.placeholderLabel.text = R.string.localizable.feedCommentsPlaceholder()
                
                //新增的条目显示出来
                guard let replyIndex = self?.replyToIndexPath else {
                    self?.commentListView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: true)
                    return
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self?.commentListView.scrollToItem(at: IndexPath(item: 0, section: replyIndex.section), at: .top, animated: true)
                }
                self?.replyToIndexPath = nil
                //end
            }, onError: { [weak self] (error) in
                self?.view.raft.autoShow(.text(error.msgOfError ?? ""))
            })
            .disposed(by: bag)
        
    }
    
    private func deleteCommentAlert(deleteAction: @escaping () -> Void) {
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let delete = UIAlertAction(title: R.string.localizable.amongChatDelete(), style: .destructive) { (_) in
            deleteAction()
        }
        
        let cancel = UIAlertAction(title: R.string.localizable.toastCancel(), style: .cancel) { (_) in
            
        }
        
        alert.addAction(cancel)
        alert.addAction(delete)
        
        present(alert, animated: true)
    }
}

extension Feed.Comments.CommentsListViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return comments.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        guard let comment = comments.safe(section) else {
            return 0
        }
        
        let loadedRepliesCount = comment.repliesCollapsed ? 0 : comment.replies.count
        
        if comment.showExpandOption && (comment.hasMoreReplies || comment.repliesCollapsed || comment.replies.count > 0) {
            return loadedRepliesCount + 2
        } else {
            return loadedRepliesCount + 1
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let comment = comments.safe(indexPath.section) else {
            return UICollectionViewCell()
        }
        
        switch indexPath.item {
        case 0:
            let cell = collectionView.dequeueReusableCell(withClazz: Feed.Comments.CommentCell.self, for: indexPath)
            cell.bindData(comment: comment, likeHandler: { [weak self] (liked) in
                
                guard let `self` = self else { return }
                
                comment.likeComment(liked)
                    .subscribe(onError: { [weak self] (error) in
                        self?.commentListView.reloadItems(at: [indexPath])
                    })
                    .disposed(by: self.bag)
                
            }, replyHandler: { [weak self] in
                guard let `self` = self else { return }
                self.replyToIndexPath = indexPath
                self.commentInputView.inputTextView.becomeFirstResponder()
                self.commentInputView.placeholderLabel.text = R.string.localizable.amongChatReply() + " @\(comment.comment.user.name ?? "")"
                self.replyComment = comment
            }, moreActionHandler: { [weak self] in
                guard let `self` = self,
                      comment.comment.user.uid.isSelfUid else { return }
                self.deleteCommentAlert(deleteAction: {
                    self.commentListVM.deleteComment(comment)
                        .subscribe(onSuccess: { (_) in
                            
                        }, onError: { (error) in
                            
                        })
                        .disposed(by: self.bag)
                })
            })
            
            return cell
            
        default:
            
            if let reply = comment.replies.safe(indexPath.item - 1),
               !comment.repliesCollapsed {
                let cell = collectionView.dequeueReusableCell(withClazz: Feed.Comments.ReplyCell.self, for: indexPath)
                cell.bindData(reply: reply,
                              tapAtHandler: {
                                let uid = reply.reply.toUid > 0 ? reply.reply.toUid : comment.comment.uid
                                Routes.handle("/profile/\(uid)")
                              },
                              replyHandler: { [weak self] in
                                guard let `self` = self else { return }
                                self.replyToIndexPath = indexPath
                                self.commentInputView.inputTextView.becomeFirstResponder()
                                self.commentInputView.placeholderLabel.text = R.string.localizable.amongChatReply() + " @\(reply.reply.user.name ?? "")"
                                self.replyReply = reply
                                self.replyComment = comment
                              }, moreActionHandler: { [weak self] in
                                guard let `self` = self,
                                      reply.reply.user.uid.isSelfUid else { return }
                                self.deleteCommentAlert(deleteAction: {
                                    comment.deleteReply(reply)
                                        .subscribe(onSuccess: { (_) in
                                            
                                        }, onError: { (error) in
                                            
                                        })
                                        .disposed(by: self.bag)
                                })
                              })
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withClazz: Feed.Comments.ExpandReplyCell.self, for: indexPath)
                cell.bindData(comment: comment) { [weak self] in
                    guard let `self` = self else { return }
                    
                    comment.expandOrCollapseReplies()
                        .subscribe(onSuccess: { [weak self] (_) in
                            self?.commentListView.reloadSections(IndexSet([indexPath.section]))
                        }, onError: { (error) in
                            
                        })
                        .disposed(by: self.bag)
                    
                }
                
                return cell
            }
            
        }
    }
}

extension Feed.Comments.CommentsListViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard let cell = collectionView.cellForItem(at: indexPath) as? Feed.Comments.ExpandReplyCell else {
            return
        }
        
        cell.tapAction?()
    }
}

extension Feed.Comments.CommentsListViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        guard let comment = comments.safe(indexPath.section) else {
            return .zero
        }
        
        switch indexPath.item {
        case 0:
            return comment.viewSize
            
        default:
            if let reply = comment.replies.safe(indexPath.item - 1),
               !comment.repliesCollapsed {
                return reply.viewSize
            } else {
                return CGSize(width: UIScreen.main.bounds.width, height: 15)
            }
            
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        switch section {
        case 0:
            
            return UIEdgeInsets(top: 12, left: 0, bottom: 0, right: 0)
            
        default:
            return UIEdgeInsets(top: 28, left: 0, bottom: 0, right: 0)
        }
        
    }
    
}
