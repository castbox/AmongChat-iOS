//
//  Feed.Comments+ViewModels.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/5/28.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension Feed.Comments {
    
    class CommentListViewModel {
        
        private let bag = DisposeBag()
        private let commentsRelay = BehaviorRelay<[CommentViewModel]>(value: [])
        private(set) var hasMore: Bool = true
        private let feedId: String
        private var isLoading = false
        
        var commentsObservable: Observable<[CommentViewModel]> {
            return commentsRelay.asObservable().observeOn(MainScheduler.asyncInstance)
        }
        
        init(with feedId: String) {
            self.feedId = feedId
        }
        
        func loadComments() -> Single<Void> {
            
            guard hasMore,
                  !isLoading else {
                return Single.just(())
            }
            
            isLoading = true
            
            let skipMs = commentsRelay.value.last?.comment.createTime ?? 0
            
            return Request.feedCommentList(ofPost: feedId, skipMs: skipMs)
                .do(onSuccess: { [weak self] (commentList) in
                    guard let `self` = self else { return }
                    
                    var cached = self.commentsRelay.value
                    cached.append(contentsOf: commentList.list.map({ CommentViewModel(with: $0) }))
                    self.commentsRelay.accept(cached)
                    self.hasMore = commentList.more
                    
                }, onDispose: { [weak self] in
                    self?.isLoading = false
                }).map { _ in }
        }
        
        func addComment(text: String) -> Single<Void> {
            return Request.createComment(toFeed: feedId, text: text)
                .do(onSuccess: { [weak self] (comment) in
                    guard let `self` = self else { return }
                    var cached = self.commentsRelay.value
                    cached.insert(CommentViewModel(with: comment), at: 0)
                    self.commentsRelay.accept(cached)
                }).map { _ in }
        }
        
        func deleteComment(_ comment: CommentViewModel) -> Single<Void> {
            return Request.deleteComment(comment.comment.cid)
                .do(onSuccess: { [weak self] (success) in
                    guard let `self` = self, success else { return }
                    var comments = self.commentsRelay.value
                    comments.removeFirst { $0 === comment }
                    self.commentsRelay.accept(comments)
                }).map { _ in }
        }
    }
    
    class CommentViewModel {
        
        private let bag = DisposeBag()
        private let repliesRelay = BehaviorRelay<[ReplyViewModel]>(value: [])
        private(set) var hasMoreReplies: Bool
        private var isLoading = false
        private(set) var comment: Entity.FeedComment
        private(set) lazy var viewSize: CGSize = CommentCell.cellSize(for: self)
        private(set) var repliesCollapsed = false

        var repliesObservable: Observable<[ReplyViewModel]> {
            return repliesRelay.asObservable().observeOn(MainScheduler.asyncInstance)
        }
        
        var replies: [ReplyViewModel] {
            return repliesRelay.value
        }
        
        var timeString: String {
            return Date(timeIntervalSince1970:(Double(comment.createTime) / 1000)).timeFormattedForConversation()
        }
        
        var expandActionTitle: String {
            
            if (replies.count == 0 && comment.replyCount > 0) || repliesCollapsed {
                return R.string.localizable.feedCommentsExpandCount("\(comment.replyCount)")
            } else if replies.count == comment.replyCount && !repliesCollapsed {
                return R.string.localizable.feedCommentsCollapse()
            } else {
                return R.string.localizable.feedCommentsExpandMore()
            }
            
        }
        
        var expandActionIcon: UIImage? {
            return nil
        }
        
        init(with comment: Entity.FeedComment) {
            self.comment = comment
            
            if let replies = comment.replyList?.map({ ReplyViewModel(with: $0) }) {
                repliesRelay.accept(replies)
            }
            hasMoreReplies = (comment.replyList?.count ?? 0) < comment.replyCount
        }
        
        private func expandReplies() -> Single<Void> {
            
            guard hasMoreReplies,
                  !isLoading else {
                return Single.just(())
            }
            
            isLoading = true
            
            let skipMs = repliesRelay.value.last?.reply.createTime ?? 0
            
            return Request.commentReplyList(ofComment: comment.cid, skipMs: skipMs)
                .do(onSuccess: { [weak self] (replyList) in
                    guard let `self` = self else { return }
                    
                    var cached = self.repliesRelay.value
                    cached.append(contentsOf: replyList.list.map({ ReplyViewModel(with: $0) }))
                    self.repliesRelay.accept(cached)
                    self.hasMoreReplies = replyList.more
                    self.comment.replyList?.append(contentsOf: replyList.list)
                }, onDispose: { [weak self] in
                    self?.isLoading = false
                }).map { _ in }
        }
        
        func replyToComment(_ comment: CommentViewModel, text: String) -> Single<Void> {
            
            return Request.replyToComment(comment.comment.cid, text: text)
                .do(onSuccess: { [weak self] (reply) in
                    
                    guard let `self` = self else { return }
                    
                    let replyVM = ReplyViewModel(with: reply)
                    
                    var cached = self.repliesRelay.value
                    cached.insert(replyVM, at: 0)
                    self.repliesRelay.accept(cached)
                    self.comment.replyCount += 1
                }).map { _ in }
            
        }
        
        func replyToReply(_ reply: ReplyViewModel, text: String) -> Single<Void> {
            
            return Request.replyToComment(reply.reply.cid, toUid: reply.reply.uid, text: text)
                .do(onSuccess: { [weak self] (reply) in
                    
                    guard let `self` = self else { return }
                    
                    let replyVM = ReplyViewModel(with: reply)
                    
                    var cached = self.repliesRelay.value
                    cached.insert(replyVM, at: 0)
                    self.repliesRelay.accept(cached)
                    self.comment.replyCount += 1

                }).map { _ in }
            
        }
        
        func likeComment(_ liked: Bool) -> Single<Bool> {
            
            let action: Single<Bool>
            
            if liked {
                action = Request.likeComment(comment.cid)
            } else {
                action = Request.cancelLikingComment(comment.cid)
            }
            
            return action.do(onSuccess: { [weak self] (success) in
                guard success else { return }
                self?.comment.isLiked = liked
                
                liked ?
                    (self?.comment.likeCount += 1) :
                    (self?.comment.likeCount -= 1)
            })
            
        }
        
        func deleteReply(_ reply: ReplyViewModel) -> Single<Bool> {
            
            return Request.deleteReply(reply.reply.rid)
                .do(onSuccess: { [weak self] (success) in
                    guard let `self` = self, success else { return }
                    var replies = self.replies
                    replies.removeFirst { $0 === reply }
                    self.repliesRelay.accept(replies)
                })
        }
        
        func expandOrCollapseReplies() -> Single<Void> {
            
            let action: Single<Void>
            
            if hasMoreReplies || repliesCollapsed {
                repliesCollapsed = false
                action = expandReplies()
            } else {
                repliesCollapsed = true
                action = Single.just(())
            }
            
            return action
            
        }
        
    }
    
    class ReplyViewModel {
        
        private(set) var reply: Entity.FeedCommentReply
        private(set) lazy var viewSize: CGSize = ReplyCell.cellSize(for: self)
        
        var content: String {
            
            guard let prefix = atPrefix else {
                return reply.text
            }
            
            return prefix + " " + reply.text
        }
        
        var atPrefix: String? {
            guard let toUser = reply.toUser else {
                return nil
            }
            return "@" + (toUser.name ?? "\(toUser.uid)") + ":"
        }
        
        init(with reply: Entity.FeedCommentReply) {
            self.reply = reply
        }
    }
    
}
