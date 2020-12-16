//
//  AmongChatRoomTopBar.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 16/12/20.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

class BottomTitleButton: UIButton {
    override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        let rect = super.imageRect(forContentRect: contentRect)
        return CGRect(x: 0, y: 0, width: contentRect.width, height: rect.height)
    }
    
    override func titleRect(forContentRect contentRect: CGRect) -> CGRect {
        let rect = super.titleRect(forContentRect: contentRect)
        return CGRect(x: 0, y: contentRect.height - rect.height, width: contentRect.width, height: rect.height)
    }
}

class AmongChatRoomTopBar: XibLoadableView {

    @IBAction func publicButtonAction(_ sender: Any) {

    }

    @IBAction func leaveButtonAction(_ sender: Any) {
    
    }
    
    @IBAction func kickOffButtonAction(_ sender: Any) {
        
    }
    
}
