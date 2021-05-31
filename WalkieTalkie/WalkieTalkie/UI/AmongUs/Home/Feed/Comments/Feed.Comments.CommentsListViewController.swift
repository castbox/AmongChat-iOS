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

extension Feed.Comments {
    
    class CommentsListViewController: WalkieTalkie.ViewController {
        
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
        
        private lazy var commentListView: UICollectionView = {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .vertical
            layout.minimumLineSpacing = 12
            let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
            v.register(cellWithClazz: CommentCell.self)
            v.register(cellWithClazz: ReplyCell.self)
            v.register(cellWithClazz: ExpandReplyCell.self)
            v.showsVerticalScrollIndicator = false
            v.showsHorizontalScrollIndicator = false
            v.dataSource = self
            v.delegate = self
            v.backgroundColor = .clear
            v.alwaysBounceVertical = true
            v.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 98, right: 0)
            v.keyboardDismissMode = .interactive
            return v
        }()
        
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
                maker.top.equalToSuperview().offset(12)
            }
            
            commentInputView.snp.makeConstraints { (maker) in
                maker.leading.equalTo(a.snp.trailing).offset(16)
                maker.trailing.equalToSuperview().offset(-Frame.horizontalBleedWidth)
                maker.top.equalToSuperview().offset(12)
                maker.bottom.equalToSuperview().offset(-46)
            }
            return v
        }()
        
        private let commentListVM: CommentListViewModel
        private lazy var comments: [CommentViewModel] = [] {
            didSet {
                commentListView.reloadData()
            }
        }
        
        private lazy var commentsReplyDisposable = [Disposable]() {
            didSet {
                oldValue.forEach { $0.dispose() }
            }
        }
        
        private var replyComment: CommentViewModel? = nil
        private var replyReply: ReplyViewModel? = nil
        
        init(with feedId: String) {
            self.commentListVM = CommentListViewModel(with: feedId)
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setUpLayout()
            setUpEvents()
        }
        
    }
    
}

extension Feed.Comments.CommentsListViewController {
    
    private func setUpLayout() {
        
        view.addSubviews(views: topBar, commentListView, bottomBar)
        
        topBar.snp.makeConstraints { (maker) in
            maker.leading.top.trailing.equalToSuperview()
            maker.height.equalTo(50)
        }
        
        commentListView.snp.makeConstraints { (maker) in
            maker.leading.trailing.bottom.equalToSuperview()
            maker.top.equalTo(topBar.snp.bottom)
        }
        
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
        
        bottomBar.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalToSuperview().offset(0)
            maker.top.greaterThanOrEqualTo(topBar.snp.bottom)
        }
        
        commentListVM.loadComments()
            .subscribe(onSuccess: { (_) in
                
            }, onError: { (error) in
                
            })
            .disposed(by: bag)
        
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
                
                guard keyboardVisibleHeight > 0 else {
                    self.bottomBar.snp.updateConstraints { (maker) in
                        maker.bottom.equalToSuperview().offset(0)
                    }
                    return
                }
                
                self.bottomBar.snp.updateConstraints { (maker) in
                    maker.bottom.equalToSuperview().offset(-(keyboardVisibleHeight - 34))
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
        
        action.subscribe(onSuccess: { [weak self] (_) in
            self?.replyComment = nil
            self?.replyReply = nil
            self?.commentInputView.inputTextView.text = ""
            self?.commentInputView.placeholderLabel.text = R.string.localizable.feedCommentsPlaceholder()
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
        
        if comment.hasMoreReplies || comment.repliesCollapsed || comment.replies.count > 0 {
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
                                Routes.handle("/profile/\(reply.reply.toUid)")
                              },
                              replyHandler: { [weak self] in
                    guard let `self` = self else { return }
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

extension Feed.Comments.CommentsListViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        guard let comment = comments.safe(indexPath.section) else {
            return .zero
        }
        
        switch indexPath.item {
        case 0:
            return comment.viewSize
            
        default:
            if let reply = comment.replies.safe(indexPath.item - 1) {
                return reply.viewSize
            } else {
                return CGSize(width: UIScreen.main.bounds.width, height: 19)
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
