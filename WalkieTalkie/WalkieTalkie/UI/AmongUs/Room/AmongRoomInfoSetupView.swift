//
//  AmongChatRoomInfoView.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 16/12/20.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

class AmongRoomInfoSetupView: XibLoadableView {

    var setupButtonClick: (() -> Void)?
    
    @IBAction func setupButtonAction(_ sender: UIButton) {
        setupButtonClick?()
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
