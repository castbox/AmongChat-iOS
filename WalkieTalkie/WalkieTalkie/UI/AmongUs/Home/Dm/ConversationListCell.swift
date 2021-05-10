//
//  ConversationListCell.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 07/05/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

class ConversationListCell: UICollectionViewCell {

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
        contentLabel.text = msg.body.text
        timeLabel.text = msg.dateString
        countLabel.text = item.unreadCount.string
    }
}
