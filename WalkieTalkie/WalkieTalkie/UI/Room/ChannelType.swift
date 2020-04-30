//
//  ChannelType.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 2020/4/30.
//  Copyright © 2020 Guru Rain. All rights reserved.
//

import UIKit

enum ChannelType: Int {
    case `public`
    case `private`
}

extension ChannelType {
    var screenColor: UIColor {
        switch self {
        case .public:
            return UIColor(hex: 0xBFFF58)!
        case .private:
            return UIColor(hex: 0xFFC800)!
        }
    }
    
    var screenImage: UIImage? {
        switch self {
        case .public:
            return R.image.icon_screen_bg()
        case .private:
            return R.image.icon_screen_s_bg()
        }
    }
}
