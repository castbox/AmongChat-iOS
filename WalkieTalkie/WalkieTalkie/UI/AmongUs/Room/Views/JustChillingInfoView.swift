//
//  JustChillingInfoView.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 16/12/20.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

class JustChillingInfoView: XibLoadableView {
    
    @IBOutlet weak var setUpButton: UIButton!
    @IBOutlet weak var notesTitleButton: UIButton!
    @IBOutlet weak var notesDetailButton: UIButton!
    
    var room: Entity.Room? {
        didSet {
            guard let room = room else {
                return
            }
            switch room.topicType {
            case .chilling:
                notesDetailButton.isHidden = false
                guard let string = room.note, !string.isEmpty else {
                    notesDetailButton.setTitle(R.string.localizable.amongChatRoomJustChatTitle(), for: .normal)
                    break
                }
                notesDetailButton.setTitle(string, for: .normal)
            default:
                notesDetailButton.isHidden = true
                notesTitleButton.setTitle(room.topicType.notes, for: .normal)
            }
            
            if room.topicType == .chilling,
               room.roomUserList.first?.uid == Settings.loginUserId,
               room.note?.isEmpty ?? true {
                setUpButton.isHidden = false
                notesTitleButton.isHidden = true
                notesDetailButton.snp.remakeConstraints { (maker) in
                    maker.top.equalTo(setUpButton.snp.bottom).offset(8)
                    maker.left.bottom.equalToSuperview()
                    maker.right.lessThanOrEqualToSuperview().offset(-24)
                }
            } else {
                setUpButton.isHidden = true
                notesTitleButton.isHidden = false
                notesDetailButton.snp.remakeConstraints { (maker) in
                    maker.top.equalTo(notesTitleButton.snp.bottom).offset(8)
                    maker.left.bottom.equalToSuperview()
                    maker.right.lessThanOrEqualToSuperview().offset(-24)
                }
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
        notesTitleButton.titleLabel?.textAlignment = .left
        notesDetailButton.titleLabel?.textAlignment = .left
    }
    
    private func configureSubview() {
        
    }
    
    @IBAction func hostNotesAction(_ sender: Any) {
        guard room?.topicType == AmongChat.Topic.chilling else {
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
