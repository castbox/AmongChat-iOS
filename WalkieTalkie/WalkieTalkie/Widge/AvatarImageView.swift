//
//  AvatarImageView.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/1/27.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

class AvatarImageView: UIImageView {
    
    init() {
        super.init(frame: .zero)
        image = R.image.ac_profile_avatar()
        clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.width / 2
    }
    
    func updateAvatar(with profile: Entity.UserProfile) {
        setImage(with: profile.pictureUrl, placeholder: image ?? R.image.ac_profile_avatar())
    }
    
}
