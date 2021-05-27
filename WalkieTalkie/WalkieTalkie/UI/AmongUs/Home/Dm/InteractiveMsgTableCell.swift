//
//  InteractiveMsgTableCell.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 26/05/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

class InteractiveMsgTableCell: UITableViewCell {

    @IBOutlet weak var avatarView: AvatarImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var desLabel: UILabel!
    @IBOutlet weak var postCoverView: UIImageView!
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var redDotView: UIView!
    
    private var viewModel: Conversation.InteractiveMessageCellViewModel?
    
    func configView(with viewModel: Conversation.InteractiveMessageCellViewModel) {
        self.viewModel = viewModel
        let msg = viewModel.msg
        avatarView.setAvatarImage(with: msg.pictureUrl)
        avatarView.isVerify = msg.isVerified
        nameLabel.attributedText = msg.nameWithVerified()
        desLabel.text = msg.opType?.rawValue
        postCoverView.setImage(with: msg.img)
        timeLabel.text = viewModel.timeString
        commentLabel.text = msg.text
    }
    
    @IBAction func tapAvatarAction(_ sender: Any) {
        guard let uid = viewModel?.msg.uid else {
            return
        }
        Routes.handle("/profile/\(uid)")
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
