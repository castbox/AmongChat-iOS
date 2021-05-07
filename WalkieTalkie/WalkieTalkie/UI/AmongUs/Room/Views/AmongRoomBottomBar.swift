//
//  AmongRoomBottomBar.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 16/12/20.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import EasyTipView
import RxSwift
import RxCocoa

class AmongRoomBottomBar: XibLoadableView {
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var chatButton: UIButton!
    @IBOutlet weak var emojiButton: UIButton!
    @IBOutlet weak var micButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    
    @IBOutlet weak var kickButton: UIButton!
    @IBOutlet weak var calcelKickButton: UIButton!
    @IBOutlet weak var kickToolContainer: UIView!
    private weak var tipBgView: UIView?
    private weak var tipView: EasyTipView?
    
    var style: AmongChat.Room.Style = .normal {
        didSet {
            switch style {
            case .normal:
                kickToolContainer.isHidden = true
                stackView.isHidden = false
                micButton.isHidden = false
            case .kick:
                kickToolContainer.isHidden = false
                stackView.isHidden = true
                micButton.isHidden = true
            }
        }
    }
    
    var selectedKickUser: [Int] = [] {
        didSet {
            kickButton.setTitle(R.string.localizable.amongChatRoomKickSelected(selectedKickUser.count.string), for: .normal)
            kickButton.backgroundColor = selectedKickUser.isEmpty ? UIColor.white.alpha(0.2) : "D30F0F".color()
        }
    }
    
    var sendMessageHandler: CallBack?
    var shareHandler: CallBack?
    var emojiHandler: CallBack?
    var changeMicStateHandler: ((Bool) -> Void)?
    
    var cancelKickHandler: CallBack?
    var kickSelectedHandler: (([Int]) -> Void)?
    var room: RoomDetailable?
    
    var muteInfo: Entity.UserMuteInfo? {
        didSet {
            guard let info = muteInfo else {
                return
            }
            if info.isMute {
                if isMicOn {
                    switchMicState()
                    showMicDisabledTips()
                }
            } else {
                if !isMicOn {
                    switchMicState()
                }
            }
        }
    }
    private let bag = DisposeBag()
    
    var isMicOn: Bool = true {
        didSet {
            if isMicOn {
                micButton.setBackgroundImage("FFF000".color().image, for: .normal)
                micButton.setTitle(R.string.localizable.amongChatRoomTipMicOn(), for: .normal)
                micButton.setImage(R.image.ac_icon_mic_on(), for: .normal)
            } else {
                micButton.setBackgroundImage("FB5858".color().image, for: .normal)
                micButton.setTitle(R.string.localizable.roomUserListMuted(), for: .normal)
                micButton.setImage(R.image.ac_icon_mic_off(), for: .normal)
            }
        }
    }
    
    var isMicButtonHidden: Bool {
        get { micButton.isHidden }
        set {
            micButton.isHidden = newValue
            //hidden 同时 mic 为关闭状态
            if !newValue, !isMicOn {
                changeMicStateAction(self.micButton)
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        bindSubviewEvent()
        configureSubview()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func bindSubviewEvent() {
        
    }
    
    private func configureSubview() {
        micButton.titleLabel?.adjustsFontSizeToFitWidth = true
        if Frame.Height.deviceDiagonalIsMinThan4_7,
           room?.topicType == .chilling {
            stackView.spacing = 5
        }
    }
    
    func update(_ room: RoomDetailable) {
        self.room = room
        if room.isGroup {
            emojiButton.isHidden = !room.loginUserIsAdmin && room.loginUserSeatNo == -1
        } else {
            emojiButton.isHidden = room.topicType != .chilling
        }
        
    }
    
    @IBAction func cancelKickAction(_ sender: Any) {
        cancelKickHandler?()
    }
    
    @IBAction func kickSelectedAction(_ sender: Any) {
        guard !selectedKickUser.isEmpty else {
            return
        }
        kickSelectedHandler?(selectedKickUser)
    }
    
    @IBAction func sendMessageButtonAction(_ sender: Any) {
        sendMessageHandler?()
    }
    
    @IBAction func emojiButtonAction(_ sender: Any) {
        emojiHandler?()
    }
    
    
    @IBAction func shareButtonAction(_ sender: Any) {
        shareHandler?()
    }
    
    @IBAction func changeMicStateAction(_ sender: UIButton) {
        //检查是否为被管理员 mute
        if let info = muteInfo, info.isMute {
            showMicDisabledTips()
            return
        }
        switchMicState()
    }
    
    func switchMicState() {
        self.isMicOn = !isMicOn
        changeMicStateHandler?(isMicOn)
    }
    
}

private extension AmongRoomBottomBar {
    
    func showMicDisabledTips() {
        
        //
        var attrString: NSAttributedString {
//            let pargraph = NSMutableParagraphStyle()
//            pargraph.lineBreakMode = .byTruncatingTail
//            pargraph.lineHeightMultiple = 0
                        
            let mutableNormalString = NSMutableAttributedString()
            
            let font = R.font.nunitoExtraBold(size: 16)!
            let image = R.image.iconMutedTips()!
            let imageAttachment = NSTextAttachment()
            imageAttachment.image = image
            imageAttachment.bounds = CGRect(x: 0, y: (font.capHeight - image.size.height)/2, width: image.size.width, height: image.size.height)
            let imageString = NSAttributedString(attachment: imageAttachment)
            mutableNormalString.append(imageString)
//            mutableNormalString.yy_appendString(" ")

            let contentAttr: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.black,
                .font: font,
//                .paragraphStyle: pargraph
            ]
            mutableNormalString.append(NSAttributedString(string: R.string.localizable.micMutedTips(), attributes: contentAttr))
            return mutableNormalString
        }
        
        var preferences = EasyTipView.Preferences()
        preferences.drawing.font = R.font.nunitoExtraBold(size: 16) ?? UIFont.boldSystemFont(ofSize: 16)
        preferences.drawing.foregroundColor = .black
        preferences.drawing.backgroundColor = .white
        preferences.drawing.arrowPosition = .top
        preferences.positioning.bubbleInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 20)
        
        let tipView = EasyTipView(text: attrString,
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
        tipView.show(animated: true, forView: micButton, withinSuperview: containingController?.view)
        Observable<Int>
            .interval(.seconds(5), scheduler: MainScheduler.instance)
            .single()
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                self.dismissTipView()
            })
            .disposed(by: bag)
    }
    
    @objc func dismissTipView() {
        tipBgView?.removeFromSuperview()
        tipView?.dismiss()
        tipView = nil
    }
}

extension AmongRoomBottomBar: EasyTipViewDelegate {
    func easyTipViewDidTap(_ tipView: EasyTipView) {
        dismissTipView()
    }
    
    func easyTipViewDidDismiss(_ tipView : EasyTipView) {
        
    }
}
