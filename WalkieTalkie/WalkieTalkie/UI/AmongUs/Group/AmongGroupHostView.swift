//
//  AmongGroupHostView.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 30/03/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit


class AmongGroupHostView: XibLoadableView {
    
    @IBOutlet weak var hostView: UIView!
    @IBOutlet weak var stackView: UIStackView!
//    private var userCell: AmongChat.Room.UserCell!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubview()
        bindSubviewEvent()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBAction func raisedHandsAction(_ sender: Any) {
        
    }
    
    @IBAction func joinReuqestAction(_ sender: Any) {
        
    }
    
    @IBAction func hostAvatarAction(_ sender: Any) {
        
    }
    
    private func bindSubviewEvent() {
//        userCell.bind(nil, topic: .amongus, index: 0)
    }
    
    private func configureSubview() {
//        hostView?.bind(nil, topic: .amongus, index: 0)
//        userCell = AmongChat.Room.UserCell(frame: CGRect(x: 0, y: 0, width: AmongChat.Room.SeatView.itemWidth, height: AmongChat.Room.SeatView.itemHeight))
//        hostView.addSubview(userCell)
//        userCell.snp.makeConstraints { maker in
//            maker.width.equalTo(AmongChat.Room.SeatView.itemWidth)
//            maker.height.equalTo(AmongChat.Room.SeatView.itemHeight)
//            maker.center.equalToSuperview()
//        }
//        if index < 5 {
//            topStackView.addArrangedSubview(cell)
//        } else {
//            bottomStackView.addArrangedSubview(cell)
//        }
//        cell.emojisNames = room.topicType.roomEmojiNames

    }
    
}
