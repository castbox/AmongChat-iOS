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

    @IBOutlet weak var publicButton: UIButton!
    @IBOutlet weak var kickButton: UIButton!
    @IBOutlet weak var leaveButton: UIButton!
    
    var changePublicStateHandler: CallBack?
    var leaveHandler: CallBack?
    var kickOffHandler: CallBack?
    
    var room: Entity.Room? {
        didSet {
            
        }
    }
    
    @IBAction func publicButtonAction(_ sender: Any) {
        changePublicStateHandler?()
    }

    @IBAction func leaveButtonAction(_ sender: Any) {
        leaveHandler?()
    }
    
    @IBAction func kickOffButtonAction(_ sender: Any) {
        kickOffHandler?()
    }
    
}
