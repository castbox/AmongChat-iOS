//
//  ConversationTableCell.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 11/05/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

class ConversationTableCell: UITableViewCell {
    
    @IBOutlet weak var avatarView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var countView: UIView!
    @IBOutlet weak var countLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func bind(_ item: Entity.DMConversation) {
        let msg = item.message
        avatarView.setAvatarImage(with: msg.fromUser.pictureUrl)
        nameLabel.text = msg.fromUser.name
        switch item.message.body.msgType {
        case .text:
            contentLabel.text = msg.body.text
        case .gif:
            contentLabel.text = R.string.localizable.dmGifText()
        case .voice:
            contentLabel.text = R.string.localizable.dmVoiceMessageText()
        default:
            ()
        }
        timeLabel.text = msg.date.timeFormattedForConversationList()
        countLabel.text = item.unreadCount.string
        countView.isHidden = item.unreadCount <= 0
    }
}
