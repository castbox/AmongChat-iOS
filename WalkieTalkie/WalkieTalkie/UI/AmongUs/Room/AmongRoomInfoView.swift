//
//  AmongRoomInfoView.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 16/12/20.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

class AmongRoomInfoView: XibLoadableView {

    @IBOutlet weak var aeraLabel: UIButton!
    @IBOutlet weak var codeLabel: UILabel!

    var room: Entity.Room? {
        didSet {
            codeLabel.text = room?.amongUsCode
            aeraLabel.setTitle(room?.amongUsZone?.title, for: .normal)
        }
    }
    
    @IBAction func copyButtonAction(_ sender: Any) {
        //is self
        if room?.roomUserList.first?.uid == "" {
            
        } else {
            room?.amongUsCode?.copyToPasteboard()
            raft.autoShow(.text(R.string.localizable.copied()), userInteractionEnabled: false)
        }
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
