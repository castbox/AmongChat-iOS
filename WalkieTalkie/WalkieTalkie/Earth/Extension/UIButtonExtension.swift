//
//  UIButtonExtension.swift
//  WalkieTalkie
//
//  Created by mayue on 2021/6/25.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

extension UIButton {
    
    func setImageTitleHorizontalSpace(_ space: CGFloat) {
        
        if UIView.userInterfaceLayoutDirection(for: semanticContentAttribute) == .rightToLeft {
            titleEdgeInsets = UIEdgeInsets(top: 0, left: -(space / 2), bottom: 0, right: (space / 2))
            imageEdgeInsets = UIEdgeInsets(top: 0, left: (space / 2), bottom: 0, right: -(space / 2))
        } else {
            titleEdgeInsets = UIEdgeInsets(top: 0, left: space / 2, bottom: 0, right: -(space / 2))
            imageEdgeInsets = UIEdgeInsets(top: 0, left: -(space / 2), bottom: 0, right: space / 2)
        }
    }
    
}
