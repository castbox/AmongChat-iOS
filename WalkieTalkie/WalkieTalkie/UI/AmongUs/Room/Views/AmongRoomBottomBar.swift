//
//  AmongRoomBottomBar.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 16/12/20.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

class AmongRoomBottomBar: XibLoadableView {
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var chatButton: UIButton!
    @IBOutlet weak var emojiButton: UIButton!
    @IBOutlet weak var micButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    
    @IBOutlet weak var kickButton: UIButton!
    @IBOutlet weak var calcelKickButton: UIButton!
    @IBOutlet weak var kickToolContainer: UIView!
    
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
    var room: RoomInfoable?
    
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
        set { micButton.isHidden = newValue }
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
    
    func update(_ room: RoomInfoable) {
        self.room = room
        if room.isGroup {
            emojiButton.isHidden = true
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
        self.isMicOn = !isMicOn
        changeMicStateHandler?(isMicOn)
    }
    
}
