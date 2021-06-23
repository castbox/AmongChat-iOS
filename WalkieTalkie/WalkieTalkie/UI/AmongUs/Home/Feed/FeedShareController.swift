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

extension Feed {
    class ShareController: ViewController {
        
        enum Style {
            case `default`
            case showInputBar
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
        
        private lazy var backgroudView: UIView = {
           let v = UIView()
            v.backgroundColor = .clear
            return v
        }()
        
        private lazy var container: UIView = {
           let v = UIView()
            v.backgroundColor = "222222".color()
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
//            v.addCorner(with: 20, corners: [.topLeft, .topRight])
            return v
        }()
                
        private let feed: Entity.Feed
        
        private var isAnonymousUser = Settings.shared.amongChatUserProfile.value?.isAnonymous ?? false
        
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
            return R.string.localizable.amongChatGroupShareContent(Settings.shared.amongChatUserProfile.value?.name ?? "",
                                                                   "groupName",
                                                                   shareUrl)
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

        var dismissHandler: ((_ errorString: String?) -> Void)?
        
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
        Request.feedShareToUser(feed, uids: selectedUsers.map { $0.uid.string }, text: inputBar.inputTextView.text?.trim() ?? "")
            .subscribe(onSuccess: { [weak self] result in
                removeHandler()
                self?.view.endEditing(true)
                let anonymousUsers = result?.uidsAnonymous ?? []
                self?.dismissModal(animated: true, completion: { [weak self] in
                    self?.dismissHandler?(anonymousUsers.isEmpty ? "": R.string.localizable.feedShareToAnonymousUserTips())
                })
            }, onError: { error in
                removeHandler()
            })
            .disposed(by: bag)
    }
    
    func onShareBar(select item: Feed.ShareBar.ShareSource) {
        switch item {
        case .message:
            ()
        case .sms:
//            self.sendSMS(body: self.shareText)
            ()
        case .copyLink:
            ()
            
        case .shareLink:
//            self.shareLink()
        ()
            
        default:
            self.dismissModal()
        }
        self.dismissModal()
    }
    
    func bindSubviewEvent() {
        DMManager.shared.conversations()
            .map { $0.map { $0.fromUid } }
            .flatMap { Request.feedShareUserList($0) }
            .subscribe(onSuccess: { [weak self] result in
                self?.userViews.dataSource = result ?? []
            }, onError: { error in
                
            })
            .disposed(by: bag)
        
        userViews.selectedUsersHandler = { [weak self] users in
            self?.selectedUsers = users
        }
        
        shareBar.selectedSourceObservable
            .subscribe(onNext: { [weak self] source in
                self?.onShareBar(select: source)
            })
            .disposed(by: bag)
        
        backgroudView.rx.tapGesture()
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
        view.addSubviews(views: backgroudView, container)
        inputBar.isHidden = true
        container.addSubviews(views: titleLabel, userViews, shareBar, inputBar)
        
        backgroudView.snp.makeConstraints { maker in
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
            maker.height.equalTo(94)
        }
        
        shareBar.snp.makeConstraints { maker in
            maker.bottom.equalTo(-(Frame.Height.safeAeraBottomHeight + (isAnonymousUser ? 27.5 : 40).cgFloat))
            maker.leading.trailing.equalToSuperview()
            maker.height.equalTo(75)
        }
        
        inputBar.snp.makeConstraints { maker in
            maker.bottom.leading.trailing.equalToSuperview()
            maker.height.equalTo(221 + Frame.Height.safeAeraBottomHeight)
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
