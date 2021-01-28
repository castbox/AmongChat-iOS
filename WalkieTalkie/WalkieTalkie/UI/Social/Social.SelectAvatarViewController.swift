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
            iv.layer.cornerRadius = 50
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
        
        let navLayoutGuide = UILayoutGuide()
        view.addLayoutGuide(navLayoutGuide)
        navLayoutGuide.snp.makeConstraints { (maker) in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(topLayoutGuide.snp.bottom)
            maker.height.equalTo(49)
        }
        
        view.addSubviews(views: backBtn, avatarIV, nameLabel, avatarCollectionView)
        
        backBtn.snp.makeConstraints { (maker) in
            maker.leading.equalToSuperview().offset(20)
            maker.centerY.equalTo(navLayoutGuide)
            maker.width.height.equalTo(24)
        }
        
        avatarIV.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.width.height.equalTo(100)
            maker.top.equalTo(navLayoutGuide.snp.bottom).offset(40)
        }
        
        nameLabel.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.leading.greaterThanOrEqualToSuperview().offset(20)
            maker.top.equalTo(avatarIV.snp.bottom).offset(8)
        }
        
        avatarCollectionView.snp.makeConstraints { (maker) in
            maker.leading.trailing.bottom.equalToSuperview()
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
        
        nameLabel.attributedText = profile.nameWithVerified(fontSize: 20, withAge: true)
        
        nameLabel.appendKern()
        
        avatarIV.setAvatarImage(with: profile.pictureUrl)
    }
    
    private func useAvatar(_ avatar: AvatarViewModel) -> Single<Entity.UserProfile?> {
        let profileProto = Entity.ProfileProto(birthday: nil, name: nil, pictureUrl: avatar.avatarUrl)
        return Request.updateProfile(profileProto)
    }

    private func unlockAvatar(for avatar: AvatarViewModel, _ indexPath: IndexPath) -> Observable<Void> {
        return AdsManager.shared.earnARewardOfVideo(fromVC: self, adPosition: .unlockAvatar)
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
    
    private func upgradePro() {
        guard !Settings.shared.isProValue.value,
              let premiun = R.storyboard.main.premiumViewController() else {
            return
        }
        premiun.style = .likeGuide
        premiun.source = .setting
        premiun.dismissHandler = { (purchased) in
            premiun.dismiss(animated: true) {
                guard purchased else { return }
                AmongChat.Login.canDoLoginEvent(style: .authNeeded(source: R.string.localizable.amongChatLoginAuthSourcePro()))
            }
        }
        premiun.modalPresentationStyle = .fullScreen
        present(premiun, animated: true, completion: nil)
        Logger.UserAction.log(.update_pro, "settings")
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
            
            //select pro item
            if avatar.locked,
               !Settings.shared.isProValue.value,
               avatar.avatar.unlockType == .premium {
                //go to premium page
                Logger.Action.log(.profile_avatar_get, category: .premium, "\(avatar.avatarId)")
                return upgradePro()
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
                
                rewardVideoDispose?.dispose()
                
                rewardVideoDispose =
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
                        if let _ = error as? RxError {
                            self?.view.raft.autoShow(.text(R.string.localizable.amongChatRewardVideoLoadFailed()), backColor: UIColor(hex6: 0x2E2E2E))
                        } else {
                            self?.view.raft.autoShow(.text(error.localizedDescription), backColor: UIColor(hex6: 0x2E2E2E))
                        }
                    })
                rewardVideoDispose?.disposed(by: bag)
                
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
            contentView.clipsToBounds = true
            
            contentView.addSubviews(views: avatarIV, selectedIcon, adBadge)
            
            avatarIV.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(34)
                maker.width.equalTo(avatarIV.snp.height).multipliedBy(1)
                maker.centerY.equalToSuperview()
            }
            
            selectedIcon.snp.makeConstraints { (maker) in
                maker.top.right.equalToSuperview()
                maker.width.equalTo(44)
                maker.height.equalTo(32)
            }
            
            adBadge.snp.makeConstraints { (maker) in
                maker.top.right.equalToSuperview()
                maker.width.equalTo(44)
                maker.height.equalTo(32)
            }
        }
        
        func bind(viewmModel avatar: AvatarViewModel) {
            
            avatarIV.setImage(with: URL(string: avatar.avatarUrl))
            
            selectedIcon.isHidden = avatar.locked
            adBadge.isHidden = !avatar.locked
            
            selectedIcon.image = avatar.selected ? R.image.ac_avatar_selected() : R.image.ac_avatar_unselected()
            switch avatar.avatar.unlockType {
            case .rewarded:
                adBadge.image = R.image.ac_avatar_ad()
            case .premium:
                adBadge.image = R.image.ac_avatar_pro()
            default:
                ()
            }
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
