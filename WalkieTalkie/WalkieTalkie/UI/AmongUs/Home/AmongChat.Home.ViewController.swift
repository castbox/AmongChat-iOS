//
//  AmongChat.Home.ViewController.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/11/25.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import MoPub
import CastboxDebuger
import RxCocoa
import RxSwift
import SwiftyUserDefaults
import AgoraRtcKit

extension AmongChat.Home {
    
    class ViewController: WalkieTalkie.ViewController {
        
        private typealias HashTagCell = AmongChat.Home.HashTagCell
        private typealias HashTag = AmongChat.Home.HashTag
        
        static let shared = AmongChat.Home.ViewController()
        
        // MARK: - members
        
        private lazy var bgImageView: UIImageView = {
            let i = UIImageView(image: R.image.star_bg())
            return i
        }()
        
        private lazy var haloView: UIView = {
            let v = UIView()
            v.backgroundColor = .clear
            v.layer.borderColor = UIColor.white.cgColor
            v.layer.borderWidth = 1
            return v
        }()
        
        private lazy var premiumBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.setImage(R.image.icon_setting_diamonds(), for: .normal)
            btn.addTarget(self, action: #selector(onPremiumBtn), for: .primaryActionTriggered)
            return btn
        }()
        
        private lazy var hashTagBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.titleLabel?.font = R.font.blackOpsOneRegular(size: 30)
            btn.setTitleColor(.black, for: .normal)
            btn.setTitle("#", for: .normal)
            btn.addTarget(self, action: #selector(onHashBtn), for: .primaryActionTriggered)
            btn.layer.cornerRadius = 10
            btn.backgroundColor = UIColor(hex6: 0xFFD52E, alpha: 1.0)
            return btn
        }()
        
        private lazy var avatarBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.addTarget(self, action: #selector(onAvatarBtn), for: .primaryActionTriggered)
            btn.layer.borderWidth = 2
            btn.layer.borderColor = UIColor.white.cgColor
            return btn
        }()
        
        private lazy var nameLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoRegular(size: 12)
            lb.textColor = .black
            return lb
        }()
        
        private lazy var editNameBtn: UIView = {
            let v = UIView()
            let icon = UIImageView(image: R.image.home_name_edit()?.withRenderingMode(.alwaysTemplate))
            icon.contentMode = .scaleAspectFit
            icon.tintColor = .black
            let tapGR = UITapGestureRecognizer(target: self, action: #selector(onEditNameBtn))
            v.addGestureRecognizer(tapGR)
            v.layer.cornerRadius = 10
            v.backgroundColor = .white
            v.isHidden = true
            
            v.addSubviews(views: nameLabel, icon)
            
            nameLabel.snp.makeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.left.equalToSuperview().inset(10)
            }
            
            icon.snp.makeConstraints { (maker) in
                maker.width.height.equalTo(14)
                maker.centerY.equalToSuperview()
                maker.right.equalToSuperview().inset(5)
                maker.left.equalTo(nameLabel.snp.right).offset(5)
            }
            
            return v
        }()
        
        private lazy var hashTagsTitle: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoRegular(size: 16)
            lb.textColor = .white
            lb.text = R.string.localizable.amomgChatHomeHashTagsTitle()
            return lb
        }()
        
        private lazy var moreRoomsBtn: UIView = {
            let v = UIView()
            
            let tapGR = UITapGestureRecognizer(target: self, action: #selector(onMoreRoomsBtn))
            v.addGestureRecognizer(tapGR)

            v.backgroundColor = .clear
            
            let lb = UILabel()
            lb.font = R.font.nunitoRegular(size: 14)
            lb.textColor = UIColor.white.alpha(0.8)
            lb.text = R.string.localizable.amongChatHomeHashTagsMore()
            
            let icon = UIImageView(image: R.image.backNor()?.rotated(by: .pi)?.withRenderingMode(.alwaysTemplate))
            icon.tintColor = UIColor.white.alpha(0.8)
            icon.contentMode = .scaleAspectFill
            
            v.addSubviews(views: lb, icon)
            
            lb.snp.makeConstraints { (maker) in
                maker.left.centerY.equalToSuperview()
            }
            
            icon.snp.makeConstraints { (maker) in
                maker.centerY.right.equalToSuperview()
                maker.left.equalTo(lb.snp.right)
                maker.width.height.equalTo(14)
            }
            
            v.isHidden = true
            
            return v
        }()
        
        private lazy var hashTagCollectionView: UICollectionView = {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .vertical
            let hInset: CGFloat = 16
            let itemSpacing: CGFloat = 7
            let cellWidth = (UIScreen.main.bounds.width - hInset * 2 - itemSpacing) / 2
            layout.itemSize = CGSize(width: cellWidth, height: 40)
            layout.minimumInteritemSpacing = itemSpacing
            layout.minimumLineSpacing = 8
            layout.sectionInset = UIEdgeInsets(top: 12, left: hInset, bottom: 12, right: hInset)
            let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
            v.register(HashTagCell.self, forCellWithReuseIdentifier: NSStringFromClass(HashTagCell.self))
            v.showsVerticalScrollIndicator = false
            v.showsHorizontalScrollIndicator = false
            v.dataSource = self
            v.delegate = self
            v.backgroundColor = .clear
            return v
        }()
        
        private lazy var requestMicBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.addTarget(self, action: #selector(onRequestMicBtn), for: .primaryActionTriggered)
            return btn
        }()
        
        private lazy var adView: MPAdView? = {
            let adView = MPAdView(adUnitId: "4334cad9c4e244f8b432635d48104bb9")
            adView?.delegate = self
            adView?.frame = CGRect(origin: .zero, size: kMPPresetMaxAdSizeMatchFrame)
            return adView
        }()
        
        private lazy var mManager: ChatRoomManager = {
            let manager = ChatRoomManager.shared
            manager.delegate = self
            return manager
        }()
                
        private let joinChannelSubject = BehaviorSubject<Room?>(value: nil)
        
        private typealias ChannelCategory = FireStore.ChannelCategory
        
        private lazy var hashTags: [HashTag] = {
            return [
                ChannelCategory(id: 101, name: R.string.localizable.amongChatHomeTagAmongA(), type: .amongUs),
                ChannelCategory(id: 100, name: R.string.localizable.amongChatHomeTagGroup(), type: .groupChat),
                ChannelCategory(id: 0, name: R.string.localizable.amongChatHomeTagCreatePrivate(), type: .createSecret),
                ChannelCategory(id: 0, name: R.string.localizable.amongChatHomeTagJoinPrivate(), type: .joinSecret)
            ].map { mapHastTag(from: $0) }
        }() {
            didSet {
                hashTagCollectionView.reloadData()
                let h = hashTagCollectionView.collectionViewLayout.collectionViewContentSize.height
                hashTagCollectionView.snp.updateConstraints { (maker) in
                    maker.height.equalTo(h)
                }
            }
        }
        
        private var hudRemoval: (() -> Void)? = nil
        
        //MARK: - inherited
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
            setupEvents()
        }
        
        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            let h = hashTagCollectionView.collectionViewLayout.collectionViewContentSize.height
            hashTagCollectionView.snp.updateConstraints { (maker) in
                maker.height.equalTo(h)
            }
            avatarBtn.layer.cornerRadius = avatarBtn.bounds.width / 2
            haloView.layer.cornerRadius = haloView.bounds.width / 2
        }
    }
    
}

extension AmongChat.Home.ViewController {

    //MARK: - UI Action
    
    @objc
    private func onPremiumBtn() {
        let premium = R.storyboard.main.premiumViewController()!
        premium.style = .likeGuide
        premium.source = .iap_home
        premium.dismissHandler = {
            premium.dismiss(animated: true, completion: nil)
        }
        premium.modalPresentationStyle = .fullScreen
        present(premium, animated: true, completion: nil)
    }
    
    @objc
    private func onHashBtn() {
        let vc = AmongChat.Home.ChannelInputViewController()
        
        vc.joinChannel = { [weak self] name, autoShare in
            guard let `self` = self else { return }
            guard let cat = FireStore.shared.allChannelCategories.first(where: { $0.name == name }),
            cat.type != .joinSecret,
            cat.type != .createSecret else {
                self._joinRoom(FireStore.shared.findAGroupChatRoom(with: name))
                return
            }
            self._joinRoom(FireStore.shared.findARoom(of: cat))
        }
        
        vc.onDismiss = { [weak self] in
            self?.hashTagBtn.isHidden = false
        }
        
        vc.modalPresentationStyle = .overCurrentContext
        present(vc, animated: false) { [weak self] in
            self?.hashTagBtn.isHidden = true
        }
        
    }

    @objc
    private func onAvatarBtn() {
        let vc = Social.ProfileViewController()
        navigationController?.pushViewController(vc)
    }
    
    @objc
    private func onEditNameBtn() {
        let vc = Social.EditProfileViewController()
        navigationController?.pushViewController(vc, completion: {
            Ad.InterstitialManager.shared.showAdIfReady(from: vc)
        })
    }
    
    @objc
    private func onMoreRoomsBtn() {
        let vc = AmongChat.AllRooms.ViewController()
        navigationController?.pushViewController(vc)
        GuruAnalytics.log(event: "clk_all_rooms")
    }
    
    @objc
    private func onRequestMicBtn() {
        
    }
    
}

extension AmongChat.Home.ViewController {
    
    // MARK: -
    
    private func setupLayout() {
        isNavigationBarHiddenWhenAppear = true
        statusBarStyle = .lightContent
        view.backgroundColor = UIColor(hex6: 0x00011B)
        view.addSubviews(views: bgImageView, haloView, premiumBtn, hashTagBtn, avatarBtn, editNameBtn, hashTagsTitle, moreRoomsBtn, hashTagCollectionView)
        
        let avatarLayoutGuide = UILayoutGuide()
        view.addLayoutGuide(avatarLayoutGuide)
        
        avatarLayoutGuide.snp.makeConstraints { (maker) in
            maker.top.left.right.equalToSuperview()
            maker.bottom.equalTo(hashTagsTitle.snp.top)
        }
        
        bgImageView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        
        haloView.snp.makeConstraints { (maker) in
            maker.center.equalTo(avatarBtn)
            maker.size.equalTo(avatarBtn)
        }
        
        premiumBtn.snp.makeConstraints { (maker) in
            maker.width.height.equalTo(60)
            maker.top.equalTo(topLayoutGuide.snp.bottom)
            maker.left.equalTo(0)
        }
        
        hashTagBtn.snp.makeConstraints { (maker) in
            maker.right.equalToSuperview().inset(10)
            maker.width.height.equalTo(40)
            maker.centerY.equalTo(premiumBtn)
        }
        
        avatarBtn.snp.makeConstraints { (maker) in
            maker.center.equalTo(avatarLayoutGuide)
        }
        
        editNameBtn.snp.makeConstraints { (maker) in
            maker.bottom.equalTo(avatarBtn.snp.bottom)
            maker.centerX.equalTo(avatarBtn)
            maker.height.equalTo(20)
        }
        
        hashTagsTitle.snp.makeConstraints { (maker) in
            maker.bottom.equalTo(hashTagCollectionView.snp.top)
            maker.left.equalTo(16)
        }
        
        moreRoomsBtn.snp.makeConstraints { (maker) in
            maker.right.equalToSuperview().inset(16)
            maker.centerY.equalTo(hashTagsTitle)
            maker.height.equalTo(20)
        }
        
        hashTagCollectionView.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview()
            maker.bottom.equalTo(bottomLayoutGuide.snp.top).offset(-50)
            maker.height.equalTo(0)
        }
        
        if let adView = self.adView {
            view.addSubview(adView)
            adView.snp.makeConstraints { (maker) in
                maker.size.equalTo(CGSize(width: 320, height: 50))
                maker.bottom.equalTo(bottomLayoutGuide.snp.top)
                maker.centerX.equalToSuperview()
            }
        }
        
    }
    
    private func haloAnimation() {

        let borderWidthAni = CABasicAnimation(keyPath: "borderWidth")
        borderWidthAni.fromValue = 1
        borderWidthAni.toValue = 0
        
        let opacityAni = CABasicAnimation(keyPath: "opacity")
        opacityAni.fromValue = 1
        opacityAni.toValue = 0
        
        let scaleAni = CABasicAnimation(keyPath: "transform.scale")
        scaleAni.fromValue = 1
        scaleAni.toValue = 2.5

        let animationGroup = CAAnimationGroup()
        animationGroup.duration = 3;
        animationGroup.animations = [borderWidthAni, opacityAni, scaleAni]
        animationGroup.repeatCount = .greatestFiniteMagnitude
        animationGroup.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        haloView.layer.add(animationGroup, forKey: "halo animation")
    }
    
    private func setupEvents() {
        
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
                if isPro {
                    //remove ad
                    self?.adView?.stopAutomaticallyRefreshingContents()
                } else {
                    self?.adView?.loadAd()
                }
                self?.adView?.isHidden = isPro
                self?.premiumBtn.isHidden = isPro
            })
            .disposed(by: bag)
        
        Settings.shared.firestoreUserProfile.replay()
            .do(onNext: { [weak self] (profile) in
                guard profile == nil else {
                    return
                }
                self?.avatarBtn.setImage(FireStore.Entity.User.Profile.defaultAvatar(of: Int.init(Constants.sUserId)).0, for: .normal)
            })
            .filterNil()
            .subscribe(onNext: { [weak self] (profile) in
                let _ = profile.avatarObservable
                    .subscribe(onSuccess: { (image) in
                        self?.avatarBtn.setImage(image, for: .normal)
                    })
                self?.editNameBtn.isHidden = false
                self?.nameLabel.text = profile.name
            })
            .disposed(by: bag)
        
        joinChannelSubject
            .filterNil()
            .filter { !$0.name.isEmpty }
            .observeOn(MainScheduler.asyncInstance)
            .debounce(.seconds(1), scheduler: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] room in
                guard let `self` = self else { return }
                self._joinChannel(room) { (channel) in
                    let vc = AmongChat.Room.ViewController(channel: channel)
                    vc.modalPresentationStyle = .fullScreen
                    let transition = CATransition()
                    transition.duration = 0.5
                    transition.type = CATransitionType.push
                    transition.subtype = CATransitionSubtype.fromRight
                    transition.timingFunction = CAMediaTimingFunction(name:CAMediaTimingFunctionName.easeInEaseOut)
                    UIApplication.shared.keyWindow?.layer.add(transition, forKey: kCATransition)
                    self.present(vc, animated: false) { [weak self] in
                        self?.navigationController?.popToRootViewController(animated: false)
                    }
                }
            })
            .disposed(by: bag)
        
        Observable.merge(NotificationCenter.default.rx.notification(UIApplication.didBecomeActiveNotification).map({ _ in }), rx.viewDidAppear.map({ _ in }))
            .subscribe { [weak self] (_) in
                self?.haloAnimation()
            }
            .disposed(by: bag)
        
        FireStore.shared.isInReviewSubject
            .filter({ !$0 })
            .take(1)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                self.hashTags = {
                    return [
                        ChannelCategory(id: 101, name: R.string.localizable.amongChatHomeTagAmongB(), type: .amongUs),
                        ChannelCategory(id: 100, name: R.string.localizable.amongChatHomeTagGroup(), type: .groupChat),
                        ChannelCategory(id: 0, name: R.string.localizable.amongChatHomeTagCreatePrivate(), type: .createSecret),
                        ChannelCategory(id: 0, name: R.string.localizable.amongChatHomeTagJoinPrivate(), type: .joinSecret)
                    ].map { self.mapHastTag(from: $0) }
                }()
                self.moreRoomsBtn.isHidden = false
            })
            .disposed(by: bag)
    }
    
    private func mapHastTag(from channelCategory: ChannelCategory) -> HashTag {
        return HashTag(channelCategory: channelCategory) { [weak self] in
            guard let `self` = self else { return }
            switch channelCategory.type {
            case .createSecret:
                self.createPrivateChannel()
            case .joinSecret:
                self.showJoinSecretChannel()
            default:
                self._joinRoom(FireStore.shared.findARoom(of: channelCategory))
            }
            Logger.Channel.logChannelCategoryClick(id: channelCategory.id, source: .home)
        }
    }
    
    private func loadAdView() {
        adView?.loadAd(withMaxAdSize: kMPPresetMaxAdSizeMatchFrame)
        Logger.Ads.logEvent(.ads_load, .channel)
        adView?.startAutomaticallyRefreshingContents()
    }
    
    @discardableResult
    private func _joinChannel(_ room: Room, completionBlock: ((Room) -> Void)? = nil) -> Bool {

        let name = room.name
        var channel = room
        
        guard !name.isEmpty else {
            return false
        }

        if mManager.isConnectedState && mManager.channelName == name {
           return false
        }
        
        guard !channel.isReachMaxUser else {
            //离开当前房间
            leaveChannel()
            return false
        }
        SpeechRecognizer.default.requestAuthorize { [weak self] _ in
            guard let `self` = self else { return }
            self.checkMicroPermission { [weak self] in
                guard let `self` = self else { return }
                self.mManager.joinChannel(channelId: name) {
                    self.hudRemoval?()
                    self.hudRemoval = nil
                    channel.updateJoinInterval()
                    HapticFeedback.Impact.success()
                    UIApplication.shared.isIdleTimerDisabled = true
                    ChannelUserListViewModel.shared.didJoinedChannel(name)
                    completionBlock?(channel)
                }
            }
        }
        
        return true
    }
    
    private func leaveChannel() {
        UIApplication.shared.isIdleTimerDisabled = false
        mManager.leaveChannel { (name) in
            ChannelUserListViewModel.shared.leavChannel(name)
        }
    }
    
    /// 获取麦克风权限
    private func checkMicroPermission(completion: @escaping ()->()) {
        weak var welf = self
        AVAudioSession.sharedInstance().requestRecordPermission { isOpen in
            if !isOpen {
                let alertVC = UIAlertController(title: NSLocalizedString("“WalkieTalkie” would like to Access the Microphone", comment: ""),
                                                message: NSLocalizedString("To join the channel, please switch on microphone permission.", comment: ""),
                                                preferredStyle: UIAlertController.Style.alert)
                let resetAction = UIAlertAction(title: NSLocalizedString("Go Settings", comment: ""), style: .default, handler: { _ in
                    
                    if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.openURL(url)
                    }
                })
                
                let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { _ in
                    /// do nothing
                }
                alertVC.addAction(cancelAction)
                alertVC.addAction(resetAction)
                DispatchQueue.main.async {
                    welf?.present(alertVC, animated: true, completion: nil)
                }
            } else {
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
    }
    
    private func _joinRoom(_ room: Single<Room>) {
        
        let networkNotReachAlertBlock = { [weak self] in
            let alert = UIAlertController(title: R.string.localizable.networkNotReachable(), message: nil, preferredStyle: .alert)
            alert.addAction(.init(title: R.string.localizable.toastConfirm(), style: .default, handler: nil))
            self?.present(alert, animated: true, completion: nil)
        }
        
        guard Reachability.shared.canReachable else {
            networkNotReachAlertBlock()
            return
        }
        
        self.view.isUserInteractionEnabled = false
        let removeBlock = self.view.raft.show(.loading, userInteractionEnabled: false)
        self.hudRemoval = {
            removeBlock()
            self.view.isUserInteractionEnabled = true
        }
        
        room.subscribe(onSuccess: { (room) in
            self.joinChannelSubject.onNext(room)
        })
        .disposed(by: bag)
        
    }
    
    private func showJoinSecretChannel() {
        let controller = AmongChat.Home.JoinSecretViewController()
        controller.joinChannel = { name, autoShare in
            self._joinRoom(FireStore.shared.findAPrivateRoom(with: name))
        }
        controller.showModal(in: self)
    }
    
    private func createPrivateChannel() {
        
        let networkNotReachAlertBlock = { [weak self] in
            let alert = UIAlertController(title: R.string.localizable.networkNotReachable(), message: nil, preferredStyle: .alert)
            alert.addAction(.init(title: R.string.localizable.toastConfirm(), style: .default, handler: nil))
            self?.present(alert, animated: true, completion: nil)
        }
        
        Observable.just(())
            .observeOn(MainScheduler.asyncInstance)
            .filter { _ -> Bool in
                guard Reachability.shared.canReachable else {
                    networkNotReachAlertBlock()
                    return false
                }
                return true
            }
            .flatMap { [weak self] _ -> Observable<Void> in
                Logger.UserAction.log(.create_secret)
                guard let `self` = self,
                      !Settings.shared.isProValue.value,
                      let reward = AdsManager.shared.aviliableRewardVideo else {
                    return Observable.just(())
                }
                
                return Observable.just(())
                    .filter({ _ in
                        MPRewardedVideo.presentAd(forAdUnitID: AdsManager.shared.rewardedVideoId, from: self, with: reward)
                        return true
                    })
                    .flatMap { _ -> Observable<Void> in
                        return AdsManager.shared.rewardVideoShouldReward.asObserver()
                    }
                    .do(onNext: { _ in
                        AdsManager.shared.requestRewardVideoIfNeed()
                    })
                    .flatMap { _ -> Observable<Void> in
                        return AdsManager.shared.rewardedVideoAdDidDisappear.asObservable()
                    }
            }
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                self._joinRoom(FireStore.shared.findAPrivateRoom())
            })
            .disposed(by: bag)
    }
    
    func joinRoom(with name: String) {
        let room = Room(name: name, user_count: 0)
        _joinRoom(Observable.just(room).asSingle())
    }

    func joinRoom(with room: Single<Room>) {
        _joinRoom(room)
    }

}

extension AmongChat.Home.ViewController: UICollectionViewDataSource {
    
    // MARK: - UICollectionView
        
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return hashTags.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(HashTagCell.self), for: indexPath)
        if let cell = cell as? HashTagCell,
           let hashTag = hashTags.safe(indexPath.item) {
            cell.configCell(with: hashTag)
        }
        return cell
    }
    
}

extension AmongChat.Home.ViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let hashTag = hashTags.safe(indexPath.item) {
            hashTag.didSelect()
        }
    }
    
}

extension AmongChat.Home.ViewController: MPAdViewDelegate {
    
    //MARK: - MPAdViewDelegate
    
    func viewControllerForPresentingModalView() -> UIViewController! {
        if let naviVC = self.navigationController {
            return naviVC
        } else {
            return self
        }
    }

    func adViewDidLoadAd(_ view: MPAdView!, adSize: CGSize) {
        mlog.debug("[AD]-adViewDidLoadAd")
        Logger.Ads.logEvent(.ads_loaded, .channel)
    }

    func adView(_ view: MPAdView!, didFailToLoadAdWithError error: Error!) {
        mlog.debug("[AD]-load ad error: \(error.localizedDescription)")
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

extension AmongChat.Home.ViewController: ChatRoomDelegate {
    // MARK: - ChatRoomDelegate
    
    func onJoinChannelFailed(channelId: String?) {
        self.hudRemoval?()
        self.hudRemoval = nil
        
        view.raft.autoShow(.text(R.string.localizable.amongChatRoomTipTimeout()))
        
        Observable.just(())
            .delay(.fromSeconds(0.6), scheduler: MainScheduler.asyncInstance)
            .filter { [weak self] _  -> Bool in
                guard let `self` = self else { return false }
                return self.mManager.state != .connected
            }
            .subscribe(onNext: { _ in
            })
            .disposed(by: bag)
    }
    
    func onJoinChannelTimeout(channelId: String?) {
        self.hudRemoval?()
        self.hudRemoval = nil
        
        view.raft.autoShow(.text(R.string.localizable.amongChatRoomTipTimeout()))
        
        Observable.just(())
            .observeOn(MainScheduler.asyncInstance)
            .filter { [weak self] _  -> Bool in
                guard let `self` = self else { return false }
                return self.mManager.state != .connected
            }
            .do(onNext: { [weak self] _ in
                self?.leaveChannel()
            })
            .delay(.fromSeconds(0.6), scheduler: MainScheduler.asyncInstance)
            .filter { [weak self] _  -> Bool in
                guard let `self` = self else { return false }
                return self.mManager.state != .connected
            }
            .subscribe(onNext: { _ in
            })
            .disposed(by: bag)
    }

    func onConnectionChangedTo(state: ConnectState, reason: AgoraConnectionChangedReason) {
    }
    
    func onSeatUpdated(position: Int) {
    }

    func onUserGivingGift(userId: String) {
    }

    func onMessageAdded(position: Int) {
    }

    func onMemberListUpdated(userId: String?) {
    }

    func onUserStatusChanged(userId: UInt, muted: Bool) {
        if Constants.isMyself(userId) {
            
        } else {
            //check block
            if let user = ChannelUserListViewModel.shared.blockedUsers.first(where: { $0.uid == userId }) {
                mManager.adjustUserPlaybackSignalVolume(user, volume: 0)
            } else if ChannelUserListViewModel.shared.mutedUserValue.contains(userId) {
                mManager.adjustUserPlaybackSignalVolume(ChannelUser.randomUser(uid: userId), volume: 0)
            }
        }
    }
    
    func onAudioMixingStateChanged(isPlaying: Bool) {

    }

    func onAudioVolumeIndication(userId: UInt, volume: UInt) {
        ChannelUserListViewModel.shared.updateVolumeIndication(userId: userId, volume: volume)
    }
    
    func onChannelUserChanged(users: [ChannelUser]) {
        ChannelUserListViewModel.shared.update(users)
    }
}
