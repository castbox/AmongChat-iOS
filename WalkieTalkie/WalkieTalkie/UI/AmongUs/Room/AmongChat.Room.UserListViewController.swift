//
//  AmongChat.Room.UserListViewController.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/11/25.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import MoPub

extension AmongChat.Room {
    
    class UserListViewController: WalkieTalkie.ViewController {
        
        private typealias UserCell = AmongChat.Room.UserCell
        private typealias ActionModal = ChannelUserListController.ActionModal
        
        private lazy var bgView: UIView = {
            let v = UIView()
            let ship = UIImageView(image: R.image.space_ship_bg())
            ship.contentMode = .scaleAspectFit
            let star = UIImageView(image: R.image.star_bg())
            let mask = UIView()
            mask.backgroundColor = UIColor.black.alpha(0.5)
            v.addSubviews(views: star, ship, mask)
            star.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
            ship.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
            mask.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
            return v
        }()
        
        private lazy var closeBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.setImage(R.image.icon_close(), for: .normal)
            btn.addTarget(self, action: #selector(onCloseBtn), for: .primaryActionTriggered)
            return btn
        }()
        
        private lazy var userCollectionView: UICollectionView = {
            let layout = UICollectionViewFlowLayout()
            let hInset: CGFloat = 24
            let itemSpacing: CGFloat = 17
            let cellWidth = (UIScreen.main.bounds.width - hInset * 2 - itemSpacing * 4) / 5
            layout.itemSize = CGSize(width: cellWidth, height: 71)
            layout.minimumInteritemSpacing = itemSpacing
            layout.minimumLineSpacing = 8
            layout.sectionInset = UIEdgeInsets(top: 12, left: hInset, bottom: 12, right: hInset)
            let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
            v.register(UserCell.self, forCellWithReuseIdentifier: NSStringFromClass(UserCell.self))
            v.showsVerticalScrollIndicator = false
            v.showsHorizontalScrollIndicator = false
            v.dataSource = self
            v.delegate = self
            v.backgroundColor = nil
            return v
        }()
        
        private lazy var gameTipView: UIView = {
            let view = UIView()
            view.backgroundColor = UIColor.white.alpha(0.5)
            let lb = UILabel()
            lb.numberOfLines = 0
            lb.lineBreakMode = .byWordWrapping
            lb.font = R.font.nunitoRegular(size: 12)
            lb.textColor = UIColor(red: 254, green: 254, blue: 104)
            
            var txt = R.string.localizable.amongChatRoomStartGameTip1()
            
            if let p = Settings.shared.firestoreUserProfile.value {
                txt = txt + " " + R.string.localizable.amongChatRoomStartGameTip2(p.name)
            }
            
            lb.text = txt
            view.addSubview(lb)
            lb.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview().inset(12)
            }
            view.layer.cornerRadius = 10
            view.isHidden = (roomType == .global)
            return view
        }()
        
        private lazy var micSwitchBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.addTarget(self, action: #selector(onMicSwitchBtn(_:)), for: .primaryActionTriggered)
            btn.backgroundColor = UIColor.white.alpha(0.8)
            btn.layer.cornerRadius = 25
            btn.setImage(R.image.icon_mic(), for: .normal)
            btn.setImage(R.image.icon_mic_disable(), for: .selected)
            return btn
        }()
        
        private lazy var shareBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.addTarget(self, action: #selector(onShareBtn), for: .primaryActionTriggered)
            btn.backgroundColor = UIColor.white.alpha(0.8)
            btn.layer.cornerRadius = 25
            let image = R.image.btn_share()?.withRenderingMode(.alwaysTemplate)
            btn.setImage(image, for: .normal)
            btn.tintColor = UIColor(red: 38, green: 38, blue: 38)
            btn.imageEdgeInsets = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
            btn.imageView?.contentMode = .scaleAspectFit
            return btn
        }()
        
        private lazy var moreBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.addTarget(self, action: #selector(onMoreBtn), for: .primaryActionTriggered)
            btn.backgroundColor = UIColor.white.alpha(0.8)
            btn.layer.cornerRadius = 25
            btn.setImage(R.image.btn_more_action(), for: .normal)
            return btn
        }()
        
        private lazy var bottomBtnStack: UIStackView = {
            let s = UIStackView(arrangedSubviews: [micSwitchBtn, shareBtn, moreBtn],
                                axis: .horizontal,
                                spacing: 12,
                                alignment: .fill,
                                distribution: .fillEqually)
            
            micSwitchBtn.snp.makeConstraints { (maker) in
                maker.height.width.equalTo(50)
            }
            
            shareBtn.snp.makeConstraints { (maker) in
                maker.height.width.equalTo(50)
            }
            
            moreBtn.snp.makeConstraints { (maker) in
                maker.height.width.equalTo(50)
            }
            
            return s
        }()
        
        private lazy var adContainer: UIView = {
            let v = UIView()
            v.backgroundColor = .clear
            return v
        }()
        
        private lazy var adView: MPAdView? = {
            let adView = MPAdView(adUnitId: "2d4ccd8d270a4f8aa9afda3713ccdc8a")
            adView?.delegate = self
            adView?.frame = CGRect(origin: .zero, size: kMPPresetMaxAdSizeMatchFrame)
            return adView
        }()
        
        private var dataSource: [ChannelUserViewModel] = [] {
            didSet {
                userCollectionView.reloadData()
            }
        }
        
        private let minimumListLength = Int(10)
        
        private let channel: Room
        private let viewModel = ChannelUserListViewModel.shared
        
        init(channel: Room) {
            self.channel = channel
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
            bindSubviewEvent()
        }
        
    }
    
}

extension AmongChat.Room.UserListViewController {
    
    //MARK: - UI Action
    
    @objc
    private func onCloseBtn() {
        
        let alertVC = UIAlertController(
            title: R.string.localizable.amongChatLeaveRoomTipTitle(),
            message: nil,
            preferredStyle: .alert
        )
        
        let confirm = UIAlertAction(title: R.string.localizable.toastConfirm(), style: .destructive, handler: { [weak self] _ in
            guard let `self` = self else { return }
            
            ChatRoomManager.shared.leaveChannel { (_) in
                let transition = CATransition()
                transition.duration = 0.5
                transition.type = CATransitionType.push
                transition.subtype = CATransitionSubtype.fromLeft
                transition.timingFunction = CAMediaTimingFunction(name:CAMediaTimingFunctionName.easeInEaseOut)
                self.view.window?.layer.add(transition, forKey: kCATransition)
                self.dismiss(animated: true) {
                    guard let vc = UIApplication.navigationController?.viewControllers.first as? AmongChat.Home.ViewController else { return }
                    Ad.InterstitialManager.shared.showAdIfReady(from: vc)
                }
            }
        })
        
        alertVC.addAction(UIAlertAction(title: R.string.localizable.toastCancel(), style: .cancel))
        alertVC.addAction(confirm)
        present(alertVC, animated: true, completion: nil)
    }
    
    @objc
    private func onMicSwitchBtn(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        
        let mute = sender.isSelected
        ChatRoomManager.shared.muteMyMic(muted: mute)
    }
    
    @objc
    private func onShareBtn() {
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

    @objc
    private func onMoreBtn() {
        showMoreSheet(for: channel)
    }
}

extension AmongChat.Room.UserListViewController: UICollectionViewDataSource {
    
    // MARK: - UICollectionView
        
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return max(dataSource.count, minimumListLength)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(UserCell.self), for: indexPath)
        if let cell = cell as? UserCell {
            cell.bind(dataSource.safe(indexPath.item))
        }
        return cell
    }
    
}

extension AmongChat.Room.UserListViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let user = dataSource.safe(indexPath.item),
              !user.isSelf else {
            return
        }
        
        showMoreSheet(for: user)
    }
    
}

extension AmongChat.Room.UserListViewController: MPAdViewDelegate {
    
    //MARK: - MPAdViewDelegate
    
    func viewControllerForPresentingModalView() -> UIViewController! {
        if let naviVC = self.navigationController {
            return naviVC
        } else {
            return self
        }
    }

    func adViewDidLoadAd(_ view: MPAdView!, adSize: CGSize) {
        Logger.Ads.logEvent(.ads_loaded, .channel)
    }

    func adView(_ view: MPAdView!, didFailToLoadAdWithError error: Error!) {
        Logger.Ads.logEvent(.ads_failed, .channel)
    }

    func willPresentModalView(forAd view: MPAdView!) {
        Logger.Ads.logEvent(.ads_imp, .channel)
    }
    
    func willLeaveApplication(fromAd view: MPAdView!) {
        Logger.Ads.logEvent(.ads_clk, .channel)
    }
    
    func didDismissModalView(forAd view: MPAdView!) {
    }
    
}


extension AmongChat.Room.UserListViewController {
    
    // MARK: -
    
    private func setupLayout() {
        isNavigationBarHiddenWhenAppear = true
        statusBarStyle = .lightContent
        view.backgroundColor = UIColor(hex6: 0x00011B)
                
        view.addSubviews(views: bgView, userCollectionView, gameTipView, closeBtn, bottomBtnStack, adContainer)
        
        bgView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        
        userCollectionView.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview()
            maker.top.equalTo(topLayoutGuide.snp.bottom).offset(140)
            maker.height.equalTo(180)
        }
        
        gameTipView.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview().inset(12)
            maker.top.equalTo(userCollectionView.snp.bottom)
        }
        
        closeBtn.snp.makeConstraints { (maker) in
            maker.height.width.equalTo(44)
            maker.top.equalTo(topLayoutGuide.snp.bottom).offset(2)
            maker.right.equalTo(-6)
        }
        
        bottomBtnStack.snp.makeConstraints { (maker) in
            maker.trailing.equalTo(-16)
            maker.bottom.equalTo(adContainer.snp.top).offset(-12)
            maker.height.equalTo(50)
        }
        
        adContainer.snp.makeConstraints { (maker) in
            maker.bottom.equalTo(bottomLayoutGuide.snp.top)
            maker.centerX.equalToSuperview()
            maker.height.equalTo(50)
        }
        
        if channel.name.isPrivate {
            var name = channel.name
            name.removeAll(where: { (c) -> Bool in
                c == "_" || c == "@"
            })
            showShareController(channelName: name)
        }
        
        if let adView = self.adView {
            adContainer.addSubview(adView)
            adView.snp.makeConstraints { (maker) in
                maker.size.equalTo(CGSize(width: 320, height: 50))
                maker.edges.equalToSuperview()
            }
        }

    }
    
    private func showShareController(channelName: String) {
        let controller = R.storyboard.main.privateShareController()
        controller?.channelName = channelName
        controller?.showModal(in: self)
    }
    
    private func showMoreSheet(for userViewModel: ChannelUserViewModel) {
        let alertVC = UIAlertController(
            title: nil,
            message: R.string.localizable.userListMoreSheet(),
            preferredStyle: .actionSheet
        )
        
//        if let firestoreUser = userViewModel.firestoreUser {
//            let followingUids = Social.Module.shared.followingValue.map { $0.uid }
//            if !followingUids.contains(firestoreUser.uid) {
//                //未添加到following
//                let followAction = UIAlertAction(title: R.string.localizable.channelUserListFollow(), style: .default) { [weak self] (_) in
//                    // follow_clk log
//                    GuruAnalytics.log(event: "follow_clk", category: nil, name: nil, value: nil, content: nil)
//                    //
//                    self?.viewModel.followUser(firestoreUser)
//                }
//                alertVC.addAction(followAction)
//            } else {
//                let unfollowAction = UIAlertAction(title: R.string.localizable.socialUnfollow(), style: .destructive) { [weak self] (_) in
//                    // unfollow_clk log
//                    GuruAnalytics.log(event: "unfollow_clk", category: nil, name: nil, value: nil, content: nil)
//                    //
//                    self?.viewModel.unfollowUser(firestoreUser)
//                }
//                alertVC.addAction(unfollowAction)
//            }
//        }
        
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
    
    private func showReportSheet(for userViewModel: ChannelUserViewModel) {
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
    
    private func showBlockAlert(with userViewModel: ChannelUserViewModel) {
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
    
    private func bindSubviewEvent() {
        
        AdsManager.shared.mopubInitializeSuccessSubject
            .filter { _ -> Bool in
                return !Settings.shared.isProValue.value
            }
            .filter { $0 }
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] _ in
                self?.loadAdView()
            })
            .disposed(by: bag)
        
        Settings.shared.isProValue.replay()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] (isPro) in
                guard let `self` = self else { return }
                
                if isPro {
                    //remove ad
                    self.adView?.stopAutomaticallyRefreshingContents()
                } else {
                    self.adView?.loadAd()
                }
                
                self.adContainer.snp.updateConstraints { (maker) in
                    maker.height.equalTo(isPro ? 0 : 50)
                }
                self.adView?.isHidden = isPro
            })
            .disposed(by: bag)
        
        viewModel.userObservable
        .subscribe(onNext: { [weak self] (channelUsers) in
            self?.dataSource = channelUsers
        })
            .disposed(by: bag)
    }
    
    private func loadAdView() {
        adView?.loadAd(withMaxAdSize: kMPPresetMaxAdSizeMatchFrame)
        Logger.Ads.logEvent(.ads_load, .channel)
        adView?.startAutomaticallyRefreshingContents()
    }
    
}

extension AmongChat.Room.UserListViewController {
    
    private func showMoreSheet(for channel: Room) {
        let alertVC = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet
        )
        
        let reportAction = UIAlertAction(title: R.string.localizable.reportTitle(), style: .default, handler: { [weak self] _ in
            guard let `self` = self else { return }
            self.showReportSheet(for: self.channel)
        })
        alertVC.addAction(reportAction)
        
        alertVC.addAction(UIAlertAction(title: R.string.localizable.toastCancel(), style: .cancel))
        present(alertVC, animated: true, completion: nil)
    }
    
    private func showReportSheet(for channel: Room) {
        let alertVC = UIAlertController(
            title: R.string.localizable.reportTitle(),
            message: "\(R.string.localizable.reportRoomId()): \(channel.showName)",
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
                Logger.Report.logImp(itemIndex: index, channelName: String(channel.showName))
            })
            alertVC.addAction(action)
        }

        alertVC.addAction(UIAlertAction(title: R.string.localizable.toastCancel(), style: .cancel))
        present(alertVC, animated: true, completion: nil)
    }
}


fileprivate extension AmongChat.Room.UserListViewController {
    
    enum RoomType {
        case amongUsMatch
        case global
        case amongUsPrivate
    }
    
    private var roomType: RoomType {
        if channel.name.hasPrefix("_@") {
            return .amongUsPrivate
        } else if channel.name.hasPrefix("@") {
            return .amongUsMatch
        } else {
            return .global
        }
    }
    
}
