//
//  Feed.Comments+Views.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/5/27.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension Feed.Comments {
    
    class CommentCell: UICollectionViewCell {
        
        private static let commentTop: CGFloat = 24
        private static let commentLeading: CGFloat = Frame.horizontalBleedWidth + 52
        private static let commentTrailing: CGFloat = Frame.horizontalBleedWidth
        private static let commentBottom: CGFloat = 21
        private static let commentFont = R.font.nunitoExtraBold(size: 14) ?? UIFont.systemFont(ofSize: 14, weight: .black)
        
        static func cellSize(for comment: Feed.Comments.CommentViewModel) -> CGSize {
            
            let commentHeight = comment.comment.text.height(forConstrainedWidth: UIScreen.main.bounds.width - commentLeading - commentTrailing, font: Self.commentFont)
            
            let height = ceil(commentTop + commentHeight + commentBottom)
            return CGSize(width: UIScreen.main.bounds.width, height: height)
        }
        
        private let bag = DisposeBag()
        
        private lazy var avatarView: AvatarImageView = {
            let iv = AvatarImageView()
            return iv
        }()
        
        private lazy var nameLabel: UILabel = {
            let l = UILabel()
            l.font = R.font.nunitoExtraBold(size: 16)
            l.textColor = UIColor(hex6: 0x898989)
            return l
        }()
        
        private lazy var likeButton: UIButton = {
            let btn = SmallSizeButton(type: .custom)
            btn.titleLabel?.font = R.font.nunitoBold(size: 14)
            btn.setTitleColor(UIColor(hex6: 0x898989), for: .normal)
            btn.setTitleColor(UIColor(hex6: 0xF03D5D), for: .selected)
            btn.setImage(R.image.ac_feed_like_normal(), for: .normal)
            btn.setImage(R.image.ac_feed_like_liked(), for: .selected)
            btn.titleEdgeInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: -2)
            btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: -2, bottom: 0, right: 2)
            btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: 2)
            btn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] (_) in
                    btn.isSelected = !btn.isSelected
                    self?.likeHandler?(btn.isSelected)
                })
                .disposed(by: bag)
            return btn
        }()
        
        private lazy var commentLabel: UILabel = {
            let l = UILabel()
            l.font = R.font.nunitoExtraBold(size: 14)
            l.textColor = .white
            l.numberOfLines = 0
            return l
        }()
        
        private lazy var timeLabel: UILabel = {
            let l = UILabel()
            l.font = R.font.nunitoSemiBold(size: 14)
            l.textColor = UIColor(hex6: 0x898989)
            return l
        }()
        
        private lazy var replyButton: UIButton = {
            let btn = SmallSizeButton(type: .custom)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 14)
            btn.setTitleColor(UIColor(hex6: 0x898989), for: .normal)
            btn.setTitle(R.string.localizable.amongChatReply(), for: .normal)
            btn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] (_) in
                    self?.replyHandler?()
                })
                .disposed(by: bag)
            return btn
        }()
        
        private var likeHandler: ((_ liked: Bool) -> Void)? = nil
        private var replyHandler: (() -> Void)? = nil
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setUpLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setUpLayout() {
            
            backgroundColor = .clear
            contentView.backgroundColor = .clear
            
            contentView.addSubviews(views: avatarView, nameLabel, likeButton, commentLabel, timeLabel, replyButton)
            
            avatarView.snp.makeConstraints { (maker) in
                maker.leading.equalToSuperview().offset(Frame.horizontalBleedWidth)
                maker.top.equalToSuperview()
                maker.width.height.equalTo(40)
            }
            
            nameLabel.snp.makeConstraints { (maker) in
                maker.top.equalToSuperview()
                maker.leading.equalTo(avatarView.snp.trailing).offset(12)
                maker.trailing.lessThanOrEqualTo(likeButton.snp.leading).offset(-12)
                maker.height.equalTo(22)
            }
            
            likeButton.snp.makeConstraints { (maker) in
                maker.centerY.equalTo(nameLabel)
                maker.trailing.equalToSuperview().offset(-Frame.horizontalBleedWidth)
            }
            
            commentLabel.snp.makeConstraints { (maker) in
                maker.leading.equalTo(Self.commentLeading)
                maker.trailing.equalToSuperview().inset(Self.commentTrailing)
                maker.top.equalTo(Self.commentTop)
            }
            
            timeLabel.snp.makeConstraints { (maker) in
                maker.leading.equalTo(nameLabel)
                maker.top.equalTo(commentLabel.snp.bottom).offset(2)
                maker.height.equalTo(19)
            }
            
            replyButton.snp.makeConstraints { (maker) in
                maker.leading.equalTo(timeLabel.snp.trailing).offset(40)
                maker.centerY.equalTo(timeLabel)
                maker.trailing.lessThanOrEqualToSuperview().offset(-Frame.horizontalBleedWidth)
            }
            
        }
        
        func bindData(comment: CommentViewModel,
                      likeHandler: @escaping ((_ liked: Bool) -> Void),
                      replyHandler: @escaping (() -> Void)) {
            avatarView.updateAvatar(with: comment.comment.user)
            nameLabel.text = comment.comment.user.name
            commentLabel.text = comment.comment.text
            likeButton.isSelected = comment.comment.isLiked
            likeButton.setTitle("\(comment.comment.likeCount)", for: .normal)
            timeLabel.text = comment.timeString
            self.likeHandler = { [weak self] liked in
                
                guard let `self` = self else { return }
                
                likeHandler(liked)
                
                guard var count = Int(self.likeButton.title(for: .normal) ?? "") else { return }
                liked ? (count += 1) : (count -= 1)
                self.likeButton.setTitle("\(max(0, count))", for: .normal)
            }
            self.replyHandler = replyHandler
        }
    }
    
}

extension Feed.Comments {
    
    class ReplyCell: UICollectionViewCell {
        
        private static let commentTop: CGFloat = 26
        private static let commentLeading: CGFloat = Frame.horizontalBleedWidth + 84
        private static let commentTrailing: CGFloat = Frame.horizontalBleedWidth
        private static let commentFont = R.font.nunitoExtraBold(size: 14) ?? UIFont.systemFont(ofSize: 14, weight: .black)
        
        static func cellSize(for reply: Feed.Comments.ReplyViewModel) -> CGSize {
            
            let commentHeight = reply.content.height(forConstrainedWidth: UIScreen.main.bounds.width - commentLeading - commentTrailing, font: Self.commentFont)
            
            let height = ceil(commentTop + commentHeight)
            return CGSize(width: UIScreen.main.bounds.width, height: height)
        }
        
        private lazy var avatarView: AvatarImageView = {
            let iv = AvatarImageView()
            return iv
        }()
        
        private lazy var nameLabel: UILabel = {
            let l = UILabel()
            l.font = R.font.nunitoExtraBold(size: 16)
            l.textColor = UIColor(hex6: 0x898989)
            return l
        }()
        
        private lazy var commentLabel: UILabel = {
            let l = UILabel()
            l.font = R.font.nunitoExtraBold(size: 14)
            l.textColor = .white
            l.numberOfLines = 0
            return l
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setUpLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setUpLayout() {
            
            backgroundColor = .clear
            contentView.backgroundColor = .clear
            
            contentView.addSubviews(views: avatarView, nameLabel, commentLabel)
            
            avatarView.snp.makeConstraints { (maker) in
                maker.leading.equalToSuperview().inset(Frame.horizontalBleedWidth + 52)
                maker.top.equalToSuperview()
                maker.width.height.equalTo(24)
            }
            
            nameLabel.snp.makeConstraints { (maker) in
                maker.top.equalToSuperview()
                maker.leading.equalTo(avatarView.snp.trailing).offset(8)
                maker.trailing.equalToSuperview().inset(Frame.horizontalBleedWidth)
                maker.height.equalTo(22)
            }
            
            commentLabel.snp.makeConstraints { (maker) in
                maker.leading.equalTo(Self.commentLeading)
                maker.trailing.equalToSuperview().inset(Self.commentTrailing)
                maker.top.equalTo(Self.commentTop)
            }
        }
        
        func bindData(reply: ReplyViewModel) {
            avatarView.updateAvatar(with: reply.reply.user)
            nameLabel.text = reply.reply.user.name
            commentLabel.text = reply.content
        }
        
    }
}

extension Feed.Comments {
    
    class ExpandReplyCell: UICollectionViewCell {
        
        private let bag = DisposeBag()
        
        private lazy var actionButton: UIButton = {
            let btn = SmallSizeButton(type: .custom)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 16)
            btn.setTitleColor(UIColor(hex6: 0x898989), for: .normal)
            btn.setImage(R.image.ac_feed_like_normal(), for: .normal)
            btn.titleEdgeInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: -2)
            btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: -2, bottom: 0, right: 2)
            btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: 2)
            btn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] (_) in
                    self?.tapAction?()
                })
                .disposed(by: bag)
            return btn
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setUpLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private var tapAction: (() -> Void)? = nil
        
        private func setUpLayout() {
            
            backgroundColor = .clear
            contentView.backgroundColor = .clear
            
            contentView.addSubviews(views: actionButton)
            
            actionButton.snp.makeConstraints { (maker) in
                maker.leading.equalToSuperview().offset(Frame.horizontalBleedWidth + 52)
                maker.top.bottom.equalToSuperview()
                maker.trailing.lessThanOrEqualToSuperview().offset(-Frame.horizontalBleedWidth)
            }
        }
        
        func bindData(comment: CommentViewModel, tapAction: @escaping (() -> Void)) {
            actionButton.setTitle(comment.expandActionTitle, for: .normal)
            actionButton.setImage(comment.expandActionIcon, for: .normal)
            self.tapAction = tapAction
        }
        
    }
    
}
