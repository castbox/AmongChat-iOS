//
//  AmongChat.Home+RelationsViews.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/12/25.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import SnapKit
import Koloda

extension AmongChat.Home {
    
    class UserView: UIView {
        
        private let bag = DisposeBag()
        
        private lazy var avatarIV: AvatarImageView = {
            let iv = AvatarImageView()
            iv.layer.cornerRadius = 20
            iv.layer.masksToBounds = true
            iv.isUserInteractionEnabled = true
            iv.addGestureRecognizer(avatarTap)
            return iv
        }()
        
        private lazy var avatarTap: UITapGestureRecognizer = {
            let g = UITapGestureRecognizer()
            g.rx.event
                .subscribe(onNext: { [weak self] (_) in
                    
                    guard let `self` = self else { return }
                    
                    if let h = self.avatarTapHandler {
                        h()
                    } else if let uid = self.uid {
                        Routes.handle("/profile/\(uid)")
                    }
                    
                })
                .disposed(by: bag)

            return g
        }()
        
        private var avatarTapHandler: (() -> Void)? = nil
                
        private lazy var nameLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 16)
            lb.textColor = .white
            return lb
        }()
        
        private lazy var statusLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoBold(size: 14)
            lb.textColor = UIColor(hex6: 0x898989)
            lb.adjustsFontSizeToFitWidth = true
            return lb
        }()
        
        private var uid: Int? = nil
        
        override init(frame: CGRect) {
            super.init(frame: .zero)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupLayout() {
            backgroundColor = .clear
            
            addSubviews(views: avatarIV, nameLabel, statusLabel)
            
            avatarIV.snp.makeConstraints { (maker) in
                maker.width.height.equalTo(40)
                maker.centerY.equalToSuperview()
                maker.leading.equalToSuperview()
            }
            
            let textLayout = UILayoutGuide()
            addLayoutGuide(textLayout)
            
            textLayout.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.leading.equalTo(avatarIV.snp.trailing).offset(12)
                maker.trailing.equalToSuperview()
            }
            
            nameLabel.snp.makeConstraints { (maker) in
                maker.leading.top.trailing.equalTo(textLayout)
            }
            
            statusLabel.snp.makeConstraints { (maker) in
                maker.top.equalTo(nameLabel.snp.bottom)
                maker.leading.trailing.bottom.equalTo(textLayout)
            }
            
        }
        
        func bind(viewModel: PlayingViewModel, onAvatarTap: @escaping () -> Void) {
            uid = viewModel.uid
            avatarIV.updateAvatar(with: viewModel.playingModel.user)
            
            nameLabel.attributedText = viewModel.userName
            
            statusLabel.text = viewModel.playingStatus
            avatarTapHandler = onAvatarTap
        }
        
        func bind(viewModel: Entity.ContactFriend, onAvatarTap: @escaping () -> Void) {
            
            avatarIV.image = R.image.ac_profile_avatar()
            
            nameLabel.text = viewModel.name
            if viewModel.count == 1 {
                statusLabel.text = R.string.localizable.socialOneContactFirend(viewModel.count.string)
            } else {
                
                statusLabel.text = R.string.localizable.socialContactFirendsCount(viewModel.count.string)
            }
        }
        
        func bind(viewModel: Entity.UserProfile, onAvatarTap: @escaping () -> Void) {
            uid = viewModel.uid
            avatarIV.updateAvatar(with: viewModel)
            
            nameLabel.attributedText = viewModel.nameWithVerified()
//            if viewModel.count == 1 {
//                statusLabel.text = R.string.localizable.socialOneContactFirend(viewModel.count.string)
//            } else {
//                
//                statusLabel.text = R.string.localizable.socialContactFirendsCount(viewModel.count.string)
//            }
        }
        
        func bind(profile: Entity.UserProfile, onAvatarTap: (() -> Void)? = nil) {
            uid = profile.uid
            avatarIV.updateAvatar(with: profile)
            nameLabel.attributedText = profile.nameWithVerified()
            avatarTapHandler = onAvatarTap
        }
    }
    
    class FriendCell: UICollectionViewCell {
        
        private lazy var userView: UserView = {
            let v = UserView()
            return v
        }()
        
        private lazy var joinBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 14)
            btn.setTitleColor(UIColor.black, for: .normal)
            btn.backgroundColor = UIColor(hex6: 0xFFF000)
            btn.setTitle(R.string.localizable.socialJoinAction().uppercased(), for: .normal)
            btn.layer.masksToBounds = true
            btn.layer.cornerRadius = 16
            btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
            btn.setContentHuggingPriority(.required, for: .horizontal)
            return btn
        }()
        
        private var joinDisposable: Disposable? = nil
        
        private lazy var lockedIcon: UIButton = {
            let btn = UIButton(type: .custom)
            btn.setImage(R.image.ac_home_friends_locked(), for: .normal)
            return btn
        }()
        private var lockedDisposable: Disposable? = nil
        
        override init(frame: CGRect) {
            super.init(frame: .zero)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupLayout() {
            contentView.backgroundColor = .clear
            
            contentView.addSubviews(views: userView, joinBtn, lockedIcon)
            
            let buttonLayout = UILayoutGuide()
            contentView.addLayoutGuide(buttonLayout)
            buttonLayout.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.trailing.equalToSuperview().inset(20)
                maker.height.equalTo(32)
            }
            
            userView.snp.makeConstraints { (maker) in
                maker.leading.equalToSuperview().offset(20)
                maker.top.bottom.equalToSuperview()
                maker.trailing.equalTo(buttonLayout.snp.leading).offset(-20)
            }
            
            joinBtn.snp.makeConstraints { (maker) in
                maker.edges.equalTo(buttonLayout)
            }
            
            lockedIcon.snp.makeConstraints { (maker) in
                maker.trailing.centerY.equalTo(buttonLayout)
            }
            
        }
        
        func bind(viewModel: PlayingViewModel,
                  onJoin: @escaping (_ roomId: String, _ topicId: String) -> Void,
                  onAvatarTap: @escaping () -> Void) {
            userView.bind(viewModel: viewModel, onAvatarTap: onAvatarTap)
            
            if let state = viewModel.roomState {
                joinBtn.isHidden = !(state == .public)
                lockedIcon.isHidden = !(state == .private)
            } else {
                joinBtn.isHidden = true
                lockedIcon.isHidden = true
            }
            
            joinDisposable?.dispose()
            joinDisposable = joinBtn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { (_) in
                    guard let roomId = viewModel.roomId,
                          let topicId = viewModel.roomTopicId else {
                        return
                    }
                    onJoin(roomId, topicId)
                })
            
            lockedDisposable?.dispose()
            lockedDisposable = lockedIcon.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { (_) in
                    guard let roomId = viewModel.roomId,
                          let topicId = viewModel.roomTopicId else {
                        return
                    }
                    onJoin(roomId, topicId)
                })
        }
        
    }
    
    class SuggestionCell: UICollectionViewCell {
        
        private lazy var userView: UserView = {
            let v = UserView()
            return v
        }()
        
        private lazy var followBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 14)
            btn.setTitleColor(UIColor(hex6: 0xFFF000), for: .normal)
            btn.setTitleColor(UIColor(hex6: 0x898989), for: .disabled)
            btn.layer.borderColor = UIColor(hex6: 0xFFF000).cgColor
            btn.setTitle(R.string.localizable.channelUserListFollow(), for: .normal)
            btn.setTitle(R.string.localizable.profileFollowing(), for: .disabled)
            btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
            btn.layer.masksToBounds = true
            btn.layer.cornerRadius = 16
            btn.layer.borderWidth = 2.5
            btn.setContentHuggingPriority(.required, for: .horizontal)
            return btn
        }()
        private var followDisposable: Disposable? = nil
        
        override init(frame: CGRect) {
            super.init(frame: .zero)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupLayout() {
            contentView.backgroundColor = .clear
            
            contentView.addSubviews(views: userView, followBtn)
            
            let buttonLayout = UILayoutGuide()
            contentView.addLayoutGuide(buttonLayout)
            buttonLayout.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.trailing.equalToSuperview().inset(20)
                maker.height.equalTo(32)
            }
            
            userView.snp.makeConstraints { (maker) in
                maker.leading.equalToSuperview().offset(20)
                maker.top.bottom.equalToSuperview()
                maker.trailing.equalTo(buttonLayout.snp.leading).offset(-20)
            }
            
            followBtn.snp.makeConstraints { (maker) in
                maker.edges.equalTo(buttonLayout)
            }
            
        }
        
        func bind(viewModel: PlayingViewModel,
                  onFollow: @escaping () -> Void,
                  onAvatarTap: @escaping () -> Void) {
            userView.bind(viewModel: viewModel, onAvatarTap: onAvatarTap)
            followDisposable?.dispose()
            followDisposable = followBtn.rx.controlEvent(.primaryActionTriggered)
                .subscribe(onNext: { (_) in
                    onFollow()
                })
        }
        
        
    }
    
    class SuggestedContactView: UIView {
        private lazy var userView: UserView = {
            let v = UserView()
            return v
        }()
        
        private lazy var skipButton: UIButton = {
            let btn = UIButton(type: .custom)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 16)
            btn.setTitleColor(UIColor(hex6: 0xFB5858), for: .normal)
            btn.setTitle(R.string.localizable.profileBirthdaySkip(), for: .normal)
            btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 12)
            btn.layer.masksToBounds = true
            //            btn.layer.cornerRadius = 16
            //            btn.layer.borderWidth = 2.5
            btn.setContentHuggingPriority(.required, for: .horizontal)
            return btn
        }()
        
        private lazy var inviteButton: UIButton = {
            let btn = UIButton(type: .custom)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 16)
            btn.setTitleColor(UIColor(hex6: 0xFFF000), for: .normal)
            //            btn.setTitleColor(UIColor(hex6: 0x898989), for: .disabled)
            //            btn.layer.borderColor = UIColor(hex6: 0xFFF000).cgColor
            btn.setTitle(R.string.localizable.socialInvite(), for: .normal)
            btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 10)
            //            btn.layer.masksToBounds = true
            //            btn.layer.cornerRadius = 16
            //            btn.layer.borderWidth = 2.5
            btn.setContentHuggingPriority(.required, for: .horizontal)
            return btn
        }()
        
        private lazy var lineView: UIView = {
            let view = UIView()
            view.backgroundColor = UIColor.white.alpha(0.12)
            return view
        }()
        
        private var followDisposable: Disposable? = nil
        
        let contact : Entity.ContactFriend?
        let bag = DisposeBag()
        
        private var onSkipHandler: CallBack?
        private var onInviteHandler: CallBack?
        
        init(contact : Entity.ContactFriend?) {
            self.contact = contact
            super.init(frame: .zero)
            setupLayout()
            bindSubviewEvent()
            
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func bindSubviewEvent() {
            
            skipButton.rx.controlEvent(.touchUpInside)
                .subscribe { [weak self] _ in
                    self?.onSkipHandler?()
                }
                .disposed(by: bag)
            
            inviteButton.rx.controlEvent(.touchUpInside)
                .subscribe { [weak self] _ in
                    self?.onInviteHandler?()
                }
                .disposed(by: bag)
            
            guard let contact = contact else {
                return
            }
            userView.bind(viewModel: contact) {
                
            }
        }
        
        private func setupLayout() {
            backgroundColor = "#222222".color()
            cornerRadius = 12
            clipsToBounds = false
            addShadow(ofColor: UIColor.black.alpha(0.6))
            
            addSubviews(views: userView, skipButton, lineView, inviteButton)
            
            let buttonLayout = UILayoutGuide()
            addLayoutGuide(buttonLayout)
            buttonLayout.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.trailing.equalToSuperview().inset(20)
                maker.height.equalTo(32)
            }
            
            userView.snp.makeConstraints { (maker) in
                maker.leading.equalToSuperview().offset(20)
                maker.top.bottom.equalToSuperview()
                maker.trailing.equalTo(buttonLayout.snp.leading)
            }
            
            skipButton.snp.makeConstraints { (maker) in
                maker.top.bottom.equalToSuperview()
                maker.trailing.equalTo(inviteButton.snp.leading)
                maker.leading.equalTo(buttonLayout)
                //                maker.width.equalTo(inviteButton)
            }
            
            lineView.snp.makeConstraints { maker in
                maker.centerY.equalTo(buttonLayout)
                maker.leading.equalTo(skipButton.snp.trailing)
                maker.height.equalTo(24)
                maker.width.equalTo(2)
            }
            
            inviteButton.snp.makeConstraints { (maker) in
                maker.top.bottom.equalToSuperview()
                maker.trailing.equalTo(-6)
            }
            
        }
        
        func bind(onSkip: @escaping () -> Void,
                  onInvite: @escaping () -> Void) {
            self.onSkipHandler = onSkip
            self.onInviteHandler = onInvite
        }
    }
    
    class SuggestedContactCell: UICollectionViewCell, KolodaViewDelegate, KolodaViewDataSource {
        
        private let cardStack = KolodaView()
        private var onSkipHandler: ((Entity.ContactFriend) -> Void)?
        private var onInviteHandler: ((Entity.ContactFriend) -> Void)?
        private var onRunOutOfCardsHandler: CallBack?
        var _dataSource: [ContactViewModel] = []
        var dataSource: [ContactViewModel] {
            set {
                guard _dataSource != newValue else {
                    return
                }
                _dataSource = newValue
                if cardStack.isRunOutOfCards {
                    cardStack.resetCurrentCardIndex()
                }
                cardStack.reloadData()
            }
            get { _dataSource }
        }
        
        override init(frame: CGRect) {
            super.init(frame: .zero)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupLayout() {
            cardStack.backgroundCardsTopMargin = 6
            cardStack.delegate = self
            cardStack.dataSource = self
            cardStack.alphaValueSemiTransparent = 1
            
            contentView.backgroundColor = .clear
            
            contentView.addSubviews(views: cardStack)
            cardStack.appearanceAnimationDuration = 0
            cardStack.snp.makeConstraints { (maker) in
                maker.edges.equalTo(UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 20))
            }
        }
        
        func bind(dataSource: [ContactViewModel],
                  onSkip: @escaping (Entity.ContactFriend) -> Void,
                  onInvite: @escaping (Entity.ContactFriend) -> Void,
                  onRunOutOfCards: @escaping CallBack) {
            self.dataSource = dataSource
            onSkipHandler = onSkip
            onInviteHandler = onInvite
            onRunOutOfCardsHandler = onRunOutOfCards
        }
        
        func kolodaNumberOfCards(_ koloda: KolodaView) -> Int {
            return dataSource.count
        }
        
        func kolodaSpeedThatCardShouldDrag(_ koloda: KolodaView) -> DragSpeed {
            return .default
        }
        
        func koloda(_ koloda: KolodaView, viewForCardAt index: Int) -> UIView {
            guard let contact = dataSource.safe(index)?.contact else {
                return UIView()
            }
            let view = SuggestedContactView(contact: contact)
            view.bind { [weak self] in
                koloda.swipe(.left)
                self?.onSkipHandler?(contact)
            } onInvite: { [weak self] in
                koloda.swipe(.right)
                self?.onInviteHandler?(contact)
            }
            
            return view
        }
        
        //        func koloda(_ koloda: KolodaView, viewForCardOverlayAt index: Int) -> OverlayView? {
        //            return Bundle.main.loadNibNamed("OverlayView", owner: self, options: nil)?[0] as? OverlayView
        //        }
        
        func kolodaDidRunOutOfCards(_ koloda: KolodaView) {
            //            self.dataSource = dataSource
            //            let position = kolodaView.currentCardIndex
            //            for i in 1...4 {
            //              dataSource.append(UIImage(named: "Card_like_\(i)")!)
            //            }
            //            kolodaView.insertCardAtIndexRange(position..<position + 4, animated: true)
            onRunOutOfCardsHandler?()
        }
        
        func koloda(_ koloda: KolodaView, shouldDragCardAt index: Int) -> Bool {
            return false
        }
        
        func koloda(_ koloda: KolodaView, didSelectCardAt index: Int) {
            //            UIApplication.shared.openURL(URL(string: "https://yalantis.com/")!)
        }
    }
    
    
    class FriendSectionHeader: UICollectionReusableView {
        
        private var titleLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 20)
            lb.textColor = .white
            lb.adjustsFontSizeToFitWidth = true
            return lb
        }()
        
        private lazy var seeAllButton: UIButton = {
            let btn = UIButton(type: .custom)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
            btn.setTitleColor(UIColor(hex6: 0x898989), for: .normal)
            btn.setTitle(R.string.localizable.socialSeeAll(), for: .normal)
            btn.isHidden = true
            //            btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
            //            btn.layer.masksToBounds = true
            //            btn.layer.cornerRadius = 16
            //            btn.layer.borderWidth = 2.5
            btn.setContentHuggingPriority(.required, for: .horizontal)
            return btn
        }()
        let bag = DisposeBag()
        
        var seeAllHandler: CallBack?
        var hideSeeAllButton: Bool {
            set { seeAllButton.isHidden = newValue }
            get { seeAllButton.isHidden }
        }
        
        override init(frame: CGRect) {
            super.init(frame: .zero)
            setupLayout()
            seeAllButton.rx.controlEvent(.touchUpInside)
                .subscribe(onNext: { [weak self] _ in
                    self?.seeAllHandler?()
                })
                .disposed(by: bag)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupLayout() {
            addSubviews(views: titleLabel, seeAllButton)
            titleLabel.snp.makeConstraints { (maker) in
                maker.top.bottom.equalToSuperview()
                maker.leading.trailing.equalToSuperview().inset(20)
            }
            
            seeAllButton.snp.makeConstraints { maker in
                maker.trailing.equalTo(-20)
                maker.centerY.equalTo(titleLabel)
            }
        }
        
        func configTitle(_ title: String, constraints: (_ make: ConstraintMaker) -> Void) {
            titleLabel.text = title
            titleLabel.snp.remakeConstraints(constraints)
        }
    }
    
    class FriendShareFooter: UICollectionReusableView {
        
        private lazy var icon: UIImageView = {
            let iv = UIImageView(image: R.image.ac_home_invite())
            iv.backgroundColor = .clear
            return iv
        }()
        
        private lazy var titleLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 16)
            lb.textColor = UIColor(hex6: 0xFFFFFF)
            lb.text = R.string.localizable.amongChatHomeFriendsShareTitle()
            lb.numberOfLines = 2
            lb.adjustsFontSizeToFitWidth = true
            return lb
        }()
        
        private lazy var rightIcon: UIImageView = {
            let i = UIImageView(image: R.image.ac_right_arrow())
            return i
        }()
        
        private lazy var contentView: UIView = {
            let v = UIView()
            v.backgroundColor = UIColor(hex6: 0x222222)
            v.layer.cornerRadius = 12
            return v
        }()
        
        var onSelect: (() -> Void)? = nil
        
        override init(frame: CGRect) {
            super.init(frame: .zero)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupLayout() {
            contentView.addSubviews(views: icon, titleLabel, rightIcon)
            addSubviews(views: contentView)
            icon.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.leading.equalToSuperview().offset(16)
                maker.width.height.equalTo(36)
            }
            
            titleLabel.snp.makeConstraints { (maker) in
                maker.leading.equalTo(icon.snp.trailing).offset(12)
                maker.top.greaterThanOrEqualToSuperview().inset(0)
                maker.centerY.equalToSuperview()
                maker.trailing.equalTo(rightIcon.snp.leading).offset(-16)
            }
            
            rightIcon.snp.makeConstraints { (maker) in
                maker.width.height.equalTo(20)
                maker.centerY.equalToSuperview()
                maker.trailing.equalToSuperview().inset(16)
            }
            
            contentView.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(20)
                maker.top.equalToSuperview().offset(7)
                maker.height.equalTo(68)
            }
            
            isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer()
            addGestureRecognizer(tap)
            let _ = tap.rx.event.bind(onNext: { [weak self] (_) in
                self?.onSelect?()
            })
        }
        
        func configContent(constraints: (_ make: ConstraintMaker) -> Void) {
            contentView.snp.remakeConstraints(constraints)
        }
    }
    
    class EmptyReusableView: UICollectionReusableView {
        
    }
}

extension AmongChat.Home {
    
    class FansGroupBannerCell: UICollectionViewCell {
        
        private static let edgeInset = UIEdgeInsets(top: 24, left: 20, bottom: 24, right: 20)
        
        private let bag = DisposeBag()
        
        class var size: CGSize {
            let h = (Frame.Screen.width - edgeInset.left - edgeInset.right) * 155 / 335 + edgeInset.top + edgeInset.bottom
            return CGSize(width: Frame.Screen.width, height: h)
        }
        
        private lazy var bg: UIImageView = {
            let i = UIImageView(image: R.image.ac_group_banner())
            i.layer.cornerRadius = 24
            i.clipsToBounds = true
            return i
        }()
        
        private lazy var tapGR: UITapGestureRecognizer = {
            let g = UITapGestureRecognizer()
            g.rx.event
                .subscribe(onNext: { [weak self] (_) in
                    self?.tapHandler?()
                })
                .disposed(by: bag)

            return g
        }()
        
        var tapHandler: (() -> Void)? = nil
        
        override init(frame: CGRect) {
            super.init(frame: .zero)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
                
        private func setupLayout() {
            
            contentView.backgroundColor = .clear
            contentView.addGestureRecognizer(tapGR)
            
            contentView.addSubviews(views: bg)
            
            bg.snp.makeConstraints { (maker) in
                maker.edges.equalTo(Self.edgeInset)
            }
        }
        
    }

}
