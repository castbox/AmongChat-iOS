//
//  Social.SelectAvatarViewController.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/12/22.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import MoPub

extension Social {
    
    class SelectAvatarViewController: WalkieTalkie.ViewController {
        
        private lazy var backBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.addTarget(self, action: #selector(onBackBtn), for: .primaryActionTriggered)
            btn.setImage(R.image.ac_profile_close(), for: .normal)
            return btn
        }()
        
        private lazy var avatarIV: UIImageView = {
            let iv = UIImageView()
            iv.layer.cornerRadius = 45
            iv.layer.masksToBounds = true
            return iv
        }()
        
        private lazy var nameLabel: WalkieLabel = {
            let lb = WalkieLabel()
            lb.font = R.font.nunitoExtraBold(size: 20)
            lb.textColor = .white
            lb.textAlignment = .center
            return lb
        }()
        
        private lazy var avatarCollectionView: UICollectionView = {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .vertical
            let hInset: CGFloat = 20
            let interSpace: CGFloat = 20
            let hwRatio: CGFloat = 1
            let cellWidth = (UIScreen.main.bounds.width - hInset * 2 - interSpace) / 2
            let cellHeight = cellWidth * hwRatio
            layout.itemSize = CGSize(width: cellWidth, height: cellHeight)
            layout.minimumInteritemSpacing = interSpace
            layout.minimumLineSpacing = 20
            layout.sectionInset = UIEdgeInsets(top: 20, left: hInset, bottom: Frame.Height.safeAeraBottomHeight, right: hInset)
            let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
            v.register(AvatarCell.self, forCellWithReuseIdentifier: NSStringFromClass(AvatarCell.self))
            v.showsVerticalScrollIndicator = false
            v.showsHorizontalScrollIndicator = false
            v.dataSource = self
            v.delegate = self
            v.backgroundColor = .clear
            v.alwaysBounceVertical = true
            return v
        }()
        
        private lazy var avatarDataSource: [AvatarViewModel] = {
            return []
        }()
        {
            didSet {
                avatarCollectionView.reloadData()
            }
        }
        
        @available(*, deprecated)
        private var rewardVideoDispose: Disposable?
        
        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
            setupData()
//            AdsManager.shared.requestRewardVideoIfNeed()
        }
    }
    
}

extension Social.SelectAvatarViewController {
    
    // MARK: - UI Action
    
    @objc
    func onBackBtn() {
        navigationController?.popViewController()
    }
    
}

extension Social.SelectAvatarViewController {
    
    // MARK: - convinient
    private func setupLayout() {
        
        view.addSubviews(views: backBtn, avatarIV, nameLabel, avatarCollectionView)
        
        backBtn.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview().offset(20)
            maker.top.equalToSuperview().offset(16 + Frame.Height.safeAeraTopHeight)
            maker.width.height.equalTo(24)
        }
        
        avatarIV.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.width.height.equalTo(90)
            maker.top.equalTo(topLayoutGuide.snp.bottom).offset(69)
        }
        
        nameLabel.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.left.greaterThanOrEqualToSuperview().offset(20)
            maker.top.equalTo(avatarIV.snp.bottom).offset(8)
        }
        
        avatarCollectionView.snp.makeConstraints { (maker) in
            maker.left.right.bottom.equalToSuperview()
            maker.top.equalTo(nameLabel.snp.bottom).offset(30)
        }
    }
    
    private func setupData() {
        
        Settings.shared.amongChatUserProfile.replay()
            .subscribe(onNext: { [weak self] (profile) in
                guard let profile = profile else { return }
                self?.configProfile(profile)
            })
            .disposed(by: bag)
        
        rx.viewDidAppear
            .take(1)
            .subscribe(onNext: { (_) in
                Settings.shared.amongChatAvatarListShown.value = Date().timeIntervalSince1970
                Logger.Action.log(.profile_avatar_imp)
            })
            .disposed(by: bag)
        
        fetchDefaultAvatars()
    }
    
    private func fetchDefaultAvatars() {
        
        let hudRemoval = view.raft.show(.loading, userInteractionEnabled: false)
        
        // 获取系统头像
        Request.defaultAvatars(withLocked: 1)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onSuccess: { [weak self] (avatars) in
                hudRemoval()
                guard let avatarList = avatars?.avatarList else {
                    return
                }
                
                self?.avatarDataSource = avatarList.map({ AvatarViewModel(with: $0) })
            }, onError: { (error) in
                hudRemoval()
            })
            .disposed(by: bag)
        
    }
    
    private func configProfile(_ profile: Entity.UserProfile) {
        
        if let b = profile.birthday, !b.isEmpty {
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd"
            
            if let startDate = dateFormatter.date(from: b)  {
                
                let endDate = Date()
                
                let calendar = Calendar.current
                let calcAge = calendar.dateComponents([.year], from: startDate, to: endDate)
                
                if let age = calcAge.year?.string, !age.isEmpty {
                    nameLabel.text = "\(profile.name ?? ""), \(age)"
                } else {
                    nameLabel.text = profile.name
                }
            } else {
                nameLabel.text = profile.name
            }
        } else {
            nameLabel.text = profile.name
        }
        
        nameLabel.appendKern()
        
        avatarIV.setAvatarImage(with: profile.pictureUrl)
    }
    
    @available(*, deprecated)
    private func updateProfileIfNeeded(_ profileProto: Entity.ProfileProto) {
        if let dict = profileProto.dictionary {
            let hudRemoval = view.raft.show(.loading, userInteractionEnabled: false)
            Request.updateProfile(dict)
                .do(onDispose: {
                    hudRemoval()
                })
                .subscribe(onSuccess: { (profile) in
                    
                    guard let p = profile else {
                        return
                    }
                    Settings.shared.amongChatUserProfile.value = p
                }, onError: { (error) in
                })
                .disposed(by: bag)
        }
    }
    
    private func useAvatar(_ avatar: AvatarViewModel) -> Single<Entity.UserProfile?> {
        let profileProto = Entity.ProfileProto(birthday: nil, name: nil, pictureUrl: avatar.avatarUrl)
        return Request.updateProfile(profileProto)
    }
    
    @available(*, deprecated)
    func showRewardVideo(for avatar: AvatarViewModel, _ indexPath: IndexPath) {
        let hudRemoval = view.raft.show(.loading)
//        AdsManager.shared.requestRewardVideoIfNeed()
        rewardVideoDispose?.dispose()
        rewardVideoDispose =
            AdsManager.shared.isRewardVideoReadyRelay
            .timeout(.seconds(15), scheduler: MainScheduler.asyncInstance)
            .filter { $0 }
            .take(1)
            .flatMap { [weak self] _ -> Observable<Void> in
                guard let `self` = self else { return  .empty() }
//                guard let reward = AdsManager.shared.aviliableRewardVideo else {
//                    self.view.raft.autoShow(.text(R.string.localizable.amongChatRewardVideoLoadFailed()))
//                    hudRemoval()
//                    return Observable.empty()
//                }
                
                return Observable.just(())
                    .filter({ [weak self] _ in
                        guard let `self` = self else {
                            return true
                        }
                        MPRewardedVideo.presentAd(forAdUnitID: AdsManager.shared.rewardedVideoId, from: self, with: nil)
                        return true
                    })
                    .flatMap { _ -> Observable<Bool> in
                        return AdsManager.shared.rewardVideoShouldReward.asObserver()
                    }
//                    .do(onNext: { _ in
//                        AdsManager.shared.requestRewardVideoIfNeed()
//                    })
                    .filter { [weak self] shouldReward -> Bool in
                        guard let `self` = self else { return false }
                        if !shouldReward {
                            self.view.raft.autoShow(.text(R.string.localizable.amongChatRewardVideoLoadFailed()))
                            hudRemoval()
                        }
                        return shouldReward
                    }
                    .flatMap { _ -> Observable<Void> in
                        return AdsManager.shared.rewardedVideoAdDidDisappear.asObservable()
                    }
            }
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                
                cdPrint("")
                
                Request.unlockAvatar(avatar.avatar)
                    .observeOn(MainScheduler.asyncInstance)
                    .subscribe(onSuccess: { (success) in
                        Logger.Action.log(.profile_avatar_get_success, category: .rewarded, "\(avatar.avatar.avatarId)")
                        hudRemoval()
                        let profileProto = Entity.ProfileProto(birthday: nil, name: nil, pictureUrl: avatar.avatarUrl)
                        self.updateProfileIfNeeded(profileProto)
                        avatar.unlock()
                        
                        for (idx, element) in self.avatarDataSource.enumerated() {
                            
                            if idx == indexPath.item {
                                element.selected = true
                            } else {
                                element.selected = false
                            }
                        }
                        
                        self.avatarCollectionView.reloadData()
                        self.fetchDefaultAvatars()
                    }, onError: { (error) in
                        hudRemoval()
                    })
                    .disposed(by: self.bag)
                
                
            }, onError: { (error) in
                self.view.raft.autoShow(.text(R.string.localizable.amongChatRewardVideoLoadFailed()))
                hudRemoval()
            })
        rewardVideoDispose?.addDisposableTo(bag)

    }
    
    private func unlockAvatar(for avatar: AvatarViewModel, _ indexPath: IndexPath) -> Observable<Void> {
        AdsManager.shared.requestRewardVideoIfNeed()
        return AdsManager.shared.isRewardVideoReadyRelay
            .filter { $0 }
            .take(1)
            .timeout(.seconds(15), scheduler: MainScheduler.asyncInstance)
            .flatMap { [weak self] _ -> Observable<Void> in
                guard let `self` = self else { return  .empty() }
                guard let reward = AdsManager.shared.aviliableRewardVideo else {
                    return Observable.error(MsgError(code: 400, msg: R.string.localizable.amongChatRewardVideoLoadFailed()))
                }
                
                MPRewardedVideo.presentAd(forAdUnitID: AdsManager.shared.rewardedVideoId, from: self, with: reward)
                
                return AdsManager.shared.rewardVideoShouldReward.asObservable()
                    .flatMap { shouldReward -> Observable<Void> in
                        guard shouldReward else {
                            return Observable.error(MsgError(code: 500, msg: R.string.localizable.amongChatRewardVideoLoadFailed()))
                        }
                        return AdsManager.shared.rewardedVideoAdDidDisappear.asObservable()
                            .do(onNext: { _ in
                                AdsManager.shared.requestRewardVideoIfNeed()
                            })
                    }
            }
            .flatMap({ _ -> Single<Void> in
                #if DEBUG
                return Single.just(())
                    .do(onSuccess: { (_) in
                        avatar.unlock()
                    })
                #else
                return Request.unlockAvatar(avatar.avatar)
                    .flatMap({ (success) -> Single<Void> in
                        guard success else {
                            return Single.error(MsgError(code: 500, msg: R.string.localizable.amongChatUnlockAvatarFailed()))
                        }
                        return Single.just(())
                    })
                    .do(onSuccess: { _ in
                        Logger.Action.log(.profile_avatar_get_success, category: .rewarded, "\(avatar.avatarId)")
                        avatar.unlock()
                    })
                #endif
            })
            .observeOn(MainScheduler.asyncInstance)
    }
    
    private func updateAvatarSelected(of index: Int) {
        
        for (idx, element) in avatarDataSource.enumerated() {
            if idx == index {
                element.selected = true
            } else {
                element.selected = false
            }
        }
        avatarCollectionView.reloadData()
    }
}

extension Social.SelectAvatarViewController: UICollectionViewDataSource {
    
    // MARK: - UICollectionView
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return avatarDataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(AvatarCell.self), for: indexPath)
        if let aCell = cell as? AvatarCell,
           let avatar = avatarDataSource.safe(indexPath.item) {
            aCell.bind(viewmModel: avatar)
        }
        return cell
    }
    
}

extension Social.SelectAvatarViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if let avatar = avatarDataSource.safe(indexPath.item) {
            guard avatar.selected == false else {
                return
            }
            
            let hudRemoval = view.raft.show(.loading, userInteractionEnabled: false)
            
            avatarCollectionView.isUserInteractionEnabled = false
            
            let completion = { [weak self] in
                hudRemoval()
                self?.avatarCollectionView.isUserInteractionEnabled = true
            }
            
            let updateProfile = useAvatar(avatar)
                .flatMap({ (p) -> Single<Entity.UserProfile> in
                    guard let profile = p else {
                        return Single.error(MsgError(code: 400, msg: R.string.localizable.amongChatUpdateProfileFailed()))
                    }
                    return Single.just(profile)
                })
                .observeOn(MainScheduler.asyncInstance)
                .do(onSuccess: { [weak self] (_) in
                    self?.updateAvatarSelected(of: indexPath.item)
                })
            
            if avatar.locked {
                Logger.Action.log(.profile_avatar_get, category: .rewarded, "\(avatar.avatarId)")
                unlockAvatar(for: avatar, indexPath)
                    .flatMap { (_) -> Single<Entity.UserProfile> in
                        return updateProfile
                    }
                    .take(1)
                    .asSingle()
                    .subscribe(onSuccess: { _ in
                        completion()
                    }, onError: { [weak self] (error) in
                        completion()
                        self?.view.raft.autoShow(.text(error.localizedDescription))
                    })
                    .disposed(by: bag)
                
            } else {
                Logger.Action.log(.profile_avatar_clk, category: .free, "\(avatar.avatarId)")
                updateProfile.subscribe(onSuccess: { (p) in
                    completion()
                }, onError: {[weak self] (error) in
                    completion()
                    self?.view.raft.autoShow(.text(error.localizedDescription))
                })
                .disposed(by: bag)
            }
        }
    }
    
}

extension Social.SelectAvatarViewController {
    
    class AvatarCell: UICollectionViewCell {
        
        private lazy var avatarIV: UIImageView = {
            let iv = UIImageView()
            iv.layer.masksToBounds = true
            iv.contentMode = .scaleToFill
            return iv
        }()
        
        private lazy var selectedIcon: UIImageView = {
            let iv = UIImageView()
            iv.contentMode = .scaleToFill
            iv.isHidden = true
            return iv
        }()
        
        private lazy var adBadge: UIImageView = {
            let iv = UIImageView()
            iv.image = R.image.ac_avatar_ad()
            iv.contentMode = .scaleToFill
            iv.isHidden = true
            return iv
        }()
                        
        override func layoutSubviews() {
            super.layoutSubviews()
            avatarIV.layoutIfNeeded()
            avatarIV.layer.cornerRadius = avatarIV.bounds.width / 2
        }
        
        override init(frame: CGRect) {
            super.init(frame: .zero)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupLayout() {
            contentView.backgroundColor = UIColor(hex6: 0x222222)
            contentView.layer.cornerRadius = 12
            
            contentView.addSubviews(views: avatarIV, selectedIcon, adBadge)
            
            avatarIV.snp.makeConstraints { (maker) in
                maker.left.right.equalToSuperview().inset(34)
                maker.width.equalTo(avatarIV.snp.height).multipliedBy(1)
                maker.centerY.equalToSuperview()
            }
            
            selectedIcon.snp.makeConstraints { (maker) in
                maker.top.left.equalToSuperview()
                maker.width.equalTo(44)
                maker.height.equalTo(32)
            }
            
            adBadge.snp.makeConstraints { (maker) in
                maker.top.left.equalToSuperview()
                maker.width.equalTo(44)
                maker.height.equalTo(32)
            }
        }
        
        func bind(viewmModel avatar: AvatarViewModel) {
            
            avatarIV.setImage(with: URL(string: avatar.avatarUrl))
            
            selectedIcon.isHidden = avatar.locked
            adBadge.isHidden = !avatar.locked
            
            selectedIcon.image = avatar.selected ? R.image.ac_avatar_selected() : R.image.ac_avatar_unselected()
        }
    }
    
}

extension Social.SelectAvatarViewController {
    
    class AvatarViewModel {
        
        private(set) var avatar: Entity.DefaultAvatar
        
        init(with avatar: Entity.DefaultAvatar) {
            self.avatar = avatar
        }
        
        var avatarUrl: String {
            return avatar.url
        }
        
        var locked: Bool {
            return avatar.lock
        }
        
        var avatarId: String {
            return avatar.avatarId
        }
        
        var selected: Bool {
            
            set {
                avatar.selected = newValue
            }
            
            get {
                return avatar.selected
            }
        }
        
        func unlock() {
            avatar.lock = false
        }
        
    }
    
}
