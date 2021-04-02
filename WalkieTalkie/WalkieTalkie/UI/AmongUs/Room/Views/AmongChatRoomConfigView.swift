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
    lazy var infoWithNicknameView = InfoWithNicknameView()
    
    @IBOutlet weak var gameIconIV: UIImageView!
    @IBOutlet weak var openGameButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var gameIconTop: NSLayoutConstraint!
    
    var updateEditTypeHandler: ((RoomEditType) -> Void)?
    var openGameHandler: CallBack?
    
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
    @IBAction func onOpenGameButton(_ sender: UIButton) {
        openGameHandler?()
    }
}

extension AmongChatRoomConfigView {
    
    func updateSubview() {
        switch room.topicType {
        case .amongus:
            justChillingInfoView.isHidden = true
            infoWithNicknameView.isHidden = true
            amongSetupView.isHidden = room.isValidAmongConfig
            amongInfoView.isHidden = !room.isValidAmongConfig
            amongInfoView.room = room
//            amongSetupView.isUserInteractionEnabled = room.loginUserIsAdmin
//            justChillingInfoView.isUserInteractionEnabled = room.loginUserIsAdmin
        case .chilling:
            justChillingInfoView.isHidden = false
            amongSetupView.isHidden = true
            amongInfoView.isHidden = true
            infoWithNicknameView.isHidden = true
            justChillingInfoView.room = room
            
        case .roblox,
             .fortnite,
             .freefire,
             .minecraft,
             .mobilelegends,
             .pubgmobile,
             .animalCrossing,
             .brawlStars,
             .callofduty:
            
            justChillingInfoView.isHidden = true
            amongSetupView.isHidden = true
            amongInfoView.isHidden = true
            infoWithNicknameView.isHidden = false
            infoWithNicknameView.room = room
            
        default:
            justChillingInfoView.isHidden = false
            amongSetupView.isHidden = true
            amongInfoView.isHidden = true
            justChillingInfoView.room = room
//            justChillingInfoView.isUserInteractionEnabled = room.loginUserIsAdmin
        }
        
        if room.topicType.productId > 0 {
            openGameButton.isHidden = false
            nameLabel.isHidden = true
            gameIconTop.constant = 14.5
        } else {
            openGameButton.isHidden = true
            nameLabel.isHidden = false
            nameLabel.text = room.topicName
            gameIconTop.constant = 18.5
        }
    }
    
    func bindSubviewEvent() {
        //sync state
        
        amongSetupView.setupHandler = { [weak self] in
            guard let `self` = self else {
                return
            }
            if self.room.userList.first?.uid == Settings.loginUserId {
                self.updateEditTypeHandler?(AmongChat.Room.EditType.amongSetup)
            } else {
                Logger.Action.log(.room_edit_clk, categoryValue: self.room.topicId)
                self.containingController?.view.raft.autoShow(.text(R.string.localizable.amongChatRoomUserChangeNotesTitle()), userInteractionEnabled: false)
            }
        }
        
        justChillingInfoView.hostNotesClick = { [weak self] in
            guard let `self` = self else {
                return
            }
            if self.room.userList.first?.uid == Settings.loginUserId {
                self.updateEditTypeHandler?(AmongChat.Room.EditType.chillingSetup)
            } else {
                Logger.Action.log(.room_edit_clk, categoryValue: self.room.topicId)
                self.containingController?.view.raft.autoShow(.text(R.string.localizable.amongChatRoomUserChangeNotesTitle()), userInteractionEnabled: false)
            }
            
        }
        
        amongInfoView.tapHandler = { [weak self] in
            guard let `self` = self else {
                return
            }
            if self.room.userList.first?.uid == Settings.loginUserId {
                self.updateEditTypeHandler?(AmongChat.Room.EditType.amongSetup)
            } else {
                Logger.Action.log(.room_amongus_code_copy)
                self.room.amongUsCode?.copyToPasteboardWithHaptic()
                self.containingController?.view.raft.autoShow(.text(R.string.localizable.copied()), userInteractionEnabled: false)
            }

        }
        
        infoWithNicknameView.setNickNameHandler = { [weak self] in
            self?.updateEditTypeHandler?(AmongChat.Room.EditType.nickName)
        }
    }
    
    func configureSubview() {
        amongSetupView.isHidden = true
        amongInfoView.isHidden = true
        justChillingInfoView.isHidden = true
        infoWithNicknameView.isHidden = true
        openGameButton.isHidden = true
        nameLabel.isHidden = true
        
        infoWithNicknameView.room = room
        amongInfoView.room = room
        justChillingInfoView.room = room
        
        addSubviews(views: amongSetupView, amongInfoView, justChillingInfoView, infoWithNicknameView)
        
        amongSetupView.snp.makeConstraints { maker in
            maker.top.greaterThanOrEqualToSuperview().inset(10)
            maker.centerY.equalToSuperview()
            maker.right.equalToSuperview()
            maker.left.equalTo(gameIconIV.snp.right).offset(28)
        }
        
        amongInfoView.snp.makeConstraints { maker in
            maker.top.greaterThanOrEqualToSuperview().inset(10)
            maker.centerY.equalToSuperview()
            maker.right.equalToSuperview()
            maker.left.equalTo(gameIconIV.snp.right).offset(28)
        }
        
        justChillingInfoView.snp.makeConstraints { maker in
            maker.top.greaterThanOrEqualToSuperview().inset(10)
            maker.centerY.equalToSuperview()
            maker.right.equalToSuperview()
            maker.left.equalTo(gameIconIV.snp.right).offset(28)
        }
        
        infoWithNicknameView.snp.makeConstraints { (maker) in
            maker.top.greaterThanOrEqualToSuperview().inset(10)
            maker.centerY.equalToSuperview()
            maker.right.equalToSuperview()
            maker.left.equalTo(gameIconIV.snp.right).offset(28)
        }
        
        gameIconIV.setImage(with: room.coverUrl)
    }
}
