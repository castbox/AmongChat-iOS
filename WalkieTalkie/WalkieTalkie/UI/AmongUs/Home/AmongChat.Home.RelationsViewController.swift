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
        
        private typealias FriendCell = AmongChat.Home.FriendCell
        private typealias SuggestionCell = AmongChat.Home.SuggestionCell
        private typealias SectionHeader = AmongChat.Home.FriendSectionHeader
        private typealias ShareFooter = AmongChat.Home.FriendShareFooter
        private typealias EmptyView = AmongChat.Home.EmptyReusableView
        
        private lazy var navigationView = NavigationBar()
            
        private lazy var friendsCollectionView: UICollectionView = {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .vertical
            let hInset: CGFloat = 0
            let cellWidth: CGFloat = UIScreen.main.bounds.width - hInset * 2
            let cellHeight: CGFloat = 69
            layout.itemSize = CGSize(width: cellWidth, height: cellHeight)
            layout.minimumLineSpacing = 0
            layout.sectionInset = UIEdgeInsets(top: 0, left: hInset, bottom: 0, right: hInset)
            let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
            v.register(FriendCell.self, forCellWithReuseIdentifier: NSStringFromClass(FriendCell.self))
            v.register(SuggestionCell.self, forCellWithReuseIdentifier: NSStringFromClass(SuggestionCell.self))
            v.register(SectionHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: NSStringFromClass(SectionHeader.self))
            v.register(ShareFooter.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: NSStringFromClass(ShareFooter.self))
            v.register(EmptyView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: NSStringFromClass(EmptyView.self))
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
        
        private let viewModel = RelationViewModel()
        
        private var dataSource = [[PlayingViewModel]]() {
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
            maker.top.left.right.equalToSuperview()
            maker.height.equalTo(49 + Frame.Height.safeAeraTopHeight)
        }
        
        friendsCollectionView.snp.makeConstraints { (maker) in
            maker.top.equalTo(navigationView.snp.bottom)
            maker.left.right.equalToSuperview()
            maker.bottom.equalToSuperview()
        }
        
                
        friendsCollectionView.snp.makeConstraints { (maker) in
            maker.left.right.bottom.equalToSuperview()
            maker.top.equalTo(navigationView.snp.bottom)
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

        rx.viewWillAppear
            .subscribe(onNext: { [weak self] (_) in
                self?.friendsCollectionView.setContentOffset(.zero, animated: false)
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
        let removeHUDBlock = view.raft.show(.loading, userInteractionEnabled: false)
        let removeBlock = { [weak self] in
            self?.view.isUserInteractionEnabled = true
            removeHUDBlock()
        }
        
        self.view.isUserInteractionEnabled = false
        ShareManager.default.showActivity(viewController: self) { () in
            removeBlock()
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
        return dataSource.safe(section)?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        switch indexPath.section {
        case 0:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(FriendCell.self), for: indexPath)
            if let cell = cell as? FriendCell,
               let playing = dataSource.safe(indexPath.section)?.safe(indexPath.item) {
                cell.bind(viewModel: playing, onJoin: { [weak self] (roomId, topicId) in
                    
                    guard let roomState = playing.roomState,
                          roomState == .public else {
                        self?.view.raft.autoShow(.text(R.string.localizable.amongChatHomeFirendsPrivateChannelTip()))
                        return
                    }
                    
                    self?.enterRoom(roomId: roomId, topicId: topicId, logSource: ParentPageSource(.friends), apiSource: ParentApiSource(.join_friend_room))
                    Logger.Action.log(.home_friends_following_join, categoryValue: playing.roomTopicId)
                }, onAvatarTap: { [weak self] in
                    let vc = Social.ProfileViewController(with: playing.uid)
                    self?.navigationController?.pushViewController(vc)
                    Logger.Action.log(.home_friends_profile_clk, categoryValue: "following")
                })
            }
            return cell

        case 1:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(SuggestionCell.self), for: indexPath)
            if let cell = cell as? SuggestionCell,
               let playing = dataSource.safe(indexPath.section)?.safe(indexPath.item) {
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
        default:
            return collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(FriendCell.self), for: indexPath)
        }

    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let reusableView: UICollectionReusableView
        
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: NSStringFromClass(SectionHeader.self), for: indexPath) as! SectionHeader
            
            if indexPath.section == 0 {
                header.configTitle(R.string.localizable.amongChatHomeFriendsOnlineTitle())
            } else {
                header.configTitle(R.string.localizable.amongChatHomeFriendsSuggestionTitle())
            }
            
            header.isHidden = (dataSource.safe(indexPath.section)?.count ?? 0) == 0
            
            reusableView = header
            
        case UICollectionView.elementKindSectionFooter:
            
            if indexPath.section == 0 {
                let shareFooter = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: NSStringFromClass(ShareFooter.self), for: indexPath) as! ShareFooter
                shareFooter.onSelect = { [weak self] in
                    self?.shareApp()
                    Logger.Action.log(.home_friends_invite_clk)
                }
                reusableView = shareFooter
            } else {
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
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if dataSource.safe(section)?.count ?? 0 > 0 {
            return CGSize(width: Frame.Screen.width, height: 31)
        } else {
            return CGSize(width: CGFloat.leastNormalMagnitude, height: CGFloat.leastNormalMagnitude)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if section == 0 {
            return CGSize(width: Frame.Screen.width, height: 113)
        } else {
            return CGSize(width: CGFloat.leastNormalMagnitude, height: CGFloat.leastNormalMagnitude)
        }
    }
    
}
