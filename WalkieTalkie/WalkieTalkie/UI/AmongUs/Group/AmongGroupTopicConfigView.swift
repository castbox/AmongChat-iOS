//
//  AmongGroupTopicConfigView.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 30/03/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

class AmongGroupTopicConfigView: XibLoadableView {
    @IBOutlet weak var setupButton: UIButton!
    
    @IBOutlet weak var amongUsContainer: UIView!
    @IBOutlet weak var codeLabel: UILabel!
    @IBOutlet weak var serviceLocationButton: UIButton!
    @IBOutlet weak var actionIcon: UIImageView!
    //justchatting 房间如果设置了 notes, 听众会有此按钮
    @IBOutlet weak var notesButton: UIButton!
    
    var group: Entity.GroupRoom? {
        didSet {
            guard let group = group else {
                return
            }
            if group.topicType == .amongus {
                codeLabel.text = group.amongUsCode?.uppercased()
                serviceLocationButton.setTitle(group.amongUsZone?.title, for: .normal)

                if group.userList.first?.uid == Settings.loginUserId {
                    actionIcon.image = R.image.ac_room_code_edit()
                } else {
                    actionIcon.image = R.image.ac_room_code_copy()
                }
            } else {
                notesButton.isHidden = !group.note.isValid
                setupButton.isHidden = !group.loginUserIsAdmin && !group.note.isValid
                if group.note.isValid {
                    notesButton.isHidden = false
                }
//                if group.loginUserIsAdmin {
//
//                }
//                switch group.topicType {
//                case .amongus:
//                    //
//
//                case .chilling:
//                    if group.loginUserIsAdmin {
//
//                    }
//                    notesButton.isHidden = false
//                    guard let string = room.note, !string.isEmpty else {
//                        descriptionLabel.text = R.string.localizable.amongChatRoomJustChatTitle()
//                        descriptionLabel.textColor = UIColor.white.alpha(0.65)
//                        descriptionLabel.font = R.font.nunitoExtraBold(size: 12)
//                        break
//                    }
//                    descriptionLabel.text = string
//                    descriptionLabel.textColor = .white
//                    descriptionLabel.font = R.font.nunitoExtraBold(size: 13)
//                default:
//                    descriptionLabel.isHidden = true
//                    titleLabel.text = room.topicType.notes
//                }
//
//                if room.topicType == .chilling,
//                   room.userList.first?.uid == Settings.loginUserId,
//                   room.note?.isEmpty ?? true {
//                    setUpView.isHidden = false
//                    titleLabel.isHidden = true
//                    descriptionLabel.snp.remakeConstraints { (maker) in
//                        maker.top.equalTo(setUpView.snp.bottom).offset(8)
//                        maker.left.bottom.equalToSuperview()
//                        maker.right.lessThanOrEqualToSuperview().offset(-24)
//                    }
//                } else {
//                    setUpView.isHidden = true
//                    titleLabel.isHidden = false
//                    descriptionLabel.snp.remakeConstraints { (maker) in
//                        maker.top.equalTo(titleLabel.snp.bottom).offset(8)
//                        maker.left.bottom.equalToSuperview()
//                        maker.right.lessThanOrEqualToSuperview().offset(-24)
//                    }
//                }
                
            }

        }
    }
    
    @IBAction func setupButtonAction(_ sender: Any) {
        
    }
}
