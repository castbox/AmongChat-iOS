//
//  AmongChatRoomInfoView.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 16/12/20.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

class AmongRoomInfoSetupView: XibLoadableView {

    @IBOutlet weak var setupButton: UIButton!
    var setupHandler: (() -> Void)?
    
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
        setupButton.titleLabel?.numberOfLines = 0
    }
    
    @IBAction func setupButtonAction(_ sender: UIButton) {
        setupHandler?()
    }
    
}
