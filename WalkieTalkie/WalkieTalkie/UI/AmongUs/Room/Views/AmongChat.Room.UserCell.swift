//
//  AmongChat.Room.UserCell.swift
//  WalkieTalkie
//
//  Created by mayue_work on 2020/11/27.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import RxSwift
import Kingfisher
import SVGAPlayer
import EasyTipView
import SwiftyUserDefaults

class SVGAGlobalParser: SVGAParser {
    static let defaut = SVGAGlobalParser()
    
    override init() {
        super.init()
        self.enabledMemoryCache = true
    }
}

typealias AmongRoomUserCell = AmongChat.Room.UserCell

extension AmongChat.Room {
    
    class UserCell: UICollectionViewCell {
        
        private static let haloViewAnimationKey = "halo_animation"
        
        enum SvagPlayerStatus {
            case free
            //动画
            case playingEmoji
            //justchatting emoji 游戏
            case playingEmojiGame
        }
        
        private lazy var indexLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 16)
            lb.textColor = .white
            lb.textAlignment = .center
            return lb
        }()
        
        private lazy var haloView = SoundAnimationView(frame: .zero)
        
        private lazy var avatarIV: UIButton = {
            let btn = UIButton(type: .custom)
            btn.layer.cornerRadius = 20
            btn.layer.masksToBounds = true
//            btn.layer.borderWidth = 0.5
            btn.imageView?.contentMode = .scaleAspectFill
//            btn.layer.borderColor = UIColor.white.alpha(0.8).cgColor
            btn.backgroundColor = UIColor.white.alpha(0.2)
            btn.addTarget(self, action: #selector(userIconButtonAction), for: .touchUpInside)
            return btn
        }()
        
        private lazy var kickSelectedView: UIImageView = {
            let iv = UIImageView()
            iv.layer.cornerRadius = 20
            iv.layer.masksToBounds = true
            iv.image = R.image.ac_kick_selected()
            iv.isHidden = true
            iv.contentMode = .center
//            iv.layer.borderWidth = 0.5
//            iv.layer.borderColor = UIColor.white.alpha(0.8).cgColor
            iv.backgroundColor = "D30F0F".color().alpha(0.62)
            return iv
        }()
        
        private lazy var disableMicView: UIImageView = {
            let iv = UIImageView()
            iv.image = R.image.ac_icon_room_disable_mic()
            iv.isHidden = true
            return iv
        }()
        
        private lazy var mutedLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 10)
            lb.textColor = "FB5858".color()
            lb.textAlignment = .center
            lb.text = R.string.localizable.roomUserListMuted()
            lb.backgroundColor = UIColor.black.alpha(0.7)
            lb.isHidden = true
            lb.cornerRadius = 20
            return lb
        }()
        
        private lazy var nameLabel: UILabel = {
            let lb = UILabel()
            lb.font = R.font.nunitoExtraBold(size: 12)
            lb.textColor = .white
            lb.textAlignment = .center
            lb.lineBreakMode = .byTruncatingMiddle
            return lb
        }()
        
        private lazy var gameNameButton: UIButton = {
            let btn = UIButton(type: .custom)
            //            btn.setTitle("XXX", for: .normal)
            btn.titleLabel?.font = R.font.nunitoExtraBold(size: 10)
            btn.titleLabel?.lineBreakMode = .byTruncatingTail
            btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
            btn.backgroundColor = UIColor.white.alpha(0.2)
            btn.cornerRadius = 10
            btn.addTarget(self, action: #selector(gameNameButtonAction), for: .touchUpInside)
            return btn
        }()
        
        private lazy var svgaView: SVGAPlayer = {
            let player = SVGAPlayer(frame: .zero)
            player.clearsAfterStop = true
            player.delegate = self
            player.loops = 1
            player.contentMode = .scaleAspectFill
            player.isUserInteractionEnabled = false
            return player
        }()
        
        lazy var loadingView: SeatLoadingView = {
            let view = SeatLoadingView(frame: .zero)
            return view
        }()

        
        private var svgaUrl: URL?
        //        private var isPlaySvgaEmoji: Bool = false
        private var svagPlayerStatus: SvagPlayerStatus = .free
        //
        private var emojiContent: ChatRoom.EmojiMessage?
        private var emojiPlayEndHandler: (ChatRoom.EmojiMessage?) -> Void = { _ in }
        //
        private var tipView: EasyTipView?
        private let bag = DisposeBag()
        
        var emojisNames: [String] = []
        var topic: AmongChat.Topic?
        var user: Entity.RoomUser?
        
        enum Action {
            case editGameName
        }
        
        var clickAvatarHandler: ((Entity.RoomUser?) -> Void)?
        var actionHandler: ((Action) -> Void)?
        
        var isKickSelected: Bool = false {
            didSet {
                kickSelectedView.isHidden = !isKickSelected
            }
        }
        let itemStyle: AmongChat.Room.SeatView.ItemStyle
        
        init(itemStyle: AmongChat.Room.SeatView.ItemStyle) {
            self.itemStyle = itemStyle
            super.init(frame: .zero)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            self.itemStyle = .normal
            super.init(coder: coder)
            setupLayout()
        }
        
//        @objc
//        func longPressGestureAction() {
//            guard let user = user else {
//                return
//            }
//            avatarLongPressHandler?(user)
//        }
        
        override func prepareForReuse() {
            super.prepareForReuse()
//            avatarIV.kf.cancelImageDownloadTask()
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
        }
        
        func startSoundAnimation() {
            guard user?.isMuted == false else {
                return
            }
            haloView.startLoading()
            if let url = svgaUrl {
                playSvga(url)
            } else {
                playSvga(emojisNames.randomItem())
            }
        }
        
        func stopSoundAnimation() {
//            isPlaySvgaEmoji = false
            
            haloView.stopLoading()
            if svagPlayerStatus == .playingEmoji {
                svgaView.stopAnimation()
                svgaView.clear()
                svagPlayerStatus = .free
            }
        }
        
        func play(_ emoji: ChatRoom.EmojiMessage, completionHandler: @escaping (ChatRoom.EmojiMessage?) -> Void) {
            if !emoji.resource.isEmpty,
                emoji.resource.hasSuffix("svga"),
                let resource = URL(string: emoji.resource) {
                emojiContent = emoji
                
                emojiPlayEndHandler = completionHandler
                svagPlayerStatus = .playingEmojiGame
                
                let parser = SVGAGlobalParser.defaut
                parser.parse(with: resource,
                             completionBlock: { [weak self] (item) in
                                self?.svgaView.clearsAfterStop = false
                                self?.svgaView.videoItem = item
                                self?.svgaView.startAnimation()
                            },
                             failureBlock: { [weak self] error in
                                debugPrint("error: \(error?.localizedDescription ?? "")")
                                self?.svagPlayerStatus = .free
                                completionHandler(emoji)
                            })
            } else {
                completionHandler(emoji)
                svgaView.clear()
            }
        }
        
        private func playSvga(_ resource: URL?) {
            guard let resource = resource else {
                return
            }
            //如果正在播放，则不用再次播放
            guard svagPlayerStatus == .free else {
                return
            }
            let parser = SVGAGlobalParser.defaut
            parser.parse(with: resource,
                         completionBlock: { [weak self] (item) in
//                            self?.isPlaySvgaEmoji = true
                            self?.svgaView.clearsAfterStop = true
                            self?.svagPlayerStatus = .playingEmoji
                            self?.svgaView.videoItem = item
                            self?.svgaView.startAnimation()
                         },
                         failureBlock: { [weak self] error in
                            self?.svagPlayerStatus = .free
                            debugPrint("error: \(error?.localizedDescription ?? "")")
                         })
        }
        
        func playSvga(_ name: String? = nil) {
            guard let name = name else {
                return
            }
            //如果正在播放，则不用再次播放
            guard svagPlayerStatus == .free else {
                return
            }
            let parser = SVGAGlobalParser.defaut
            parser.parse(withNamed: name, in: nil,
                         completionBlock: { [weak self] (item) in
//                            self?.isPlaySvgaEmoji = true
                            self?.svgaView.clearsAfterStop = true
                            self?.svagPlayerStatus = .playingEmoji
                            self?.svgaView.videoItem = item
                            self?.svgaView.startAnimation()
                         },
                         failureBlock: { [weak self] error in
                            self?.svagPlayerStatus = .free
                            debugPrint("error: \(error.localizedDescription ?? "")")
                         })
        }
        
        /// loading动画
        func startLoading() {
            loadingView.startLoading()
        }
        
        func stopLoading() {
            loadingView.stopLoading()
        }
        
        func showGameNameTipsIfNeed() {
            guard let topic = topic,
                  user?.uid == Settings.loginUserId,
                  Defaults[key: DefaultsKeys.groupRoomCanShowGameNameTips(for: topic)],
                  let tips = topic.groupGameNamePlaceholderTips else {
                return
            }
            Defaults[key: DefaultsKeys.groupRoomCanShowGameNameTips(for: topic)] = false
            var preferences = EasyTipView.Preferences()
            preferences.drawing.font = R.font.nunitoExtraBold(size: 16) ?? UIFont.boldSystemFont(ofSize: 16)
            preferences.drawing.foregroundColor = .black
            preferences.drawing.backgroundColor = .white
            preferences.drawing.arrowPosition = .top
            
            tipView = EasyTipView(text: tips,
                                  preferences: preferences,
                                  delegate: self)
            tipView?.tag = 0
            tipView?.show(animated: true, forView: gameNameButton, withinSuperview: containingController?.view)
            Observable<Int>
                .interval(.seconds(5), scheduler: MainScheduler.instance)
                .single()
                .subscribe(onNext: { [weak welf = self] _ in
                    guard let `self` = welf else { return }
                    self.tipView?.dismiss()
                })
                .disposed(by: self.bag)
        }
        
        
        @objc
        func userIconButtonAction() {
            clickAvatarHandler?(user)
        }
        
        @objc
        func gameNameButtonAction() {
            //
            if itemStyle == .group, user?.uid == Settings.loginUserId {
                //edit
                actionHandler?(.editGameName)
                return
            }
            user?.nickname?.copyToPasteboardWithHaptic()                
        }
        
        private func bindSubviewEvent() {
            Settings.shared.amongChatUserProfile.replay()
                .observeOn(MainScheduler.asyncInstance)
                .subscribe(onNext: { [weak self] profile in
                    self?.updateGameNameTitle()
                })
                .disposed(by: bag)
            
        }
        
        private func updateGameNameTitle() {
            guard let user = user,
                  user.uid == Settings.loginUserId,
                  let topic = topic,
                  let profile = Settings.shared.amongChatUserProfile.value else {
                return
            }
            //
            guard let name = profile.hostNickname(for: topic),
                  !name.isEmpty else {
                gameNameButton.setTitle(topic.groupGameNamePlaceholder, for: .normal)
                return
            }
            gameNameButton.setTitle(name, for: .normal)

        }
        
        private func setupLayout() {
            contentView.backgroundColor = .clear
            contentView.addSubviews(views: gameNameButton, haloView, avatarIV, nameLabel, disableMicView, svgaView, mutedLabel, kickSelectedView, loadingView)
            
            if itemStyle == .normal {
                contentView.addSubviews(views: indexLabel)
                indexLabel.snp.makeConstraints { (maker) in
                    maker.left.right.top.equalToSuperview()
                    maker.height.equalTo(21.5)
                }
                avatarIV.snp.makeConstraints { (maker) in
                    maker.size.equalTo(CGSize(width: 40, height: 40))
                    maker.centerX.equalToSuperview()
                    maker.top.equalTo(indexLabel.snp.bottom).offset(4)
                }
            } else {
                avatarIV.snp.makeConstraints { (maker) in
                    maker.size.equalTo(CGSize(width: 40, height: 40))
                    maker.centerX.top.equalToSuperview()
                }
            }
            
            haloView.snp.makeConstraints { (maker) in
                maker.center.equalTo(avatarIV)
                maker.width.height.equalTo(60)
            }
            
            
            svgaView.snp.makeConstraints { make in
                make.center.equalTo(avatarIV)
                make.width.height.equalTo(avatarIV)
            }
            
            kickSelectedView.snp.makeConstraints { (maker) in
                maker.center.equalTo(avatarIV)
                maker.width.height.equalTo(40)
            }
            
            disableMicView.snp.makeConstraints { (maker) in
                maker.right.bottom.equalTo(avatarIV)
            }
            
            mutedLabel.snp.makeConstraints { (maker) in
                maker.center.equalTo(avatarIV)
                maker.width.height.equalTo(avatarIV)
            }
            
            nameLabel.snp.makeConstraints { (maker) in
                maker.top.equalTo(avatarIV.snp.bottom).offset(4)
                maker.trailing.leading.equalToSuperview().inset(2)
            }
            
            gameNameButton.snp.makeConstraints { maker in
                maker.top.equalTo(nameLabel.snp.bottom).offset(4)
                maker.left.equalTo(3)
                maker.right.equalTo(-3)
                maker.height.equalTo(20)
            }
            
            loadingView.snp.makeConstraints { make in
                make.center.equalTo(avatarIV)
                make.width.equalTo(32)
                make.height.equalTo(16)
            }
        }
    }
}

extension AmongChat.Room.UserCell: SVGAPlayerDelegate {
    func svgaPlayerDidFinishedAnimation(_ player: SVGAPlayer!) {
//        isPlaySvgaEmoji = false
        switch svagPlayerStatus {
        case .playingEmojiGame:
//            svagPlayerStatus = .playingEmojiGame
            if let emoji = emojiContent, let hideDelaySec = emoji.hideDelaySec, hideDelaySec > 0 {
                mainQueueDispatchAsync(after: Double(hideDelaySec)) { [weak self] in
                    player.clear()
                    player.videoItem = nil
                    self?.emojiPlayEndHandler(self?.emojiContent)
                    self?.svagPlayerStatus = .free
                }
            } else {
                player.clear()
                player.videoItem = nil
                emojiPlayEndHandler(emojiContent)
                svagPlayerStatus = .free
            }
            emojiContent = nil
        default:
            svagPlayerStatus = .free
        }
    }
}

extension AmongChat.Room.UserCell {
    
    func bind(_ user: Entity.RoomUser?, topic: AmongChat.Topic, index: Int) {
        self.topic = topic
        
        if index == 1 {
            indexLabel.text = "\(index)-Host"
        } else {
            indexLabel.text = index.string
        }
        if Settings.loginUserId == user?.uid {
            indexLabel.textColor = "#FFF000".color()
        } else {
            indexLabel.textColor = .white
        }        
        nameLabel.textColor = indexLabel.textColor
        
        guard let user = user else {
            clearStyle()
            return
        }
        
        if let urlString = Entity.DecorationEntity.entityOf(id: user.decoPetId)?.sayUrl,
           let url = URL(string: urlString) {
            //svga
            svgaUrl = url
        } else {
            svgaUrl = nil
        }
        
        if user.status == .talking {
            startSoundAnimation()
        } else if user.status == .muted {
            stopSoundAnimation()
        }
        if self.user?.uid != user.uid {
            avatarIV.imageView?.contentMode = .scaleAspectFill
            avatarIV.setImage(with: user.pictureUrl, for: .normal, placeholder: R.image.ac_profile_avatar())
            avatarIV.layer.borderWidth = 0.5
            nameLabel.attributedText = user.nameWithVerified(fontSize: 12)
        }
        //
        if itemStyle == .normal {
            gameNameButton.isHidden = !(topic.enableNickName && user.nickname.isValid)
            gameNameButton.setTitle(user.nickname, for: .normal)
        } else {
            if user.uid == Settings.loginUserId {
                gameNameButton.isHidden = !topic.enableNickName
                if user.nickname.isValid {
                    gameNameButton.setTitle(user.nickname, for: .normal)
                } else {
                    gameNameButton.setTitle(topic.groupGameNamePlaceholder, for: .normal)
                    showGameNameTipsIfNeed()
                }
            } else {
                gameNameButton.isHidden = !(topic.enableNickName && user.nickname.isValid)
            }
        }
        if isKickSelected {
            mutedLabel.isHidden = true
            disableMicView.isHidden = true
        } else {
            if user.isMutedByLoginUser == true {
                mutedLabel.isHidden = false
                disableMicView.isHidden = true
            } else {
                mutedLabel.isHidden = true
                disableMicView.isHidden = !user.isMuted
            }
        }
        self.user = user
    }
    
    func clearStyle() {
        user = nil
        svgaUrl = nil
        stopSoundAnimation()
        avatarIV.kf.cancelImageDownloadTask()
        avatarIV.setImage(R.image.ac_icon_seat_add(), for: .normal)
        avatarIV.imageView?.contentMode = .center
        avatarIV.layer.borderWidth = 0
        haloView.isHidden = true
        nameLabel.text = ""
        gameNameButton.setTitle(nil, for: .normal)
        gameNameButton.isHidden = true
        mutedLabel.isHidden = true
        disableMicView.isHidden = true
    }
    
}


extension AmongChat.Room.UserCell: EasyTipViewDelegate {
    func easyTipViewDidTap(_ tipView: EasyTipView) {
//        dismissTipView()
        self.tipView?.dismiss()
    }
    
    func easyTipViewDidDismiss(_ tipView : EasyTipView) {
        
    }
}
