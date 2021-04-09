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

class AmongGroupHostView: XibLoadableView {
    
    enum Action {
        case joinHost
        case joinGroup
        case editNickName
    }
    
    @IBOutlet weak var hostView: UIView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var raiseHandsContainer: UIView!
    @IBOutlet weak var raiseButton: UIImageView!
    @IBOutlet weak var applyGroupContainer: UIView!
    @IBOutlet weak var applyGroupButton: UIImageView!
    @IBOutlet weak var hostAvatarView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var gameNameButton: UIButton!
    @IBOutlet weak var indexLabel: UILabel!
    
    private var onSeatBadge: BadgeHub?
    private var applyGroupBadge: BadgeHub?
    private var tipView: EasyTipView?
    private let bag = DisposeBag()
//    private var isShowTips: Bool
    
    var actionHandler: ((Action) -> Void)?
    
    var group: Entity.GroupRoom? {
        didSet {
            hostAvatarView.setImage(with: group?.broadcaster.pictureUrl)
            nameLabel.text = group?.broadcaster.name
            if let group = group, group.hostNickname.isValid {
                gameNameButton.setTitle(group.hostNickname, for: .normal)
            } else {
                //set nick name
                gameNameButton.setTitle(group?.topicType.groupGameNamePlaceholder, for: .normal)
                //show
                showGameNameTipsIfNeed()
            }
            if Settings.loginUserId == group?.broadcaster.uid {
                nameLabel.textColor = "#FFF000".color()
            } else {
                nameLabel.textColor = .white
            }
            applyGroupContainer.isHidden = group?.loginUserIsAdmin == false
            raiseHandsContainer.isHidden = applyGroupContainer.isHidden
            indexLabel.textColor = nameLabel.textColor
            gameNameButton.setTitleColor(nameLabel.textColor, for: .normal)
            gameNameButton.isHidden = group?.topicType == .amongus
            updateGameNameTitle()
        }
    }
    
//    var groupRequestCount: Int {
//        applyGroup.redDotOn()
//    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubview()
        bindSubviewEvent()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showGameNameTipsIfNeed() {
        guard let group = group,
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
        
        tipView = EasyTipView(text: tips,
                              preferences: preferences,
                              delegate: self)
        tipView?.tag = 0
        tipView?.show(animated: true, forView: gameNameButton, withinSuperview: superview)
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
            onSeatBadge?.setCountLabel(R.font.nunitoExtraBold(size: 12))
            onSeatBadge?.scaleCircleSize(by: 0.4)
            onSeatBadge?.setCircleAtFrame(CGRect(x: raiseButton.bounds.width - 5, y: 0, width: 16, height: 16))
//            segmentedView.clipsToBounds = false
//            Logger.PageShow.logger("lv_rm_pk", "pk_receive",room.room_id, nil)
        }
        onSeatBadge?.setCount(count)
    }
    
    func updateApplyGroupBadge(with count: Int) {
        if applyGroupBadge == nil {
            applyGroupBadge = BadgeHub(view: applyGroupButton) // Initially count set to 0
            applyGroupBadge?.setCircleColor(UIColor(hex: 0xFB5858), label: .white)
            applyGroupBadge?.setCountLabel(R.font.nunitoExtraBold(size: 12))
            applyGroupBadge?.scaleCircleSize(by: 0.4)
            applyGroupBadge?.setCircleAtFrame(CGRect(x: applyGroupButton.bounds.width - 5, y: 0, width: 16, height: 16))
//            segmentedView.clipsToBounds = false
//            Logger.PageShow.logger("lv_rm_pk", "pk_receive",room.room_id, nil)
        }
        applyGroupBadge?.setCount(count)
    }
    
    @objc func dismissTipView() {
        tipView?.dismiss()
    }
    
    @IBAction func raisedHandsAction(_ sender: Any) {
        actionHandler?(.joinHost)
    }
    
    @IBAction func joinReuqestAction(_ sender: Any) {
        actionHandler?(.joinGroup)
    }
    
    @IBAction func hostAvatarAction(_ sender: Any) {
//        showShareTipView()
    }
    
    @IBAction func gameNameAction(_ sender: Any) {
        actionHandler?(.editNickName)
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

    }
    
    private func updateGameNameTitle() {
        guard let group = group,
              group.loginUserIsAdmin,
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
