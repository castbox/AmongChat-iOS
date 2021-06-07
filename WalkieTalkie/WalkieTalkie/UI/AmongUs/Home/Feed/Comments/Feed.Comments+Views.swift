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
            iv.isUserInteractionEnabled = true
            iv.addGestureRecognizer(avatarTap)
            return iv
        }()
                
        private lazy var avatarTap: UITapGestureRecognizer = {
            let g = UITapGestureRecognizer()
            g.rx.event
                .subscribe(onNext: { [weak self] (_) in
                    self?.avatarTapHandler?()
                })
                .disposed(by: bag)

            return g
        }()
        
        private var avatarTapHandler: (() -> Void)? = nil
        
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
                    guard let `self` = self else { return }
                    AmongChat.Login.doLogedInEvent(style: .authNeeded(source: .comment)) { [weak self] in
                        btn.isSelected = !btn.isSelected
                        self?.likeHandler?(btn.isSelected)
                    }
                })
                .disposed(by: bag)
            return btn
        }()
        
        private lazy var commentLabel: UILabel = {
            let l = UILabel()
            l.font = R.font.nunitoExtraBold(size: 14)
            l.textColor = .white
            l.numberOfLines = 0
            l.isUserInteractionEnabled = true
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
                    guard let `self` = self else { return }
                    AmongChat.Login.doLogedInEvent(style: .authNeeded(source: .comment)) { [weak self] in
                        self?.replyHandler?()
                    }
                })
                .disposed(by: bag)
            return btn
        }()
        
        private var likeHandler: ((_ liked: Bool) -> Void)? = nil
        private var replyHandler: (() -> Void)? = nil
        private var moreActionHandler: (() -> Void)? = nil
        
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
            
            let commentTap = UITapGestureRecognizer()
            commentLabel.addGestureRecognizer(commentTap)
            commentTap.rx.event
                .subscribe(onNext: { [weak self] (_) in
                    self?.replyHandler?()
                })
                .disposed(by: bag)
            
            let longPress = UILongPressGestureRecognizer()
            contentView.addGestureRecognizer(longPress)
            longPress.rx.event
                .subscribe(onNext: { [weak self] (_) in
                    self?.moreActionHandler?()
                })
                .disposed(by: bag)
        }
        
        func bindData(comment: CommentViewModel,
                      likeHandler: @escaping ((_ liked: Bool) -> Void),
                      replyHandler: @escaping (() -> Void),
                      moreActionHandler: @escaping (() -> Void)) {
            avatarView.updateAvatar(with: comment.comment.user)
            nameLabel.text = comment.comment.user.name
            commentLabel.text = comment.comment.text
            likeButton.isSelected = comment.comment.isLiked
            likeButton.setTitle("\(comment.comment.likeCount)", for: .normal)
            timeLabel.text = comment.timeString
            self.likeHandler = { [weak self] liked in
                
                guard let `self` = self else { return }
                
                guard var count = Int(self.likeButton.title(for: .normal) ?? "") else { return }
                liked ? (count += 1) : (count -= 1)
                self.likeButton.setTitle("\(max(0, count))", for: .normal)
            }
            self.replyHandler = replyHandler
            self.moreActionHandler = moreActionHandler
            self.avatarTapHandler = {
                Routes.handle("/profile/\(comment.comment.uid)")
            }
        }
    }
    
}

extension Feed.Comments {
    
    class ReplyCell: UICollectionViewCell {
        
        private static let commentTop: CGFloat = 26
        private static let commentLeading: CGFloat = Frame.horizontalBleedWidth + 84
        private static let commentTrailing: CGFloat = Frame.horizontalBleedWidth
        private static let commentFont = R.font.nunitoExtraBold(size: 14) ?? UIFont.systemFont(ofSize: 14, weight: .black)
        private static let commentBottom: CGFloat = 21

        static func cellSize(for reply: Feed.Comments.ReplyViewModel) -> CGSize {
            
            let commentHeight = reply.content.height(forConstrainedWidth: UIScreen.main.bounds.width - commentLeading - commentTrailing, font: Self.commentFont)
            
            let height = ceil(commentTop + commentHeight + commentBottom)
            return CGSize(width: UIScreen.main.bounds.width, height: height)
        }
        
        private let bag = DisposeBag()
        
        private lazy var avatarView: AvatarImageView = {
            let iv = AvatarImageView()
            iv.isUserInteractionEnabled = true
            iv.addGestureRecognizer(avatarTap)
            return iv
        }()
                
        private lazy var avatarTap: UITapGestureRecognizer = {
            let g = UITapGestureRecognizer()
            g.rx.event
                .subscribe(onNext: { [weak self] (_) in
                    self?.avatarTapHandler?()
                })
                .disposed(by: bag)

            return g
        }()
        
        private var avatarTapHandler: (() -> Void)? = nil

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
        
        private lazy var atButton: UIButton = {
            let b = UIButton(type: .custom)
            b.titleLabel?.font = R.font.nunitoExtraBold(size: 14)
            b.setTitleColor(.clear, for: .normal)
            b.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { [weak self] (_) in
                    self?.tapAtHandler?()
                })
                .disposed(by: bag)
            return b
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
        
        private var replyHandler: (() -> Void)? = nil
        private var moreActionHandler: (() -> Void)? = nil
        private var tapAtHandler: (() -> Void)? = nil
        
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
            
            contentView.addSubviews(views: avatarView, nameLabel, commentLabel, atButton, timeLabel, replyButton)
            
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
            
            atButton.snp.makeConstraints { (maker) in
                maker.top.leading.equalTo(commentLabel)
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
            
            let tap = UITapGestureRecognizer()
            contentView.addGestureRecognizer(tap)
            tap.rx.event
                .subscribe(onNext: { [weak self] (_) in
                    self?.replyHandler?()
                })
                .disposed(by: bag)
            
            let longPress = UILongPressGestureRecognizer()
            contentView.addGestureRecognizer(longPress)
            longPress.rx.event
                .subscribe(onNext: { [weak self] (_) in
                    self?.moreActionHandler?()
                })
                .disposed(by: bag)
        }
        
        func bindData(reply: ReplyViewModel,
                      tapAtHandler: @escaping (() -> Void),
                      replyHandler: @escaping (() -> Void),
                      moreActionHandler: @escaping (() -> Void)) {
            avatarView.updateAvatar(with: reply.reply.user)
            nameLabel.text = reply.reply.user.name
            let attComment = NSMutableAttributedString(string: reply.content)
            let atRange = (reply.content as NSString).range(of: reply.atPrefix)
            attComment.addAttributes([.foregroundColor : UIColor(hex6: 0x866EEF)], range: atRange)
            commentLabel.attributedText = attComment
            atButton.setTitle(reply.atPrefix, for: .normal)
            timeLabel.text = reply.timeString
            self.replyHandler = replyHandler
            self.moreActionHandler = moreActionHandler
            self.tapAtHandler = tapAtHandler
            self.avatarTapHandler = {
                Routes.handle("/profile/\(reply.reply.uid)")
            }
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
            
            btn.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
            btn.titleLabel?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
            btn.imageView?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
            return btn
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setUpLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private(set) var tapAction: (() -> Void)? = nil
        
        private func setUpLayout() {
            
            backgroundColor = .clear
            contentView.backgroundColor = .clear
            
            contentView.addSubviews(views: actionButton)
            
            actionButton.snp.makeConstraints { (maker) in
                maker.leading.equalToSuperview().offset(Frame.horizontalBleedWidth + 52)
                maker.bottom.equalToSuperview()
                maker.height.equalTo(19)
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

extension Feed.Comments {
    
    class CommentInputView: UIView, UITextViewDelegate {
        
        private let bag = DisposeBag()
        
        private let maxInputLength = Int(280)
        private let textViewMinHeight = CGFloat(22)
        private let textViewMaxHeight = CGFloat(65)
        
        private let sendSignal = PublishSubject<Void>()
        
        var enableAutoResizeHeight = true
        
        var sendObservable: Observable<Void> {
            return sendSignal.asObservable()
        }
        
        private(set) lazy var inputTextView: UITextView = {
            let f = UITextView()
            f.backgroundColor = .clear
            f.keyboardAppearance = .dark
            f.returnKeyType = .send
            f.textContainerInset = .zero
            f.textContainer.lineFragmentPadding = 0
            f.delegate = self
            f.font = R.font.nunitoBold(size: 16)
            f.textColor = .white
            f.rx.text
                .subscribe(onNext: { [weak self] (text) in
                    
                    guard let `self` = self else { return }
                    
                    self.placeholderLabel.isHidden = (text != nil) && text!.count > 0
                    
                })
                .disposed(by: bag)
            f.showsVerticalScrollIndicator = false
            f.showsHorizontalScrollIndicator = false
            return f
        }()
        
        private(set) lazy var placeholderLabel: UILabel = {
            let l = UILabel()
            l.numberOfLines = 0
            l.font = R.font.nunitoBold(size: 16)
            l.textColor = UIColor(hex6: 0x646464)
            l.text = R.string.localizable.feedCommentsPlaceholder()
            return l
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setUpLayout()
            setUpEvents()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setUpLayout() {
            
            backgroundColor = UIColor(hex6: 0x2B2B2B)
            layer.cornerRadius = 20
            layer.masksToBounds = true
            
            addSubviews(views: inputTextView, placeholderLabel)
            
            inputTextView.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview().inset(UIEdgeInsets(top: 9, left: 16, bottom: 9, right: 16))
                maker.height.equalTo(textViewMinHeight)
            }
            
            placeholderLabel.snp.makeConstraints { (maker) in
                maker.leading.centerY.equalTo(inputTextView)
            }
        }
        
        func setUpEvents() {
            
            inputTextView.rx.text
                .subscribe(onNext: { [weak self] (_) in
                    guard let `self` = self, self.enableAutoResizeHeight else { return }
                    
                    let height = self.inputTextView.contentSize.height
                    self.inputTextView.snp.updateConstraints { (maker) in
                        maker.height.equalTo(min(self.textViewMaxHeight, max(self.textViewMinHeight, height)))
                    }
                })
                .disposed(by: bag)
            
            inputTextView.isEditable = AmongChat.Login.isLogedin
            
            if !AmongChat.Login.isLogedin {
                inputTextView.rx.tapGesture()
                    .when(.recognized)
                    .subscribe(onNext: { [weak self] gesture in
                        let style: AmongChat.Login.LoginStyle = .authNeeded(source: .comment)
                        AmongChat.Login.doLogedInEvent(style: style) { [weak self] in
                            self?.inputTextView.removeGestureRecognizer(gesture)
                            self?.inputTextView.isEditable = true
                            _ = self?.inputTextView.becomeFirstResponder()
                        }
                    })
                    .disposed(by: bag)
            }
        }
        
        // MARK: - UITextView Delegate
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            guard let textFieldText = textView.text,
                  let rangeOfTextToReplace = Range(range, in: textFieldText) else {
                return false
            }
            
            if text == "\n"{
                // do your stuff here
                // return false here, if you want to disable user from adding newline
                textView.resignFirstResponder()
                sendSignal.onNext(())
                return false
            }
            
            let substringToReplace = textFieldText[rangeOfTextToReplace]
            let count = textFieldText.count - substringToReplace.count + text.count
            return count <= maxInputLength
        }
        
    }
    
}
