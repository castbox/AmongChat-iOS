//
//  UIImageViewNetwork.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 17/12/20.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import Foundation
import Kingfisher

extension UIImageView {
    
    func setImage(with urlString: String?, placeholder: UIImage? = nil) {
        guard let url = URL(string: urlString) else {
            image = nil
            return
        }
        let resource = ImageResource(downloadURL: url, cacheKey: urlString)
        var kf = self.kf
        kf.indicatorType = .activity
        self.kf.setImage(with: resource, placeholder: placeholder)
    }
    
    func setAvatarImage(with urlString: String?) {
        setImage(with: urlString, placeholder: R.image.ac_profile_avatar())
    }
}
