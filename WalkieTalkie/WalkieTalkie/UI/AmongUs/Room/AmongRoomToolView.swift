//
//  AmongRoomToolView.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 17/12/20.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

class AmongRoomToolView: XibLoadableView {
    
    @IBOutlet weak var openGameButton: UIButton!
    @IBOutlet weak var nickNameButton: UIButton!
    
    var openGameHandler: CallBack?
    var setNickNameHandler: CallBack?
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        bindSubviewEvent()
        configureSubview()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func set(_ room: Entity.Room) {
        switch room.topicId {
        case .amongus:
            openGameButton.setTitle(R.string.localizable.roomTagOpenGame(), for: .normal)
        case .roblox:
            openGameButton.setTitle(R.string.localizable.roomTagOpenGame(), for: .normal)
            
        default:
            openGameButton.setTitle(R.string.localizable.roomTagChilling(), for: .normal)
        }
        openGameButton.isUserInteractionEnabled = room.topicId != .chilling
        nickNameButton.isHidden = room.topicId != .roblox
    }
    
    private func bindSubviewEvent() {
        
    }
    
    private func configureSubview() {
        openGameButton.setBackgroundImage("592DFF".color().image, for: .normal)
    }
    
    @IBAction func setupNickNameAction(_ sender: Any) {
        setNickNameHandler?()
    }
    @IBAction func openGameAction(_ sender: Any) {
        openGameHandler?()
    }
}
