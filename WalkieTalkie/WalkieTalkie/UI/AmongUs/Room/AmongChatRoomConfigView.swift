//
//  AmongChatRoomConfigView.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 16/12/20.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit
import SnapKit

class AmongChatRoomConfigView: XibLoadableView {
    //view
    lazy var amongSetupView = AmongRoomInfoSetupView()
    lazy var amongInfoView = AmongRoomInfoView()
    lazy var justChillingInfoView = JustChillingInfoView()
    
    var updateEditTypeHandler: ((RoomEditType) -> Void)?
    
    var room: Entity.Room {
        didSet {
            updateSubview()
        }
    }
    
    init(_ room: Entity.Room) {
        self.room = room
        super.init(frame: .zero)
        configureSubview()
        bindSubviewEvent()
        updateSubview()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AmongChatRoomConfigView {
    
    func updateSubview() {
        switch room.topicId {
        case .amongus:
            justChillingInfoView.isHidden = true
            amongSetupView.isHidden = room.isValidAmongConfig
            amongInfoView.isHidden = !room.isValidAmongConfig
            amongInfoView.room = room
        case .roblox:
            justChillingInfoView.isHidden = false
            amongSetupView.isHidden = true
            amongInfoView.isHidden = true
            justChillingInfoView.room = room
        case .chilling:
            justChillingInfoView.isHidden = false
            amongSetupView.isHidden = true
            amongInfoView.isHidden = true
            justChillingInfoView.room = room
        }
    }
    
    func bindSubviewEvent() {
        amongSetupView.setupHandler = { [weak self] in
            self?.updateEditTypeHandler?(AmongChat.Room.EditType.amongSetup)
        }
        
        justChillingInfoView.hostNotesClick = { [weak self] in
            self?.updateEditTypeHandler?(AmongChat.Room.EditType.chillingSetup)
        }
    }
    
    func configureSubview() {
        amongSetupView.isHidden = true
        amongInfoView.isHidden = true
        justChillingInfoView.isHidden = true
        addSubviews(views: amongSetupView, amongInfoView, justChillingInfoView)
        
        amongSetupView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        
        amongInfoView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        
        justChillingInfoView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

    }
}
