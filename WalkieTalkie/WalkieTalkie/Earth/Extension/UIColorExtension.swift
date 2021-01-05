//
//  UIColorExtension.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 30/12/20.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

extension UIColor {
    var image: UIImage {
        return UIImage(color: self, size: CGSize(width: 10, height: 10))
    }
}
