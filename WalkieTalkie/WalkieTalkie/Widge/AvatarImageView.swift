//
//  AvatarImageView.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/1/27.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

class AvatarImageView: UIImageView {
    
    static var placeholder: UIImage?
    
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
        
        let placeholder: UIImage?
        
        if profile.uid.isSelfUid {
            placeholder = Self.placeholder ?? R.image.ac_profile_avatar()
        } else {
            placeholder = R.image.ac_profile_avatar()
        }
        
        setImage(with: profile.pictureUrl, placeholder: placeholder)
    }
    
}
