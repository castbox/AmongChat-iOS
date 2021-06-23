//
//  FeedShareUserCell.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 22/06/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

class FeedShareUserCell: UICollectionViewCell {

    @IBOutlet weak var avatarView: AvatarImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var onlineView: UIView!
    
    func bind(_ profile: Entity.UserProfile, isSelected: Bool) {
        avatarView.setAvatarImage(with: profile.pictureUrl)
        nameLabel.numberOfLines = profile.isOnlineValue ? 1 : 2
        nameLabel.attributedText = profile.nameWithVerified(fontSize: 14, withAge: false, isShowVerify: false, isShowOfficial: true, officialHeight: ._14)
        onlineView.isHidden = !profile.isOnlineValue
        if isSelected {
            avatarView.verifyIV.image = R.image.iconFeedShareUserSelected()
        } else {
            avatarView.verifyIV.image = R.image.iconVerifyBlackBorder()
            avatarView.isVerify = profile.isVerified ?? false
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
