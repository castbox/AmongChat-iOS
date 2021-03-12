//
//  JustChillingInfoView.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 16/12/20.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

class JustChillingInfoView: XibLoadableView {
    
    @IBOutlet weak var setUpView: UIView!
    @IBOutlet weak var setUpLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    var room: Entity.Room? {
        didSet {
            guard let room = room else {
                return
            }
            switch room.topicType {
            case .chilling:
                descriptionLabel.isHidden = false
                guard let string = room.note, !string.isEmpty else {
                    descriptionLabel.text = R.string.localizable.amongChatRoomJustChatTitle()
                    descriptionLabel.textColor = UIColor.white.alpha(0.65)
                    descriptionLabel.font = R.font.nunitoExtraBold(size: 12)
                    break
                }
                descriptionLabel.text = string
                descriptionLabel.textColor = .white
                descriptionLabel.font = R.font.nunitoExtraBold(size: 13)
            default:
                descriptionLabel.isHidden = true
                titleLabel.text = room.topicType.notes
            }
            
            if room.topicType == .chilling,
               room.roomUserList.first?.uid == Settings.loginUserId,
               room.note?.isEmpty ?? true {
                setUpView.isHidden = false
                titleLabel.isHidden = true
                descriptionLabel.snp.remakeConstraints { (maker) in
                    maker.top.equalTo(setUpView.snp.bottom).offset(8)
                    maker.left.bottom.equalToSuperview()
                    maker.right.lessThanOrEqualToSuperview().offset(-24)
                }
            } else {
                setUpView.isHidden = true
                titleLabel.isHidden = false
                descriptionLabel.snp.remakeConstraints { (maker) in
                    maker.top.equalTo(titleLabel.snp.bottom).offset(8)
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
        titleLabel.text = R.string.localizable.roomHostsNotes()
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
