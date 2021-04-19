//
//  AmongGroupHostView.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 30/03/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit
import EasyTipView
import RxSwift
import RxCocoa
import SwiftyUserDefaults
import SVGAPlayer

class AmongGroupHostView: XibLoadableView {
    
    enum Action {
        case joinHost
        case joinGroup
        case editNickName
        case userProfileSheetAction(AmongSheetController.ItemType, _ user: Entity.RoomUser)
    }
    
    @IBOutlet weak var hostView: UIView!
//    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var raiseHandsContainer: UIView!
    @IBOutlet weak var raiseButton: UIImageView!
    @IBOutlet weak var applyGroupContainer: UIView!
    @IBOutlet weak var applyGroupButton: UIImageView!
    @IBOutlet weak var hostAvatarView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var gameNameButton: UIButton!
    @IBOutlet weak var indexLabel: UILabel!
    
    private lazy var disableMicView: UIImageView = {
        let iv = UIImageView()
        iv.image = R.image.ac_icon_room_disable_mic()
        iv.isHidden = true
        return iv
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
    
    private var svgaUrl: URL?
    private var svagPlayerStatus: AmongChat.Room.UserCell.SvagPlayerStatus = .free
    private lazy var haloView = SoundAnimationView(frame: .zero)
    private let bag = DisposeBag()
    
    var emojisNames: [String] = []
    
    private var onSeatBadge: BadgeHub?
    private var applyGroupBadge: BadgeHub?
    private var tipView: EasyTipView?
    private weak var tipBgView: UIView?
//    private let bag = DisposeBag()
//    private var isShowTips: Bool
    
    var actionHandler: ((Action) -> Void)?
    
    var group: Entity.Group {
        didSet {
            hostAvatarView.setImage(with: group.broadcaster.pictureUrl)
            nameLabel.attributedText = group.broadcaster.nameWithVerified(fontSize: 12, withAge: false)
            emojisNames = group.topicType.roomEmojiNames
            
            if let urlString = Entity.DecorationEntity.entityOf(id: group.broadcaster.decoPetId ?? 0)?.sayUrl,
               let url = URL(string: urlString) {
                //svga
                svgaUrl = url
            } else {
                svgaUrl = nil
            }
            
            if Settings.loginUserId == group.broadcaster.uid {
                nameLabel.textColor = "#FFF000".color()
            } else {
                nameLabel.textColor = .white
            }
            applyGroupContainer.isHidden = !group.loginUserIsAdmin
            raiseHandsContainer.isHidden = applyGroupContainer.isHidden
            indexLabel.textColor = nameLabel.textColor
//            gameNameButton.setTitleColor(nameLabel.textColor, for: .normal)
            
            gameNameButton.isHidden = !group.topicType.enableNickName

            if group.topicType.enableNickName {
                if group.hostNickname.isValid {
                    gameNameButton.setTitle(group.hostNickname, for: .normal)
                } else {
                    if group.loginUserIsAdmin {
                    //set nick name
                    gameNameButton.setTitle(group.topicType.groupGameNamePlaceholder, for: .normal)
                    //show
                        mainQueueDispatchAsync(after: 0.2) { [weak self] in
                            self?.showGameNameTipsIfNeed()
                        }
                    } else {
                        gameNameButton.isHidden = true
                    }
                }
                updateGameNameTitle()
            }
        
        }
    }
    
    var hostProfile: Entity.RoomUser? {
        didSet {
            if hostProfile?.isMutedByLoginUser == true {
                mutedLabel.isHidden = false
                disableMicView.isHidden = true
            } else {
                mutedLabel.isHidden = true
                disableMicView.isHidden = !(hostProfile?.isMuted ?? false)
            }
        }

    }
    
    let viewModel: AmongChat.BaseRoomViewModel

    init(group: Entity.Group, viewModel: AmongChat.BaseRoomViewModel) {
        self.viewModel = viewModel
        self.group = group
        super.init(frame: .zero)
        configureSubview()
        bindSubviewEvent()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func fetchRealation(with user: Entity.RoomUser) {
        let removeBlock = parentViewController?.view.raft.show(.loading)
        Request.relationData(uid: user.uid).asObservable()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] relation in
                removeBlock?()
                guard let `self` = self,
                      let data = relation else { return }
                self.showAvatarSheet(with: user, relation: data)
            }, onError: { error in
                removeBlock?()
                cdPrint("relationData error :\(error.localizedDescription)")
            })
            .disposed(by: bag)
    }
    
    func showAvatarSheet(with user: Entity.RoomUser, relation: Entity.RelationData) {
        guard let viewController = containingController else {
            return
        }
        var items: [AmongSheetController.ItemType] = [.userInfo, .profile]

        let isFollowed = relation.isFollowed ?? false
        if !isFollowed {
            items.append(.follow)
        }
        //
        if group.loginUserIsAdmin == true {
            items.append(.drop)
        }
        let isBlocked = relation.isBlocked ?? false
        let blockItem: AmongSheetController.ItemType = isBlocked ? .unblock : .block
        
        let muteItem: AmongSheetController.ItemType = viewModel.mutedUser.contains(user.uid.uInt) ? .unmute : .mute
//        if viewModel.roomReplay.value.userList.first?.uid == Settings.loginUserId {
//            items.append(.kick)
//        }
        
        items.append(contentsOf: [blockItem, muteItem, .report, .cancel])

        AmongSheetController.show(with: user, items: items, in: viewController) { [weak self] item in
//            Logger.Action.log(.room_user_profile_clk, categoryValue: self?.room.topicId, item.rawValue)
            self?.actionHandler?(.userProfileSheetAction(item, user))
        }
    }
    
    func showGameNameTipsIfNeed() {
        guard group.loginUserIsAdmin,
              Defaults[key: DefaultsKeys.groupRoomCanShowGameNameTips(for: group.topicType)],
              let tips = group.topicType.groupGameNamePlaceholderTips else {
            return
        }
        Defaults[key: DefaultsKeys.groupRoomCanShowGameNameTips(for: group.topicType)] = false
        var preferences = EasyTipView.Preferences()
        preferences.drawing.font = R.font.nunitoExtraBold(size: 16) ?? UIFont.boldSystemFont(ofSize: 16)
        preferences.drawing.foregroundColor = .black
        preferences.drawing.backgroundColor = .white
        preferences.drawing.arrowPosition = .top
        
        
        let tipView = EasyTipView(text: tips,
                              preferences: preferences,
                              delegate: self)
        
        let bgView = UIView(frame: Frame.Screen.bounds)
        bgView.rx.tapGesture()
            .subscribe(onNext: { [weak self] gesture in
                self?.dismissTipView()
            })
            .disposed(by: bag)
        self.tipBgView = bgView
        containingController?.view.addSubview(bgView)
        
        self.tipView = tipView
        tipView.tag = 0
        tipView.show(animated: true, forView: gameNameButton, withinSuperview: containingController?.view)
        Observable<Int>
            .interval(.seconds(5), scheduler: MainScheduler.instance)
            .single()
            .subscribe(onNext: { [weak welf = self] _ in
                guard let `self` = welf else { return }
                self.dismissTipView()
            })
            .disposed(by: self.bag)
    }

    func updateOnSeatBadge(with count: Int) {
        if onSeatBadge == nil {
            onSeatBadge = BadgeHub(view: raiseButton) // Initially count set to 0
            onSeatBadge?.setCircleColor(UIColor(hex: 0xFB5858), label: .white)
            onSeatBadge?.scaleCircleSize(by: 0.4)
            onSeatBadge?.setCircleAtFrame(CGRect(x: raiseButton.bounds.width-1, y: -8, width: 16, height: 16))
            onSeatBadge?.setCountLabel(R.font.nunitoExtraBold(size: 12))
        }
        onSeatBadge?.setCount(count)
    }
    
    func updateApplyGroupBadge(with count: Int) {
        if applyGroupBadge == nil {
            applyGroupBadge = BadgeHub(view: applyGroupButton) // Initially count set to 0
            applyGroupBadge?.setCircleColor(UIColor(hex: 0xFB5858), label: .white)
            applyGroupBadge?.scaleCircleSize(by: 0.4)
            applyGroupBadge?.setCircleAtFrame(CGRect(x: applyGroupButton.bounds.width - 1, y: -8, width: 16, height: 16))
            applyGroupBadge?.setCountLabel(R.font.nunitoExtraBold(size: 12))
        }
        applyGroupBadge?.setCount(count)
    }
    
    func startSoundAnimation() {
        guard hostProfile?.isMuted == false else {
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
    
    @objc func dismissTipView() {
        tipBgView?.removeFromSuperview()
        tipView?.dismiss()
        tipView = nil
    }
    
    @IBAction func raisedHandsAction(_ sender: Any) {
        actionHandler?(.joinHost)
    }
    
    @IBAction func joinReuqestAction(_ sender: Any) {
        actionHandler?(.joinGroup)
    }
    
    @IBAction func hostAvatarAction(_ sender: Any) {
        guard let user = hostProfile,
              group.uid != Settings.loginUserId else {
            return
        }
        fetchRealation(with: user)
    }
    
    @IBAction func gameNameAction(_ sender: Any) {
        if group.loginUserIsAdmin {
            actionHandler?(.editNickName)
        } else if let nickName = group.broadcaster.hostNickname(for: group.topicType) {
            nickName.copyToPasteboardWithHaptic()
        }
    }
    
    private func bindSubviewEvent() {
        Settings.shared.amongChatUserProfile.replay()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] profile in
                self?.updateGameNameTitle()
            })
            .disposed(by: bag)
    }
    
    private func configureSubview() {
        insertSubview(haloView, at: 0)
        
        addSubviews(views: disableMicView, svgaView, mutedLabel)
        haloView.snp.makeConstraints { (maker) in
            maker.center.equalTo(hostAvatarView)
            maker.width.height.equalTo(60)
        }
        
        svgaView.snp.makeConstraints { make in
            make.center.equalTo(hostAvatarView)
            make.width.height.equalTo(hostAvatarView)
        }
        
        disableMicView.snp.makeConstraints { (maker) in
            maker.right.bottom.equalTo(hostAvatarView)
        }
        
        mutedLabel.snp.makeConstraints { (maker) in
            maker.center.equalTo(hostAvatarView)
            maker.width.height.equalTo(hostAvatarView)
        }
        
        gameNameButton.titleLabel?.lineBreakMode = .byTruncatingTail
    }
    
    private func updateGameNameTitle() {
        guard group.loginUserIsAdmin,
              let profile = Settings.shared.amongChatUserProfile.value else {
            return
        }
        //
        guard let name = profile.hostNickname(for: group.topicType),
              !name.isEmpty else {
            gameNameButton.setTitle(group.topicType.groupGameNamePlaceholder, for: .normal)
            return
        }
        gameNameButton.setTitle(name, for: .normal)

    }
    
}

extension AmongGroupHostView: EasyTipViewDelegate {
    func easyTipViewDidTap(_ tipView: EasyTipView) {
        dismissTipView()
    }
    
    func easyTipViewDidDismiss(_ tipView : EasyTipView) {
        
    }
}

extension AmongGroupHostView: SVGAPlayerDelegate {
    func svgaPlayerDidFinishedAnimation(_ player: SVGAPlayer!) {
//        isPlaySvgaEmoji = false
//        switch svagPlayerStatus {
//        case .playingEmojiGame:
////            svagPlayerStatus = .playingEmojiGame
//            if let emoji = emojiContent, let hideDelaySec = emoji.hideDelaySec, hideDelaySec > 0 {
//                mainQueueDispatchAsync(after: Double(hideDelaySec)) { [weak self] in
//                    player.clear()
//                    player.videoItem = nil
//                    self?.emojiPlayEndHandler(self?.emojiContent)
//                    self?.svagPlayerStatus = .free
//                }
//            } else {
//                player.clear()
//                player.videoItem = nil
//                emojiPlayEndHandler(emojiContent)
//                svagPlayerStatus = .free
//            }
//            emojiContent = nil
//        default:
            svagPlayerStatus = .free
//        }
    }
}
