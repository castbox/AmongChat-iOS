//
//  ChannelUserListController.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/8/3.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class ChannelUserListController: ViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var navHeightConstraint: NSLayoutConstraint!
    
    private lazy var footerView: UIView = {
        
        let view = UIView()
        view.backgroundColor = UIColor(hex6: 0xFFFFFF, alpha: 0.5)
        
        let iconiV = UIImageView(image: R.image.channel_user_list_social())
        view.addSubview(iconiV)
        iconiV.snp.makeConstraints { (maker) in
            maker.width.height.equalTo(15)
            maker.left.equalToSuperview().offset(15)
            maker.top.equalToSuperview().offset(5)
        }
        
        let lb = WalkieLabel()
        lb.font = R.font.nunitoSemiBold(size: 12)
        lb.textColor = .black
        lb.text = R.string.localizable.channelUserListSocialTitle()
        lb.appendKern()
        view.addSubview(lb)
        lb.snp.makeConstraints { (maker) in
            maker.centerY.equalTo(iconiV)
            maker.left.equalTo(45)
        }
        
        let shareContainer = SocialContainerView(with: self.channel)

        view.addSubview(shareContainer)
        shareContainer.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview().inset(15)
            maker.bottom.equalToSuperview().offset(-40)
        }
        view.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 145)
        return view
    }()

    private var dataSource: [[ChannelUserViewModel]] = [[], [], []] {
        didSet {
            tableView.reloadData()
        }
    }
    
    private var hasBeenInvited: [String] = []
    
    private let channel: Room
    private let viewModel = ChannelUserListViewModel.shared
    
    init(channel: Room) {
        self.channel = channel
        super.init(nibName: "ChannelUserListController", bundle: nil)
        self.isNavigationBarHiddenWhenAppear = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureSubview()
        bindSubviewEvent()
    }
    
    @IBAction func backButtonAction(_ sender: Any) {
        navigationController?.popViewController()
    }
}

extension ChannelUserListController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        if dataSource.safe(2)?.count ?? 0 > 0 {
            return dataSource.count
        } else {
            return 2
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.safe(section)?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(ChannelFriendUserCell.self), for: indexPath)
            if let user = dataSource.safe(indexPath.section)?.safe(indexPath.row),
                let friendCell = cell as? ChannelFriendUserCell,
                let firestoreUser = user.firestoreUser {
                
                friendCell.inviteHandler = { [weak self] (uid) in
                    self?.hasBeenInvited.append(uid)
                }
                
                friendCell.configView(with: Social.UserList.UserViewModel(with: firestoreUser), hasInvited: hasBeenInvited.contains(firestoreUser.uid))
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withClass: ChannelUserCell.self, for: indexPath)
            if let user = dataSource.safe(indexPath.section)?.safe(indexPath.row) {
                cell.bind(user)
                if user.isSelf {
                    cell.tapBlockHandler = nil
                } else {
                    cell.tapBlockHandler = { [weak self] in
                        self?.showMoreSheet(for: user)
                    }
                }
            }
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
//        let room = dataSource[indexPath.row]
//        selectRoomHandler(room)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 15
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let titleView: UIView = {
            let view = UIView()
            view.backgroundColor = UIColor(hex6: 0xFFFFFF, alpha: 0.5)
            let lb = WalkieLabel()
            lb.font = R.font.nunitoSemiBold(size: 12)
            lb.textColor = .black
            if section == 0 {
                lb.text = R.string.localizable.channelUserListSpeakingTitle()
            } else if section == 1 {
                lb.text = R.string.localizable.channelUserListListenTitle()
            } else {
                lb.text = R.string.localizable.channelUserListFollowedTitle()
            }
            lb.appendKern()
            view.addSubview(lb)
            lb.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.left.equalTo(45)
            }
            let icon: UIImage?
            if section == 0 {
                icon = R.image.channel_user_list_mic()
            } else if section == 1 {
                icon = R.image.channel_user_list_ear()
            } else {
                icon = R.image.channel_user_list_followed()
            }
            let iconiV = UIImageView(image: icon)
            view.addSubview(iconiV)
            iconiV.snp.makeConstraints { (maker) in
                maker.width.height.equalTo(20)
                maker.centerY.equalToSuperview()
                maker.left.equalToSuperview().offset(15)
            }
            return view
        }()
        
        let emptyTextView: UIView = {
            let v = UIView()
            
            let lb = WalkieLabel()
            lb.font = R.font.nunitoSemiBold(size: 16)
            lb.textColor = .black
            
            if section == 0 {
                lb.text = R.string.localizable.channelUserListSpeakEmptyText()
            } else if section == 1 {
                lb.text = R.string.localizable.channelUserListListenEmptyText()
            }
            
            v.addSubview(lb)
            lb.snp.makeConstraints { (maker) in
                maker.center.equalToSuperview()
                maker.top.bottom.equalToSuperview().inset(30)
            }
            return v
        }()
        
        let header: UIView = {
            let v = UIView()
            
            v.addSubview(titleView)
            
            titleView.snp.makeConstraints { (maker) in
                maker.left.right.top.equalToSuperview()
                maker.height.equalTo(30)
            }
            
            if dataSource.safe(section)?.count == 0 {
                v.addSubview(emptyTextView)
                emptyTextView.snp.makeConstraints { (maker) in
                    maker.left.right.bottom.equalToSuperview()
                    maker.top.equalTo(titleView.snp.bottom)
                }
            } else {
                titleView.snp.makeConstraints { (maker) in
                    maker.bottom.equalToSuperview()
                }
            }
            
            return v
        }()
        
        return header
        
    }

}

extension ChannelUserListController: UITableViewDelegate {
    
}

extension ChannelUserListController {
    func showMoreSheet(for userViewModel: ChannelUserViewModel) {
        let alertVC = UIAlertController(
            title: nil,
            message: R.string.localizable.userListMoreSheet(),
            preferredStyle: .actionSheet
        )
        
        if let firestoreUser = userViewModel.firestoreUser {
            let followingUids = Social.Module.shared.followingValue.map { $0.uid }
            if !followingUids.contains(firestoreUser.uid) {
                //未添加到following
                let followAction = UIAlertAction(title: R.string.localizable.channelUserListFollow(), style: .default) { [weak self] (_) in
                    // follow_clk log
                    GuruAnalytics.log(event: "follow_clk", category: nil, name: nil, value: nil, content: nil)
                    //
                    self?.viewModel.followUser(firestoreUser)
                }
                alertVC.addAction(followAction)
            } else {
                let unfollowAction = UIAlertAction(title: R.string.localizable.socialUnfollow(), style: .destructive) { [weak self] (_) in
                    // unfollow_clk log
                    GuruAnalytics.log(event: "unfollow_clk", category: nil, name: nil, value: nil, content: nil)
                    //
                    self?.viewModel.unfollowUser(firestoreUser)
                }
                alertVC.addAction(unfollowAction)
            }
        }
        
        let isMuted = Social.Module.shared.mutedValue.contains(userViewModel.channelUser.uid)
        if isMuted {
            let unmuteAction = UIAlertAction(title: R.string.localizable.channelUserListUnmute(), style: .default) { [weak self] (_) in
                // unmute_clk log
                GuruAnalytics.log(event: "unmute_clk", category: nil, name: nil, value: nil, content: nil)
                //
                self?.viewModel.unmuteUser(userViewModel)
                ChatRoomManager.shared.adjustUserPlaybackSignalVolume(userViewModel.channelUser, volume: 100)
            }
            alertVC.addAction(unmuteAction)
            
        } else {
            let muteAction = UIAlertAction(title: R.string.localizable.channelUserListMute(), style: .default) { [weak self] (_) in
                
//                self?.viewModel.muteUser(userViewModel)
//                ChatRoomManager.shared.adjustUserPlaybackSignalVolume(userViewModel.channelUser, volume: 0)

                // mute_clk log
                GuruAnalytics.log(event: "mute_clk", category: nil, name: nil, value: nil, content: nil)
                //
                
                let modal = ActionModal(with: userViewModel, actionType: .mute)
                modal.actionHandler = { () in
                    self?.viewModel.muteUser(userViewModel)
                    ChatRoomManager.shared.adjustUserPlaybackSignalVolume(userViewModel.channelUser, volume: 0)
                }
                modal.showModal(in: self)
            }
            alertVC.addAction(muteAction)
        }
        
        let reportAction = UIAlertAction(title: R.string.localizable.reportTitle(), style: .default, handler: { [weak self] _ in
            self?.showReportSheet(for: userViewModel)
        })
        let blockAction = UIAlertAction(title:userViewModel.channelUser.status == .blocked ? R.string.localizable.alertUnblock() : R.string.localizable.alertBlock(), style: .default, handler: { [weak self] _ in
            // block_clk log
            GuruAnalytics.log(event: "block_clk", category: "user_list", name: nil, value: nil, content: nil)
            //
            self?.showBlockAlert(with: userViewModel)
        })
        alertVC.addAction(reportAction)
        alertVC.addAction(blockAction)
        
        alertVC.addAction(UIAlertAction(title: R.string.localizable.toastCancel(), style: .cancel))
        present(alertVC, animated: true, completion: nil)
    }
    
    func showReportSheet(for userViewModel: ChannelUserViewModel) {
        let user = userViewModel.channelUser
        let alertVC = UIAlertController(
            title: R.string.localizable.reportTitle(),
            message: "\(R.string.localizable.reportUserId()): \(user.uid)",
            preferredStyle: .actionSheet)

        let items = [
            R.string.localizable.reportIncorrectInformation(),
            R.string.localizable.reportIncorrectSexual(),
            R.string.localizable.reportIncorrectHarassment(),
            R.string.localizable.reportIncorrectUnreasonable(),
            ].enumerated()

        for (index, item) in items {
            let action = UIAlertAction(title: item, style: .default, handler: { [weak self] _ in
                self?.view.raft.autoShow(.text(R.string.localizable.reportSuccess()))
                Logger.Report.logImp(itemIndex: index, channelName: String(user.uid))
            })
            alertVC.addAction(action)
        }

        alertVC.addAction(UIAlertAction(title: R.string.localizable.toastCancel(), style: .cancel))
        present(alertVC, animated: true, completion: nil)
    }
    
    func showBlockAlert(with userViewModel: ChannelUserViewModel) {
        guard userViewModel.channelUser.status != .blocked else {
            viewModel.unblockedUser(userViewModel)
            ChatRoomManager.shared.adjustUserPlaybackSignalVolume(userViewModel.channelUser, volume: 100)
            return
        }
        let modal = ActionModal(with: userViewModel, actionType: .block)
        modal.actionHandler = { [weak self] in
            self?.viewModel.blockedUser(userViewModel)
            ChatRoomManager.shared.adjustUserPlaybackSignalVolume(userViewModel.channelUser, volume: 0)
        }
        modal.showModal(in: self)
    }
    
    func bindSubviewEvent() {

        let friendsOb = Observable.combineLatest(Social.Module.shared.followerObservable, Social.Module.shared.followingObservable)
            .map { (t) -> [FireStore.Entity.User.FriendMeta] in
                let (followers, followings) = t
                return followers.filter { (follower) -> Bool in
                    followings.contains { (following) -> Bool in
                        following.uid == follower.uid
                    }
                }
        }
        .map({ $0.map { $0.uid } })
        .map({ Set($0) })
        .distinctUntilChanged()
        .flatMap({ FireStore.shared.fetchUsers(Array($0)) })
        .map({
            $0.map { ChannelUserViewModel(with: ChannelUser.randomUser(uid: $0.profile.uidInt), firestoreUser: $0) }
        })
        
        let channelUserOb = viewModel.userObservable
        
        Observable.combineLatest(channelUserOb, friendsOb)
        .subscribe(onNext: { [weak self] (t) in
            
            let (channelUsers, friends) = t
            
            let speaking = channelUsers.filter { (user) -> Bool in
                user.channelUser.status == .talking
            }
            
            let listen = channelUsers.filter { (user) -> Bool in
                user.channelUser.status != .talking
            }
            
            self?.dataSource[0] = speaking
            self?.dataSource[1] = listen
            self?.dataSource[2] = friends
            /* 暂时不用筛除已在房间的好友
             .filter({ (friend) -> Bool in
             !channelUsers.contains { $0.channelUser.uid == friend.channelUser.uid }
             })
             */
        })
            .disposed(by: bag)
        
    }
    
    func configureSubview() {
        tableView.register(nibWithCellClass: ChannelUserCell.self)
        tableView.register(ChannelFriendUserCell.self, forCellReuseIdentifier: NSStringFromClass(ChannelFriendUserCell.self))
        tableView.backgroundColor = .clear
        navHeightConstraint.constant = Frame.Height.navigation
        tableView.tableFooterView = footerView
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 73
    }
}

extension ChannelUserListController: Modalable {
    
    func style() -> Modal.Style {
        return .customHeight
    }
    
    func height() -> CGFloat {
        return 438 + Frame.Height.safeAeraBottomHeight
    }
    
    func modalPresentationStyle() -> UIModalPresentationStyle {
        return .overCurrentContext
    }
    
    func cornerRadius() -> CGFloat {
        return 10
    }
    
    func coverAlpha() -> CGFloat {
        return 0.5
    }
}

extension ChannelUserListController {
    
    class SocialContainerView: UIView, UICollectionViewDataSource, UICollectionViewDelegate {
                
        private lazy var collectionView: UICollectionView = {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .horizontal
            layout.itemSize = CGSize(width: 50, height: 50)
            layout.minimumLineSpacing = 24
            layout.sectionInset = .zero
            let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
            v.register(ShareContainerView.Cell.self, forCellWithReuseIdentifier: NSStringFromClass(ShareContainerView.Cell.self))
            v.showsVerticalScrollIndicator = false
            v.showsHorizontalScrollIndicator = false
            v.dataSource = self
            v.delegate = self
            v.backgroundColor = nil
            return v
        }()
        
        private typealias Item = ShareContainerView.Item
        
        private var source: [Item] = []
        private let channel: Room
        
        override var intrinsicContentSize: CGSize {
            return CGSize(width: 0, height: 50)
        }
        
        init(with channel: Room) {
            self.channel = channel
            super.init(frame: .zero)
            setupLayout()
            updateSource()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupLayout() {
            addSubview(collectionView)
            collectionView.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
        }
        
        private func updateSource() {
            ShareManager.ShareType.allCases
                .filter { $0.isAppInstalled }
                .forEach { type in
                    switch type {
                    case .message:
                        source.append(Item(icon: R.image.icon_share_message(), type: .message))
                    case .whatsapp:
                        source.append(Item(icon: R.image.icon_share_whatsapp(), type: .whatsapp))
                    case .snapchat:
                        let isInreview = FireStore.shared.appConfigSubject.value?.isSnapchatInreview ?? false
                        if !isInreview {
                            source.append(Item(icon: R.image.icon_share_snapchat(), type: .snapchat))
                        }
                    case .ticktock:
                        ()
    //                    source.append(Item(icon: R.image.icon_share_ticktock(), type: .ticktock))
                    case .more:
                        source.append(Item(icon: R.image.icon_share_more(), type: .more))
                    }
            }
        }
        
        
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return source.count
        }
        
        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(ShareContainerView.Cell.self), for: indexPath)
            if let cell = cell as? ShareContainerView.Cell,
                let item = source.safe(indexPath.item) {
                cell.imageView.image = item.icon
            }
            return cell
        }
        
        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            //select
            guard let cell = collectionView.cellForItem(at: indexPath) as? ShareContainerView.Cell,
                let item = source.safe(indexPath.item) else {
                    return
            }
            self.isUserInteractionEnabled = false
            cell.isAnimate = true
            ShareManager.default.share(with: channel.name, type: item.type, viewController: self.parentViewController!) { [weak self] in
                self?.isUserInteractionEnabled = true
                cell.isAnimate = false
            }
        }
    }
    
}
