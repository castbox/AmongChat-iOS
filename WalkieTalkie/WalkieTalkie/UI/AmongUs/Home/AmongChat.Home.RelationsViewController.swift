//
//  AmongChat.Home.RelationsViewController.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/12/25.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

extension AmongChat.Home {
    
    class RelationsViewController: WalkieTalkie.ViewController {
        
        private typealias FansGroupBannerCell = AmongChat.Home.FansGroupBannerCell
        private typealias FriendCell = AmongChat.Home.FriendCell
        private typealias SuggestContactCell = AmongChat.Home.SuggestedContactCell
        private typealias SuggestionCell = AmongChat.Home.SuggestionCell
        private typealias SectionHeader = AmongChat.Home.FriendSectionHeader
        private typealias ShareFooter = AmongChat.Home.FriendShareFooter
        private typealias EmptyView = AmongChat.Home.EmptyReusableView
        private typealias ContactViewModel = AmongChat.Home.ContactViewModel
        private lazy var navigationView = NavigationBar()
            
        private lazy var friendsCollectionView: UICollectionView = {
            
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .vertical
            var hInset: CGFloat = 0
            adaptToIPad {
                hInset = 20
            }
            let cellWidth: CGFloat = UIScreen.main.bounds.width - hInset * 2
            let cellHeight: CGFloat = 69
            layout.itemSize = CGSize(width: cellWidth, height: cellHeight)
            layout.minimumLineSpacing = 0
            let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
            v.contentInset = UIEdgeInsets(top: 0, left: hInset, bottom: 0, right: hInset)
            v.register(FansGroupBannerCell.self, forCellWithReuseIdentifier: NSStringFromClass(FansGroupBannerCell.self))
            v.register(FriendCell.self, forCellWithReuseIdentifier: NSStringFromClass(FriendCell.self))
            v.register(SuggestionCell.self, forCellWithReuseIdentifier: NSStringFromClass(SuggestionCell.self))
            v.register(SectionHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: NSStringFromClass(SectionHeader.self))
            v.register(ShareFooter.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: NSStringFromClass(ShareFooter.self))
            v.register(EmptyView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: NSStringFromClass(EmptyView.self))
            v.register(SuggestedContactCell.self, forCellWithReuseIdentifier: NSStringFromClass(SuggestedContactCell.self))
            v.showsVerticalScrollIndicator = false
            v.showsHorizontalScrollIndicator = false
            v.dataSource = self
            v.delegate = self
            v.backgroundColor = .clear
            v.alwaysBounceVertical = true
            return v
        }()
        
        override var screenName: Logger.Screen.Node.Start {
            return .friends
        }
        
        override var isHidesBottomBarWhenPushed: Bool {
            return false
        }
        
        override var contentScrollView: UIScrollView? {
            friendsCollectionView
        }
        
        private var suggestContactCell: SuggestContactCell?
        
        private let viewModel = RelationViewModel()
        
        private var dataSource = [RelationViewModel.Item]() {
            didSet {
                friendsCollectionView.reloadData()
            }
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
            setupEvent()
        }
        
    }
    
}

extension AmongChat.Home.RelationsViewController {
    
    private func setupLayout() {

        view.addSubviews(views: navigationView, friendsCollectionView)
        
        navigationView.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(topLayoutGuide.snp.bottom)
        }
        
        friendsCollectionView.snp.makeConstraints { (maker) in
            maker.top.equalTo(navigationView.snp.bottom)
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalToSuperview()
        }
        
    }
    
    private func setupEvent() {
        
        viewModel.refreshData()
        
        viewModel.dataSource
            .subscribe(onNext: { [weak self] (data) in
                self?.dataSource = data
            })
            .disposed(by: bag)
                
        rx.viewDidAppear
            .subscribe(onNext: { [weak self] (_) in
                self?.viewModel.refreshData()
            })
            .disposed(by: bag)
        
    }
    
    private func followUser(user: AmongChat.Home.PlayingViewModel) {
        
        let hudRemoval = view.raft.show(.loading, userInteractionEnabled: false)
        let completion = { [weak self] in
            self?.friendsCollectionView.isUserInteractionEnabled = true
            hudRemoval()
        }
        friendsCollectionView.isUserInteractionEnabled = false
        
        let _ = Request.follow(uid: user.uid, type: "follow")
            .subscribe(onSuccess: { [weak self] (success) in
                completion()
                guard success else { return }
                self?.viewModel.updateSuggestionUser(user: user)
            }, onError: { [weak self] (error) in
                completion()
                self?.view.raft.autoShow(.text(error.localizedDescription), userInteractionEnabled: false)
            })
        
    }
    
    private func shareApp() {
        let inviteView = Social.InviteFirendsViewController()
        presentPanModal(inviteView)
        inviteView.shareSnapchatHandler = { [weak self] in
            guard let `self` = self else {
                return
            }
            let removeHandler = self.view.raft.show(.loading)
            //get sign
            Request.userShareSign()
                .subscribe { sign in
                    guard let sign = sign else {
                        removeHandler()
                        return
                    }
                    let content = ShareManager.Content(type: .profile, targetType: .snapchat, content: R.string.localizable.shareApp(), url: "https://among.chat/user?uid=\(Settings.loginUserId!)&sign=\(sign)")
                    ShareManager.default.share(with: content, .snapchat, viewController: self) {
                        removeHandler()
                    }
                } onError: { error in
                    removeHandler()
                }
                .disposed(by: self.bag)
        }
    }

}

extension AmongChat.Home.RelationsViewController {

    //MARK: - UI Action
    

}

extension AmongChat.Home.RelationsViewController: UICollectionViewDataSource {

    // MARK: - UICollectionView
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dataSource.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let item = dataSource.safe(section)
        if item?.group == .suggestContacts {
            return item?.userLsit.isEmpty == false ? 1 : 0
        } else if item?.group == .fansGroup {
            return 1
        }
        return item?.userLsit.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let item = dataSource.safe(indexPath.section) else {
            return collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(FriendCell.self), for: indexPath)
        }
        switch item.group {
        case .playing:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(FriendCell.self), for: indexPath)
            if let cell = cell as? FriendCell,
               let playing = dataSource.safe(indexPath.section)?.userLsit.safe(indexPath.item) {
                cell.bind(viewModel: playing, onJoin: { [weak self] in
                    guard let `self` = self else { return }
                    guard let roomState = playing.roomState else {
                        //chat
                        self.startChatAfterLogin(with: playing.playingModel.user)
                        return
                    }
                    
                    guard (roomState == .public || Settings.isSilentUser) else {
                        self.view.raft.autoShow(.text(R.string.localizable.amongChatHomeFirendsPrivateChannelTip()))
                        return
                    }
                    
                    if let gid = playing.groupId {
                        self.enter(group: gid, logSource: .init(.friends))
                    } else if let roomId = playing.roomId,
                              let topicId = playing.roomTopicId {
                        self.enterRoom(roomId: roomId, topicId: topicId, logSource: ParentPageSource(.friends), apiSource: ParentApiSource(.join_friend_room))
                    }
                    
                    Logger.Action.log(.home_friends_following_join, categoryValue: playing.roomTopicId)
                }, onAvatarTap: { [weak self] in
                    let vc = Social.ProfileViewController(with: playing.uid)
                    self?.navigationController?.pushViewController(vc)
                    Logger.Action.log(.home_friends_profile_clk, categoryValue: "following")
                })
            }
            return cell
        case .suggestContacts:
            if suggestContactCell == nil {
                suggestContactCell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(SuggestContactCell.self), for: indexPath) as? SuggestContactCell
                Logger.Action.log(.suggested_contact_imp)
            }
            if let cell = suggestContactCell {
                cell.bind(dataSource: item.userLsit as! [ContactViewModel]) { [weak self] contact in
                    Logger.Action.log(.suggested_contact_clk, category: .skip)
                    self?.viewModel.setReadTags(contact)
                } onInvite: { [weak self] contact in
                    Logger.Action.log(.suggested_contact_clk, category: .invite)

                    self?.viewModel.setReadTags(contact)
                    self?.sendSMS(to: contact.phone, body: R.string.localizable.shareAppContent())
                } onRunOutOfCards: { [weak self] in
                    self?.viewModel.resetSuggestedContacts()
                }
            }
            return suggestContactCell!
        case .suggestStrangers:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(SuggestionCell.self), for: indexPath)
            if let cell = cell as? SuggestionCell,
               let playing = item.userLsit.safe(indexPath.item) {
                cell.bind(viewModel: playing, onFollow: { [weak self] in
                    self?.followUser(user: playing)
                    Logger.Action.log(.home_friends_suggestion_following_clk)
                }, onAvatarTap: { [weak self] in
                    let vc = Social.ProfileViewController(with: playing.uid)
                    self?.navigationController?.pushViewController(vc)
                    Logger.Action.log(.home_friends_profile_clk, categoryValue: "suggestion")
                })
            }
            return cell
            
        case .fansGroup:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(FansGroupBannerCell.self), for: indexPath)
            if let cell = cell as? FansGroupBannerCell {
                cell.tapHandler = { [weak self] in
                    let vc = FansGroup.GroupsViewController()
                    self?.navigationController?.pushViewController(vc)
                }                
            }
            return cell
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let reusableView: UICollectionReusableView
        
        guard let item = dataSource.safe(indexPath.section) else {
            reusableView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: NSStringFromClass(EmptyView.self), for: indexPath)
            reusableView.isHidden = true
            return reusableView
        }
        
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: NSStringFromClass(SectionHeader.self), for: indexPath) as! SectionHeader
            header.seeAllHandler = { [weak self] in
                Logger.Action.log(.suggested_contact_imp, category: .all)
                let controller = Social.ContactListViewController()
                self?.navigationController?.pushViewController(controller)
            }
            header.hideSeeAllButton = item.group != .suggestContacts
            switch item.group {
            case .playing:
                header.configTitle(R.string.localizable.amongChatHomeFriendsOnlineTitle()) { (maker) in
                    maker.leading.trailing.equalToSuperview().inset(20)
                    maker.bottom.equalToSuperview().offset(2)
                }
            case .suggestContacts:
                header.configTitle(R.string.localizable.socialSuggestedContacts()) { (maker) in
                    maker.leading.trailing.equalToSuperview().inset(20)
                    maker.bottom.equalToSuperview().offset(2)
                }
            case .suggestStrangers:
                header.configTitle(R.string.localizable.amongChatHomeFriendsSuggestionTitle()) { (maker) in
                    maker.leading.trailing.equalToSuperview().inset(20)
                    maker.bottom.equalToSuperview().offset(2)
                }
            default:
                ()
            }
            
            header.isHidden = (item.userLsit.count) == 0
            
            reusableView = header
            
        case UICollectionView.elementKindSectionFooter:
            
            switch item.group {
            case .playing:
                let shareFooter = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: NSStringFromClass(ShareFooter.self), for: indexPath) as! ShareFooter
                shareFooter.onSelect = { [weak self] in
                    self?.shareApp()
                    Logger.Action.log(.home_friends_invite_clk)
                }
                
                if dataSource.safe(indexPath.section)?.userLsit.count ?? 0 > 0 {
                    shareFooter.configContent { (maker) in
                        maker.leading.trailing.equalToSuperview().inset(20)
                        maker.top.equalToSuperview().offset(6)
                        maker.height.equalTo(68)
                    }
                } else {
                    shareFooter.configContent { (maker) in
                        maker.leading.trailing.equalToSuperview().inset(20)
                        maker.top.equalToSuperview().offset(24)
                        maker.height.equalTo(68)
                    }
                }
                
                reusableView = shareFooter
                
            default:
                reusableView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: NSStringFromClass(EmptyView.self), for: indexPath)
                reusableView.isHidden = true
            }
            
        default:
            reusableView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: NSStringFromClass(EmptyView.self), for: indexPath)
            reusableView.isHidden = true
        }
        
        return reusableView
    }
    
}

extension AmongChat.Home.RelationsViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding = collectionView.contentInset.left + collectionView.contentInset.right
        if dataSource.safe(indexPath.section)?.group == .suggestContacts {
            return CGSize(width: Frame.Screen.width - padding, height: 104)
        } else if dataSource.safe(indexPath.section)?.group == .fansGroup {
            return FansGroupBannerCell.size(width: Frame.Screen.width - padding)
        }
        return CGSize(width: Frame.Screen.width - padding, height: 69)

    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        guard let item = dataSource.safe(section) else {
            return CGSize(width: CGFloat.leastNormalMagnitude, height: CGFloat.leastNormalMagnitude)
        }
        
        if item.userLsit.count > 0 {
            if item.group == .playing {
                return CGSize(width: Frame.Screen.width, height: 53.5)
            } else {
                return CGSize(width: Frame.Screen.width, height: 85.5)
            }
        } else {
            return CGSize(width: CGFloat.leastNormalMagnitude, height: CGFloat.leastNormalMagnitude)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        
        guard let item = dataSource.safe(section) else {
            return CGSize(width: CGFloat.leastNormalMagnitude, height: CGFloat.leastNormalMagnitude)
        }
        
        switch item.group {
        case .fansGroup:
            return CGSize(width: Frame.Screen.width, height: 0)
        case .playing:
            if item.userLsit.count > 0 {
                return CGSize(width: Frame.Screen.width, height: 74)
            } else {
                return CGSize(width: Frame.Screen.width, height: 94)
            }

        default:
            return CGSize(width: CGFloat.leastNormalMagnitude, height: CGFloat.leastNormalMagnitude)
        }
    }
    
}
