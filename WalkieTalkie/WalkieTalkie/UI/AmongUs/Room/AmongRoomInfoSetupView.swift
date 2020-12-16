//
//  AmongChatRoomInfoView.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 16/12/20.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

class AmongRoomInfoSetupView: XibLoadableView {

    var setupHandler: (() -> Void)?
    
    @IBAction func setupButtonAction(_ sender: UIButton) {
        setupHandler?()
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
