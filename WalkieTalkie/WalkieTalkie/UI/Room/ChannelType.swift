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
    
    func screenImage(with isConnected: Bool) -> UIImage? {
        switch self {
        case .public:
            return isConnected ? R.image.icon_screen_bg_g() : R.image.icon_screen_bg_g_d_pdf()
        case .private:
            return isConnected ? R.image.icon_screen_bg_o() : R.image.icon_screen_bg_o_d()
        }
    }
    
    func screenInnerShadowImage(with isConnected: Bool, isShowSearchView: Bool = false) -> UIImage? {
        switch self {
        case .public:
            return isConnected ? (isShowSearchView ? R.image.icon_screen_bg_g_shadow_round() : R.image.icon_screen_bg_g_shadow()) : nil
        case .private:
            return isConnected ? (isShowSearchView ? R.image.icon_screen_bg_o_shadow_round() : R.image.icon_screen_bg_o_shadow()) : nil
        }
    }
}
