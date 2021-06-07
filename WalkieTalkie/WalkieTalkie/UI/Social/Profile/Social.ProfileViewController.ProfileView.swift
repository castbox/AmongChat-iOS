//
//  Social.ProfileViewController.ProfileView.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/5/19.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import SwiftyUserDefaults
import SVGAPlayer
import UICollectionViewLeftAlignedLayout

extension Social.ProfileViewController {
    
    class ProfileView: UIView {
        
        enum HeaderProfileAction {
            case edit
            case following
            case follower
            case avater
            case follow
            case heightUpdated
        }
        
        let bag = DisposeBag()
        
        var headerHandle:((HeaderProfileAction) -> Void)?
        
        private let avatarTop = Frame.Height.safeAeraTopHeight + NavigationBar.barHeight + 24
        private let avatarSize = CGSize(width: 100, height: 100)
        private let nameLabelTopSpace: CGFloat = 16
        private let nameLabelFont: UIFont = R.font.nunitoExtraBold(size: 24) ?? UIFont.systemFont(ofSize: 24, weight: .black)
        private let infoTopSpace: CGFloat = 8
        private let descriptionLabelTopSpace: CGFloat = 8
        private let relationContainerTopSpace: CGFloat = 24
        private let relationContainerHeight: CGFloat = VerticalTitleButton.height
        private let loginButtonTopSpace: CGFloat = 24
        private let loginButtonHeight: CGFloat = 48
        private let liveRoomTopSpace: CGFloat = 24
        private let liveRoomHeight: CGFloat = 56
        private let bottomSpace: CGFloat = 44
        private let petSize = CGSize(width: 70, height: 70)
        
        var estimatedViewHeight: CGFloat = 440
        
        var viewHeight: CGFloat {
            
            var height: CGFloat = 0
            
            height = height + avatarTop + avatarSize.height
            
            let nameHeight = nameLabel.attributedText?.string.height(forConstrainedWidth: UIScreen.main.bounds.width - Frame.horizontalBleedWidth * 2, font: nameLabelFont) ?? 33.0
            
            height = height + nameLabelTopSpace + nameHeight
            
            if infoItems.count > 0 {
                height = height + infoTopSpace + infoCollectionView.collectionViewLayout.collectionViewContentSize.height
            }
            
            if let _ = descriptionLabel.wholeString {
                height = height + descriptionLabelTopSpace + descriptionLabel.textHeight
            }
            
            height = height + relationContainerTopSpace + relationContainerHeight
            
            if isSelf,
               let isAnonymous = Settings.shared.loginResult.value?.isAnonymousUser,
               isAnonymous {
                height = height + loginButtonTopSpace + loginButtonHeight
            } else if !isSelf,
                      let _ = liveRoom {
                height = height + liveRoomTopSpace + liveRoomHeight
            }
            
            height = height + bottomSpace
            
            return height
        }
        
        private var liveRoom: ProfileLiveRoom? = nil {
            didSet {
                
                if let liveRoom = liveRoom {
                    
                    liveRoomView.coverIV.setImage(with: liveRoom.roomCover)
                    liveRoomView.label.text = liveRoom.roomName
                    liveRoomView.joinBtn.isEnabled = !liveRoom.isPrivate
                    penddingViewContainer.addSubview(liveRoomView)
                    
                    liveRoomView.snp.makeConstraints { (maker) in
                        maker.leading.trailing.equalToSuperview().inset(Frame.horizontalBleedWidth)
                        maker.height.equalTo(liveRoomHeight)
                        maker.top.equalToSuperview().offset(liveRoomTopSpace)
                        maker.bottom.equalToSuperview()
                    }
                    
                    if let room = liveRoom as? Entity.UserStatus.Room {
                        liveRoomView.joinHandler = { [weak self] in
                            self?.controller?.enterRoom(roomId: room.roomId, topicId: room.topicId)
                        }
                    } else if let group = liveRoom as? Entity.UserStatus.Group {
                        liveRoomView.joinHandler = { [weak self] in
                            self?.controller?.enter(group: group.gid)
                        }
                    }
                    
                } else {
                    liveRoomView.removeFromSuperview()
                }
                
                headerHandle?(.heightUpdated)
            }
        }
        
        private lazy var liveRoomView: LiveCell = {
            let cell = LiveCell(frame: .zero)
            return cell
        }()
        
        private typealias BigCoverView = FansGroup.Views.GroupBigCoverView
        private lazy var bg: BigCoverView = {
            let b = BigCoverView()
            b.bottomCornerRadius = 0
            b.coverRelay.accept(R.image.ac_profile_avatar())
            avatarIV.imageOb
                .bind(to: b.coverRelay)
                .disposed(by: bag)
            let mask = UIView()
            mask.backgroundColor = UIColor.black.withAlphaComponent(0.65)
            b.insertSubview(mask, belowSubview: b.blurView)
            mask.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
            return b
        }()
                
        private lazy var avatarIV: AvatarImageView = {
            let iv = AvatarImageView()
            let tapGR = UITapGestureRecognizer()
            tapGR.addTarget(self, action: #selector(onAvatarTapped))
            iv.isUserInteractionEnabled = true
            iv.addGestureRecognizer(tapGR)
            return iv
        }()
        
        private(set) lazy var changeIcon: UIImageView = {
            let iv = UIImageView(image: R.image.profile_avatar_random_btn())
            iv.isHidden = !isSelf
            return iv
        }()
        
        private lazy var petView: SVGAPlayer = {
            let player = SVGAPlayer(frame: .zero)
            player.clearsAfterStop = true
            player.contentMode = .scaleAspectFill
            player.isUserInteractionEnabled = false
            return player
        }()
        
        private lazy var nameLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 24)
            lb.textColor = .white
            lb.numberOfLines = 0
            return lb
        }()
        
        private(set) lazy var onlineStatusView: OnlineStatusView = {
            let o = OnlineStatusView()
            o.isHidden = true
            return o
        }()
        
        private lazy var infoCollectionView: UICollectionView = {
            let layout = UICollectionViewLeftAlignedLayout()
            layout.scrollDirection = .vertical
            let hInset: CGFloat = 0
            let vInset: CGFloat = 0
            layout.minimumLineSpacing = 8
            layout.minimumInteritemSpacing = 20
            layout.sectionInset = UIEdgeInsets(top: vInset, left: hInset, bottom: vInset, right: hInset)
            let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
            v.register(InfoCell.self, forCellWithReuseIdentifier: NSStringFromClass(InfoCell.self))
            v.showsVerticalScrollIndicator = false
            v.showsHorizontalScrollIndicator = false
            v.dataSource = self
            v.delegate = self
            v.backgroundColor = .clear
            return v
        }()
        
        private var infoItems = [InfoItem]() {
            didSet {
                infoCollectionView.reloadData()
                infoCollectionView.layoutIfNeeded()
                infoCollectionView.snp.updateConstraints { (maker) in
                    maker.height.equalTo(infoCollectionView.collectionViewLayout.collectionViewContentSize.height)
                }
            }
        }
        
        private typealias ExpandableLabel = FansGroup.GroupInfoViewController.ExpandableLabel
        private lazy var descriptionLabel: ExpandableLabel = {
            let l = ExpandableLabel(contentTextFont: R.font.nunitoBold(size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .bold),
                                    contentTextColor: UIColor(hex6: 0xFFFFFF, alpha: 0.6),
                                    expandTextFont: R.font.nunitoBold(size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .bold))
            l.numberOfLines = 0
            l.expandedHandler = { [weak self] in
                self?.headerHandle?(.heightUpdated)
                l.snp.updateConstraints { (maker) in
                    maker.height.equalTo(l.textHeight)
                }
            }
            return l
        }()
        
        private lazy var followingBtn: VerticalTitleButton = {
            let v = VerticalTitleButton()
            v.setTitle("0")
            v.setSubtitle(R.string.localizable.profileLittleFollowing())
            let tapGR = UITapGestureRecognizer()
            tapGR.addTarget(self, action: #selector(onFollowingBtn))
            v.isUserInteractionEnabled = true
            v.addGestureRecognizer(tapGR)
            return v
        }()
        
        private lazy var relationContainer: UIView = {
            let view = UIView()
            view.addSubviews(views: followingBtn, followerBtn)
            
            followingBtn.snp.makeConstraints { (maker) in
                maker.leading.top.bottom.equalToSuperview()
                maker.width.lessThanOrEqualTo(view.snp.width).multipliedBy(0.5).offset(20)
            }
            
            followerBtn.snp.makeConstraints { (maker) in
                maker.leading.equalTo(followingBtn.snp.trailing).offset(40)
                maker.top.bottom.equalToSuperview()
                maker.width.lessThanOrEqualTo(view.snp.width).multipliedBy(0.5).offset(20)
            }
            
            return view
        }()
        
        private lazy var penddingViewContainer: UIView = {
            let v = UIView()
            return v
        }()
        
        private lazy var followerBtn: VerticalTitleButton = {
            let v = VerticalTitleButton()
            v.setTitle("0")
            v.titleLabel.snp.remakeConstraints { (maker) in
                maker.leading.top.equalToSuperview()
                maker.trailing.lessThanOrEqualTo(0)
                maker.height.equalTo(30)
            }
            v.setSubtitle(R.string.localizable.profileLittleFollower())
            let tapGR = UITapGestureRecognizer()
            tapGR.addTarget(self, action: #selector(onFollowerBtn))
            v.isUserInteractionEnabled = true
            v.addGestureRecognizer(tapGR)
            return v
        }()
        
        private lazy var editBtn: UIButton = {
            let btn = UIButton(type: .custom)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 16)
            btn.setTitle(R.string.localizable.profileEditTitle(), for: .normal)
            btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
            btn.backgroundColor = UIColor(hex6: 0xFFFFFF, alpha: 0.12)
            btn.layer.cornerRadius = 18
            btn.clipsToBounds = true
            btn.addTarget(self, action: #selector(onEditBtn), for: .primaryActionTriggered)
            btn.isHidden = !isSelf
            return btn
        }()
        
        private lazy var loginButton: UIButton = {
            let btn = UIButton(type: .custom)
            btn.adjustsImageWhenHighlighted = false
            btn.layer.masksToBounds = true
            btn.setTitle(R.string.localizable.amongChatProfileSignIn(), for: .normal)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 20)
            btn.titleLabel?.textAlignment = .center
            btn.setTitleColor(.black, for: .normal)
            btn.layer.cornerRadius = 25
            btn.backgroundColor = "#FFF000".color()
            btn.rx.controlEvent(.primaryActionTriggered)
                .subscribe { _ in
                    _ = AmongChat.Login.canDoLoginEvent(style: .inAppLogin)
                }
                .disposed(by: bag)
            return btn
        }()
                
        private lazy var redCountLabel: UILabel = {
            let lb = WalkieLabel()
            lb.font = R.font.nunitoExtraBold(size: 14)
            lb.textColor = .white
            lb.textAlignment = .center
            return lb
        }()
        
        private(set) lazy var redDotView: UIView = {
            let v = UIView()
            v.addSubview(redCountLabel)
            redCountLabel.snp.makeConstraints { (maker) in
                maker.top.bottom.equalToSuperview()
                maker.leading.trailing.equalToSuperview().inset(6)
            }
            v.backgroundColor = UIColor(hex6: 0xFB5858)
            v.layer.masksToBounds = true
            v.layer.cornerRadius = 10
            v.isHidden = true
            return v
        }()
        
        private var isSelf = true
        private var uid = ""
        private var changedName = false
        private weak var controller: ViewController?
        
        init(with isSelf: Bool, viewController: ViewController) {
            super.init(frame: .zero)
            self.isSelf = isSelf
            self.controller = viewController
            setupLayout()
            setUpEvents()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func configProfile(_ profile: Entity.UserProfile) {
            uid = profile.uid.string
            
            let attName = NSMutableAttributedString(attributedString: profile.nameWithVerified(fontSize: 24, withAge: false))
            
            if let pronounString = profile.pronoun == .pronounNotShare ? nil : profile.pronoun.title {
                attName.yy_appendString(" ")
                attName.append(NSAttributedString(string: pronounString, attributes: [
                    .font : R.font.nunitoBold(size: 16),
                    .foregroundColor : UIColor(hex6: 0xFFFFFF, alpha: 0.6)
                ]))
            }
            
            nameLabel.attributedText = attName
            
            var infoItems = [InfoItem]()
            
            infoItems.append(InfoItem(icon: R.image.ac_profile_id(), text: "\(profile.uid)"))
            
            if let age = profile.age {
                infoItems.append(InfoItem(icon: R.image.ac_profile_birthday(), text: age))
            }
            
            if let cons = profile.constellation?.title {
                infoItems.append(InfoItem(icon: R.image.ac_profile_constellation_24(), text: cons))
            }
            
            if let loc = profile.locale {
                infoItems.append(InfoItem(icon: R.image.ac_profile_geo(), text: loc))
            }
            
            self.infoItems = infoItems
            
            descriptionLabel.wholeString = profile.description
            descriptionLabel.snp.updateConstraints { (maker) in
                maker.height.equalTo(descriptionLabel.textHeight)
            }
            
            avatarIV.updateAvatar(with: profile)
            
            if let pet = profile.decorations.first(where: { $0.decorationType == .pet }) {
                playSvga(pet.lookUrl?.url)
                petView.snp.updateConstraints { (maker) in
                    maker.size.equalTo(petSize)
                }
            } else {
                petView.snp.updateConstraints { (maker) in
                    maker.size.equalTo(CGSize.zero)
                }
            }
            
            headerHandle?(.heightUpdated)
        }
        
        func setProfileData(_ model: Entity.RoomUser) {
            uid = model.uid.string
            nameLabel.text = model.name
            avatarIV.setAvatarImage(with: model.pictureUrl)
        }
        
        func setViewData(_ model: Entity.RelationData, isSelf: Bool) {
            
            let lastCount = Defaults[\.followersCount]
            
            let followersCount = model.followersCount ?? 0
            
            followingBtn.setTitle("\(model.followingCount ?? 0)")
            followerBtn.setTitle("\(followersCount)")
            
            if isSelf {
                Defaults[\.followersCount] = followersCount
                if followersCount > lastCount {
                    redCountLabel.text = "+\(followersCount - lastCount)"
                    redDotView.isHidden = false
                } else {
                    redDotView.isHidden = true
                }
            }
        }
        
        func setLiveStatus(liveRoom: ProfileLiveRoom?) {
            self.liveRoom = liveRoom
        }
        
        private func setupLayout() {
            
            addSubviews(views: bg, avatarIV, petView, nameLabel, infoCollectionView, descriptionLabel, relationContainer, penddingViewContainer)
            
            bg.snp.makeConstraints { (maker) in
                maker.leading.trailing.bottom.equalToSuperview()
                maker.top.equalTo(0)
            }
                        
            avatarIV.snp.makeConstraints { (maker) in
                maker.top.equalToSuperview().offset(avatarTop)
                maker.leading.equalTo(Frame.horizontalBleedWidth)
                maker.size.equalTo(avatarSize)
            }
            
            petView.snp.makeConstraints { (maker) in
                maker.leading.equalTo(avatarIV.snp.trailing).offset(16)
                maker.size.equalTo(petSize)
                maker.bottom.equalTo(avatarIV)
            }
            
            nameLabel.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(Frame.horizontalBleedWidth)
                maker.top.equalTo(avatarIV.snp.bottom).offset(nameLabelTopSpace)
            }
            
            infoCollectionView.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(Frame.horizontalBleedWidth)
                maker.top.equalTo(nameLabel.snp.bottom).offset(infoTopSpace)
                maker.height.equalTo(24)
            }
            
            descriptionLabel.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview().inset(Frame.horizontalBleedWidth)
                maker.top.equalTo(infoCollectionView.snp.bottom).offset(descriptionLabelTopSpace)
                maker.height.equalTo(0)
            }
            
            relationContainer.snp.makeConstraints { maker in
                maker.top.equalTo(descriptionLabel.snp.bottom).offset(relationContainerTopSpace)
                maker.leading.trailing.equalToSuperview().inset(Frame.horizontalBleedWidth)
                maker.height.equalTo(relationContainerHeight)
            }
            
            penddingViewContainer.snp.makeConstraints { (maker) in
                maker.top.equalTo(relationContainer.snp.bottom)
                maker.leading.trailing.equalToSuperview()
            }
            
            if isSelf {
                
                addSubview(changeIcon)
                changeIcon.snp.makeConstraints { (maker) in
                    maker.bottom.equalTo(avatarIV)
                    maker.trailing.equalTo(avatarIV).offset(-4)
                    maker.width.height.equalTo(24)
                }
                
                relationContainer.addSubview(redDotView)
                redDotView.snp.makeConstraints { (make) in
                    make.leading.equalTo(followerBtn.titleLabel.snp.trailing).offset(7)
                    make.centerY.equalTo(followerBtn.titleLabel.snp.centerY).offset(-2)
                    make.height.equalTo(20)
                    make.width.greaterThanOrEqualTo(30)
                }
                                
                addSubview(editBtn)
                editBtn.snp.makeConstraints { (maker) in
                    maker.trailing.equalToSuperview().inset(Frame.horizontalBleedWidth)
                    maker.leading.greaterThanOrEqualTo(petView.snp.trailing).offset(20)
                    maker.bottom.equalTo(avatarIV)
                    maker.height.equalTo(36)
                }
                
                Settings.shared.loginResult.replay()
                    .filterNil()
                    .subscribe(onNext: { [weak self] (p) in
                        
                        guard let `self` = self else { return }
                        
                        if p.isAnonymousUser {
                            self.penddingViewContainer.addSubview(self.loginButton)
                            self.loginButton.snp.makeConstraints { (maker) in
                                maker.leading.trailing.equalToSuperview().inset(Frame.horizontalBleedWidth)
                                maker.top.equalToSuperview().offset(self.loginButtonTopSpace)
                                maker.height.equalTo(self.loginButtonHeight)
                                maker.bottom.equalToSuperview()
                            }
                        } else {
                            self.loginButton.removeFromSuperview()
                        }
                        
                    })
                    .disposed(by: bag)

            } else {
                
                addSubview(onlineStatusView)
                onlineStatusView.snp.makeConstraints { (maker) in
                    maker.trailing.equalToSuperview().inset(Frame.horizontalBleedWidth)
                    maker.leading.greaterThanOrEqualTo(petView.snp.trailing).offset(20)
                    maker.bottom.equalTo(avatarIV)
                    maker.height.equalTo(36)
                }
            }
            
        }
        
        func setUpEvents() {
            infoCollectionView.rx.observe(CGSize.self, "contentSize")
                .filterNil()
                .filter({ $0 != .zero })
                .take(1)
                .subscribe(onNext: { [weak self] (_) in
                    self?.headerHandle?(.heightUpdated)
                })
                .disposed(by: bag)

        }
        
        @objc private func onEditBtn() {
            headerHandle?(.edit)
        }
        
        @objc private func onFollowingBtn() {
            headerHandle?(.following)
        }
        
        @objc private func onFollowerBtn() {
            headerHandle?(.follower)
        }
        
        @objc private func onAvatarTapped() {
            if isSelf {
                headerHandle?(.avater)
            }
        }
        
        private func playSvga(_ resource: URL?) {
            petView.stopAnimation()
            petView.clear()
            guard let resource = resource else {
                return
            }
            
            let parser = SVGAGlobalParser.defaut
            parser.parse(with: resource,
                         completionBlock: { [weak self] (item) in
                            self?.petView.videoItem = item
                            self?.petView.startAnimation()
                         },
                         failureBlock: { error in
                            debugPrint("error: \(error?.localizedDescription ?? "")")
                         })
        }
        
        func enlargeTopGbHeight(extraHeight: CGFloat) {
            
            guard extraHeight >= 0 else {
                return
            }
            
            bg.snp.updateConstraints { (maker) in
                maker.top.equalTo(-extraHeight)
            }
            
        }
    }
    
    class VerticalTitleButton: UIView {
        
        static var height: CGFloat = 51
        
        private(set) lazy var titleLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 22)
            lb.textColor = .white
            lb.adjustsFontSizeToFitWidth = true
            return lb
        }()
        
        private(set) lazy var subtitleLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoBold(size: 16)
            lb.textColor = UIColor(hex6: 0xFFFFFF, alpha: 0.6)
            return lb
        }()
        
        init() {
            super.init(frame: .zero)
            addSubviews(views: titleLabel, subtitleLabel)
            titleLabel.snp.makeConstraints { (maker) in
                maker.leading.top.equalToSuperview()
                maker.trailing.equalToSuperview()
                maker.height.equalTo(30)
            }
            
            subtitleLabel.snp.makeConstraints { (maker) in
                maker.leading.bottom.equalToSuperview()
                maker.trailing.equalToSuperview()
                maker.height.equalTo(21)
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func setTitle(_ title: String) {
            titleLabel.text = title
        }
        
        func setSubtitle(_ subtitle: String) {
            subtitleLabel.text = subtitle
        }
    }
    
}

extension Social.ProfileViewController.ProfileView: UICollectionViewDataSource {
    
    // MARK: - UICollectionView Data Source
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return infoItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(InfoCell.self), for: indexPath)
        
        if let cell = cell as? InfoCell,
           let item = infoItems.safe(indexPath.item) {
            cell.icon.image = item.icon
            cell.label.text = item.text
        }
        
        return cell
    }
    
}

extension Social.ProfileViewController.ProfileView: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        guard let info = infoItems.safe(indexPath.item) else {
            return .zero
        }
        
        return InfoCell.viewSize(for: info.text)
    }
    
}

extension Social.ProfileViewController.ProfileView {
    
    class InfoCell: UICollectionViewCell {
        
        private static let font = R.font.nunitoBold(size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .bold)
        private static let iconSize = CGSize(width: 24, height: 24)
        private static let labelLeadingSpace: CGFloat = 2
        
        class func viewSize(for text: String) -> CGSize {
            let width = text.width(withConstrainedHeight: iconSize.height, font: font) + iconSize.width + labelLeadingSpace
            return CGSize(width: width, height: iconSize.height)
        }
        
        private(set) lazy var icon: UIImageView = {
            let i = UIImageView()
            return i
        }()
        
        private(set) lazy var label: UILabel = {
            let l = UILabel()
            l.font = Self.font
            l.textColor = UIColor.white.withAlphaComponent(0.6)
            return l
        }()
        
        override init(frame: CGRect) {
            super.init(frame: .zero)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupLayout() {
            contentView.backgroundColor = .clear
            
            contentView.addSubviews(views: icon, label)
            
            icon.snp.makeConstraints { (maker) in
                maker.leading.top.bottom.equalToSuperview()
                maker.size.equalTo(Self.iconSize)
            }
            
            label.snp.makeConstraints { (maker) in
                maker.leading.equalTo(icon.snp.trailing).offset(Self.labelLeadingSpace)
                maker.centerY.trailing.equalToSuperview()
            }
        }
        
    }
    
    
}

extension Social.ProfileViewController.ProfileView {
    
    private struct InfoItem {
        let icon: UIImage?
        let text: String
    }
    
}

extension Social.ProfileViewController.ProfileView {
    
    class OnlineStatusView: UIView {
        
        private lazy var icon: UIImageView = {
            let i = UIImageView(image: R.image.online())
            return i
        }()
        
        private lazy var label: UILabel = {
            let l = UILabel()
            l.font = R.font.nunitoBold(size: 16)
            l.textColor = UIColor(hex6: 0xFFFFFF)
            l.text = R.string.localizable.socialStatusOnline()
            return l
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setUpLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            layer.cornerRadius = bounds.height / 2
        }
        
        private func setUpLayout() {
            
            backgroundColor = UIColor(hex6: 0xFFFFFF, alpha: 0.12)
            clipsToBounds = true
            
            addSubviews(views: icon, label)
            icon.snp.makeConstraints { (maker) in
                maker.width.height.equalTo(16)
                maker.leading.equalToSuperview().offset(13.5)
                maker.centerY.equalToSuperview()
            }
            
            label.snp.makeConstraints { (maker) in
                maker.leading.equalTo(icon.snp.trailing).offset(4)
                maker.trailing.equalToSuperview().offset(-13)
                maker.centerY.equalToSuperview()
            }
        }
    }
    
}
