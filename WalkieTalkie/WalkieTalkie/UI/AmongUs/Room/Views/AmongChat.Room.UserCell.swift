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

class SVGAGlobalParser: SVGAParser {
    static let defaut = SVGAGlobalParser()
    
    override init() {
        super.init()
        self.enabledMemoryCache = true
    }
}

extension AmongChat.Room {
    
    class UserCell: UICollectionViewCell {
        
        private static let haloViewAnimationKey = "halo_animation"
        
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
            btn.layer.borderWidth = 0.5
            btn.imageView?.contentMode = .scaleAspectFill
            btn.layer.borderColor = UIColor.white.alpha(0.8).cgColor
            btn.backgroundColor = UIColor.white.alpha(0.2)
            btn.addTarget(self, action: #selector(userIconButtonAction), for: .touchUpInside)
            return btn
        }()
        
//        private lazy var avatarIV: UIImageView = {
//            let iv = UIImageView()
//            iv.layer.cornerRadius = 20
//            iv.layer.masksToBounds = true
//            iv.layer.borderWidth = 0.5
//            iv.contentMode = .scaleAspectFill
//            iv.layer.borderColor = UIColor.white.alpha(0.8).cgColor
//            iv.backgroundColor = UIColor.white.alpha(0.2)
//            iv.isUserInteractionEnabled = true
////            let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressGestureAction))
////            longPressGesture.minimumPressDuration = 0.5
////            iv.addGestureRecognizer(longPressGesture)
//            return iv
//        }()
        
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
        
        lazy var svgaView: SVGAPlayer = {
            let player = SVGAPlayer(frame: .zero)
            player.clearsAfterStop = true
            player.delegate = self
            player.loops = 1
            player.contentMode = .scaleAspectFill
            player.isUserInteractionEnabled = false
            return player
        }()
        
        var emojis: [URL] = []
        
        private var user: Entity.RoomUser?
        private var svgaUrl: URL?
        private var isPlaySvgaEmoji: Bool = false

        var clickAvatarHandler: ((Entity.RoomUser?) -> Void)?
        
        var isKickSelected: Bool = false {
            didSet {
                kickSelectedView.isHidden = !isKickSelected
            }
        }
        
        override init(frame: CGRect) {
            super.init(frame: .zero)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
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
                playSvga(emojis.randomItem())
            }
        }
        
        func stopSoundAnimation() {
            isPlaySvgaEmoji = false
            haloView.stopLoading()
            svgaView.stopAnimation()
        }
        
        func playSvga(_ resource: URL?) {
            guard let resource = resource else {
                return
            }
            //如果正在播放，则不用再次播放
            guard !isPlaySvgaEmoji else  {
                return
            }
            let parser = SVGAGlobalParser.defaut
            parser.parse(with: resource,
                         completionBlock: { [weak self] (item) in
                            self?.isPlaySvgaEmoji = true
                            self?.svgaView.videoItem = item
                            self?.svgaView.startAnimation()
                         },
                         failureBlock: { error in
                            debugPrint("error: \(error?.localizedDescription ?? "")")
                         })
        }
        
        @objc
        func userIconButtonAction() {
            clickAvatarHandler?(user)
        }
        
        @objc
        func gameNameButtonAction() {
            user?.nickname?.copyToPasteboardWithHaptic()
            containingController?.view.raft.autoShow(.text(R.string.localizable.copied()), userInteractionEnabled: false)
        }
        
        private func setupLayout() {
            contentView.backgroundColor = .clear
            contentView.addSubviews(views: indexLabel, gameNameButton, haloView, avatarIV, svgaView, nameLabel, disableMicView, mutedLabel, kickSelectedView)
            
            indexLabel.snp.makeConstraints { (maker) in
                maker.left.right.top.equalToSuperview()
                maker.height.equalTo(21.5)
            }
            
            //            haloView.soundWidth = 60
            haloView.snp.makeConstraints { (maker) in
                maker.center.equalTo(avatarIV)
                maker.width.height.equalTo(60)
            }
            
            avatarIV.snp.makeConstraints { (maker) in
                maker.size.equalTo(CGSize(width: 40, height: 40))
                maker.centerX.equalToSuperview()
                maker.top.equalTo(indexLabel.snp.bottom).offset(4)
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
//                maker.left.right.equalToSuperview()
                maker.trailing.leading.equalToSuperview().inset(2)
                //                maker.bottom.equalTo(gameNameButton.snp.top)
            }
            
            gameNameButton.snp.makeConstraints { maker in
                maker.top.equalTo(nameLabel.snp.bottom).offset(4)
                maker.left.equalTo(3)
                maker.right.equalTo(-3)
                maker.height.equalTo(20)
            }
        }
    }
}

extension AmongChat.Room.UserCell: SVGAPlayerDelegate {
    func svgaPlayerDidFinishedAnimation(_ player: SVGAPlayer!) {
        isPlaySvgaEmoji = false
    }
}

extension AmongChat.Room.UserCell {
    
    func bind(_ user: Entity.RoomUser?, topic: AmongChat.Topic, index: Int) {
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
        gameNameButton.setTitle(user.nickname, for: .normal)
        gameNameButton.isHidden = !(topic.enableNickName && user.nickname.isValid)
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
