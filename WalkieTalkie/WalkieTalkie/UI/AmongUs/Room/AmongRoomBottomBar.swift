//
//  AmongRoomBottomBar.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 16/12/20.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

class AmongRoomBottomBar: XibLoadableView {
    
    @IBOutlet weak var micButton: UIButton!
    
    var sendMessageHandler: CallBack?
    var shareHandler: CallBack?
    var changeMicStateHandler: ((Bool) -> Void)?
    
    var isMicOn: Bool = true {
        didSet {
            if isMicOn {
                micButton.setBackgroundImage("FFF000".color().image, for: .normal)
                micButton.setTitle(R.string.localizable.amongChatRoomTipMicOn(), for: .normal)
                micButton.setImage(R.image.ac_icon_mic_on(), for: .normal)
            } else {
                micButton.setBackgroundImage("FB5858".color().image, for: .normal)
                micButton.setTitle(R.string.localizable.amongChatRoomTipMicOff(), for: .normal)
                micButton.setImage(R.image.ac_icon_mic_off(), for: .normal)
            }
        }
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
