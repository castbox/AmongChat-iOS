//
//  ConversationSystemMsgCell.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 26/05/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

class ConversationSystemMsgCell: UITableViewCell {

    @IBOutlet weak var avatarView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var redDotView: UIView!
    
    
    func bind(_ msg: Entity.DMSystemConversation) {
        redDotView.isHidden = msg.isRead
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
