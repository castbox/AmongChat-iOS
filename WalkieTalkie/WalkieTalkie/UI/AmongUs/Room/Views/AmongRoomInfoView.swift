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
    
    var tapHandler: CallBack?
    
    var room: Entity.Room? {
        didSet {
            codeLabel.text = room?.amongUsCode?.uppercased()
            aeraLabel.setTitle(room?.amongUsZone?.title, for: .normal)
        }
    }
    
    @IBAction func copyButtonAction(_ sender: Any) {
        //is self
        tapHandler?()
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
