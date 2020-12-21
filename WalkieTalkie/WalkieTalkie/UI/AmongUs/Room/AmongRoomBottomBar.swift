//
//  AmongRoomBottomBar.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 16/12/20.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

class AmongRoomBottomBar: XibLoadableView {
    
    @IBOutlet weak var chatButton: UIButton!
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
                chatButton.isHidden = false
                micButton.isHidden = false
                shareButton.isHidden = false
            case .kick:
                kickToolContainer.isHidden = false
                chatButton.isHidden = true
                micButton.isHidden = true
                shareButton.isHidden = true
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
    var changeMicStateHandler: ((Bool) -> Void)?
    
    var cancelKickHandler: CallBack?
    var kickSelectedHandler: (([Int]) -> Void)?
    
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
    
    @IBAction func shareButtonAction(_ sender: Any) {
        shareHandler?()
    }
    
    @IBAction func changeMicStateAction(_ sender: UIButton) {
        self.isMicOn = !isMicOn
        changeMicStateHandler?(isMicOn)
    }
    
}
