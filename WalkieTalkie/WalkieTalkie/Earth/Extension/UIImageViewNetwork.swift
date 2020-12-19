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
    func setImage(with urlString: String?) {
        kf.cancelDownloadTask()
        guard let url = URL(string: urlString) else {
            image = nil
            return
        }
        let resource = ImageResource(downloadURL: url, cacheKey: urlString)
        var kf = self.kf
        kf.indicatorType = .activity
        kf.setImage(with: resource)
    }
}
