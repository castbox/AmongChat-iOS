//
//  SnapChatSharePhotoView.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 24/02/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

class SnapChatSharePhotoView: XibLoadableView {
    @IBOutlet weak var avatarView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var clickTipsLabel: UILabel!
    @IBOutlet weak var avatarWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var linkViewbottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLabelWidthConstraint: NSLayoutConstraint!

    init(image: UIImage?) {
        super.init(frame: Frame.Screen.bounds)
        avatarView.image = image ?? R.image.ac_profile_avatar()
        bindSubviewEvent()
        configureSubview()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func bindSubviewEvent() {
        
    }
    
    private func configureSubview() {
        if Frame.Height.deviceDiagonalIsMinThan5_5 {
            avatarWidthConstraint.constant = 100
            titleLabel.font = R.font.nunitoExtraBold(size: 21)
            clickTipsLabel.font = R.font.nunitoBold(size: 15)
            linkViewbottomConstraint.constant = 45
            avatarView.cornerRadius = avatarWidthConstraint.constant / 2
            layoutIfNeeded()
        }
    }
}
