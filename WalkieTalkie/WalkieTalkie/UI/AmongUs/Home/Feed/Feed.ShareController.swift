//
//  FeedShareController.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 22/06/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import MessageUI
import PullToDismiss

extension Feed {
    class ShareController: ViewController {
        
        enum Style {
            case `default`
            case showInputBar
        }
        
        enum Action {
            case error(String?)
            case share(Feed.ShareBar.ShareSource)
            case moreSelectUser([Entity.UserProfile])
        }
        
        private lazy var titleLabel: UILabel = {
            let lb = UILabel()
            lb.textAlignment = .center
            lb.font = R.font.nunitoExtraBold(size: 16)
            lb.textColor = .white
            lb.text = R.string.localizable.feedShareWith()
            lb.adjustsFontSizeToFitWidth = true
            return lb
        }()
        
        private lazy var backgroundView: UIView = {
            let v = UIView()
            v.backgroundColor = .clear
            return v
        }()
        
        private lazy var container: UIScrollView = {
            let v = UIScrollView()
            v.backgroundColor = "222222".color()
            v.alwaysBounceVertical = true
            v.showsVerticalScrollIndicator = false
            v.showsHorizontalScrollIndicator = false
            return v
        }()
        
        private lazy var userViews: Feed.ShareUserView = {
            let v = Feed.ShareUserView()
            v.backgroundColor = .clear
            return v
        }()
        
        private lazy var shareBar: Feed.ShareBar = {
            let v = Feed.ShareBar()
            v.backgroundColor = .clear
            //            v.addCorner(with: 20, corners: [.topLeft, .topRight])
            return v
        }()
        
        private lazy var inputBar: Feed.Share.ShareInputView = {
            let v = Feed.Share.ShareInputView()
            v.backgroundColor = .clear
            let subviews = v.subviews
            subviews.first(where: { $0 is GradientView })?.removeFromSuperview()
            //            v.addCorner(with: 20, corners: [.topLeft, .topRight])
            return v
        }()
        
        private let feed: Entity.Feed
        
        private var isAnonymousUser = Settings.shared.amongChatUserProfile.value?.isAnonymous ?? false
        private let kScreenH = UIScreen.main.bounds.height
        private var beginLocation: CGPoint = .zero
        private var beginContainerYOffset: CGFloat = 0
        private var containerHeight: CGFloat {
            guard !isAnonymousUser else {
                return 210
            }
            if selectedUsers.isEmpty {
                return containerStyle.height
            } else {
                return 397 + Frame.Height.safeAeraBottomHeight
            }
        }
        
        private var containerStyle: Style = .default {
            didSet {
                inputBar.isHidden = containerStyle == .default
                shareBar.isHidden = !inputBar.isHidden
            }
        }
        
        private var shareUrl: String {
            return "https://among.chat/feeds/\(feed.pid)"
        }
        
        private var shareText: String {
            return R.string.localizable.feedThirdShareContent(shareUrl)
        }
        
        
        private var selectedUsers: [Entity.UserProfile] = [] {
            didSet {
                //                selectedUsersHandler?(selectedUsers)
                containerStyle = selectedUsers.isEmpty ? .default : .showInputBar
                //update height
                self.container.snp.updateConstraints { maker in
                    maker.height.equalTo(containerHeight)
                }
                UIView.springAnimate { [weak self] in
                    self?.view.layoutIfNeeded()
                }
            }
        }
        
        var dismissHandler: ((Action) -> Void)?
        
        private var pullToDismiss: PullToDismiss?
        
        init(with feed: Entity.Feed) {
            self.feed = feed
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            configureSubview()
            bindSubviewEvent()
        }
        
        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            container.addCorner(with: 20, corners: [.topLeft, .topRight])
        }
    }
}

extension Feed.ShareController {
    func sendShare() {
        let removeHandler = container.raft.show(.loading)
        //send message
        Request.feedShareToUser(feed, uids: selectedUsers.map { $0.uid }, text: inputBar.inputTextView.text?.trim() ?? "")
            .subscribe(onSuccess: { [weak self] result in
                removeHandler()
                self?.view.endEditing(true)
                let anonymousUsers = result?.uidsAnonymous ?? []
                self?.dismissModal(animated: true, completion: { [weak self] in
                    self?.dismissHandler?(.error(anonymousUsers.isEmpty ? "": R.string.localizable.feedShareToAnonymousUserTips()))
                })
            }, onError: { error in
                removeHandler()
            })
            .disposed(by: bag)
    }
    
    func bindSubviewEvent() {
        if !Settings.loginUserIsAnonymous {
            DMManager.shared.conversations()
                .map { $0.map { $0.fromUid } }
                .flatMap { Request.feedShareUserList($0) }
                .subscribe(onSuccess: { [weak self] result in
                    self?.userViews.bind(result ?? [])
                }, onError: { error in
                    
                })
                .disposed(by: bag)            
        }
        
        userViews.selectedUsersHandler = { [weak self] users in
            self?.selectedUsers = users
        }
        
        userViews.tapMoreHandler = { [weak self] in
            guard let `self` = self else { return }
            let user = self.selectedUsers
            self.dismissModal(animated: true, completion: { [weak self] in
                self?.dismissHandler?(.moreSelectUser(user))
            })
        }
        
        shareBar.selectedSourceObservable
            .subscribe(onNext: { [weak self] source in
                self?.dismissModal(animated: true, completion: { [weak self] in
                    self?.dismissHandler?(.share(source))
                })
            })
            .disposed(by: bag)
        
        backgroundView.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                self?.dismissModal()
            })
            .disposed(by: bag)
        
        inputBar.imageView.setImage(with: feed.img)
        
        inputBar.sendObservable
            .subscribe(onNext: { [weak self] in
                self?.sendShare()
            })
            .disposed(by: bag)
        
        RxKeyboard.instance.visibleHeight
            .drive(onNext: { [weak self] keyboardVisibleHeight in
                guard let `self` = self else { return }
                var bottomOffset = keyboardVisibleHeight
                if keyboardVisibleHeight > 0 {
                    bottomOffset = keyboardVisibleHeight - (8 + Frame.Height.safeAeraBottomHeight)
                }
                self.container.snp.updateConstraints { (maker) in
                    maker.bottom.equalToSuperview().offset(-bottomOffset)
                }
                UIView.animate(withDuration: 0) {
                    self.view.layoutIfNeeded()
                }
            })
            .disposed(by: bag)
        
    }
    
    func configureSubview() {
        view.backgroundColor = .clear
        view.addSubviews(views: backgroundView, container)
        inputBar.isHidden = true
        
        pullToDismiss = PullToDismiss(scrollView: container)
        pullToDismiss?.dismissableHeightPercentage = 0.1
        pullToDismiss?.backgroundEffect = ShadowEffect(color: .black, alpha: 0)
        pullToDismiss?.dismissAction = { [weak self] in
            self?.dismissModal()
        }
        
        let line = UIView()
        line.backgroundColor = UIColor.white.alpha(0.2)
        line.cornerRadius = 2
        
        container.addSubviews(views: line, titleLabel, userViews, shareBar, inputBar)
        
        line.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(8)
            maker.width.equalTo(36)
            maker.height.equalTo(4)
        }
        
        backgroundView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        
        container.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.equalToSuperview()
            maker.height.equalTo(containerHeight)
        }
        
        titleLabel.snp.makeConstraints { maker in
            maker.top.equalTo(32)
            maker.centerX.equalToSuperview()
        }
        
        userViews.snp.makeConstraints { maker in
            maker.top.equalTo(titleLabel.snp.bottom).offset(20)
            maker.leading.trailing.equalToSuperview()
            maker.width.equalTo(Frame.Screen.width)
            maker.height.equalTo(94)
        }
        
        shareBar.snp.makeConstraints { maker in
            maker.top.equalTo(userViews.snp.bottom).offset(40)
            maker.leading.trailing.equalToSuperview()
            maker.width.equalTo(Frame.Screen.width)
            maker.height.equalTo(75)
        }
        
        inputBar.snp.makeConstraints { maker in
            maker.top.equalTo(userViews.snp.bottom)
            maker.leading.trailing.equalToSuperview()
            maker.width.equalTo(Frame.Screen.width)
            maker.height.equalTo(229 + Frame.Height.safeAeraBottomHeight)
        }
    }
}

extension Feed.ShareController.Style {
    var height: CGFloat {
        let height: CGFloat = self == .default ? 323 : 497
        return height + Frame.Height.safeAeraBottomHeight
    }
}

extension Feed.ShareController: Modalable {
    
    func style() -> Modal.Style {
        return .customHeight
    }
    
    func height() -> CGFloat {
        return Frame.Screen.height
    }
    
    func modalPresentationStyle() -> UIModalPresentationStyle {
        return .overCurrentContext
    }
    
    override func cornerRadius() -> CGFloat {
        return 0
    }
    
    func coverAlpha() -> CGFloat {
        return 0.2
    }
    
}
