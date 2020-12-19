//
//  JustChillingInfoView.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 16/12/20.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

class JustChillingInfoView: XibLoadableView {
    
    @IBOutlet weak var notesTitleButton: UIButton!
    @IBOutlet weak var notesDetailButton: UIButton!
    
    var room: Entity.Room? {
        didSet {
            guard let room = room else {
                return
            }
            if room.topicId == .roblox {
                notesDetailButton.isHidden = true
                notesTitleButton.setTitle(R.string.localizable.amongChatRoomRebloxTitle(), for: .normal)
            } else {
                notesDetailButton.isHidden = false
                guard let string = room.note, !string.isEmpty else {
                    notesDetailButton.setTitle(R.string.localizable.amongChatRoomJustChatTitle(), for: .normal)
                    return
                }
                notesDetailButton.setTitle(string, for: .normal)
            }
            
        }
    }
    
    var hostNotesClick: CallBack?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        bindSubviewEvent()
        configureSubview()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func bindSubviewEvent() {
        notesTitleButton.setTitle(R.string.localizable.roomHostsNotes(), for: .normal)
        notesTitleButton.titleLabel?.numberOfLines = 0
        notesDetailButton.titleLabel?.numberOfLines = 3
    }
    
    private func configureSubview() {
        
    }
    
    @IBAction func hostNotesAction(_ sender: Any) {
        guard room?.topicId == AmongChat.Topic.chilling else {
            return
        }
        hostNotesClick?()
    }
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */
    
}
