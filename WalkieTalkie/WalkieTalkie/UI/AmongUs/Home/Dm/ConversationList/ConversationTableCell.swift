//
//  ConversationTableCell.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 11/05/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

class ConversationTableCell: UITableViewCell {
    
    @IBOutlet weak var avatarView: AvatarImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var countView: UIView!
    @IBOutlet weak var countLabel: UILabel!
    
//    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
//        super.init(style: style, reuseIdentifier: reuseIdentifier)
//        self.avatarView.verifyStyle = .gray
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        super
//    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func bind(_ item: Entity.DMConversation) {
        let msg = item.message
        avatarView.setAvatarImage(with: msg.fromUser.pictureUrl)
        avatarView.isVerify = msg.fromUser.isVerified
        nameLabel.attributedText = msg.fromUser.nameWithVerified(fontSize: 20, isShowVerify: false)
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
