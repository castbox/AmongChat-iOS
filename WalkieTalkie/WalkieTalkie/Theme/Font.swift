//
//  Font.swift
//  Castbox
//
//  Created by ChenDong on 2018/11/15.
//  Copyright © 2018年 Guru. All rights reserved.
//

import UIKit

// MARK: - Font
struct Font {
    
    enum Size: CGFloat {
        case _44 = 44
        case _34 = 34
        case _24 = 24
        case _22 = 22
        case _20 = 20
        case _16 = 16
        case _13 = 13
        case _11 = 11
        
        case _10 = 10
        
        // 以下重构完就会弃用
        case _17 = 17
        case _14 = 14
        case _12 = 12
        case _15 = 15

        static let headline = Size._34
        static let title = Size._14
        static let body = Size._13
        static let info = Size._12
        static let actionBar = Size._15
    }
    
    enum Weight {
        case bold
        case semibold
        case regular
        case medium
        
        var rawValue: CGFloat {
            switch self {
            case .bold:
                return UIFont.Weight.bold.rawValue
            case .semibold:
                return UIFont.Weight.semibold.rawValue
            case .regular:
                return UIFont.Weight.regular.rawValue
            case .medium:
                return UIFont.Weight.medium.rawValue
            }
        }
    }
    
    let value: UIFont
    // 使用 fileprivate 限制是为了保证全部的 Font 都在这里集中管理
    fileprivate init(size: Size, weight: Weight) {
        self.value = UIFont.systemFont(ofSize: size.rawValue, weight: UIFont.Weight(rawValue: weight.rawValue))
    }
}

extension Font {
    
    static let bigTitle = Font(size: ._34, weight: .bold)
    static let title = Font(size: ._16, weight: .bold)
    static let boldTitle = Font(size: ._20, weight: .bold)
    static let littleTitle = Font(size: ._20, weight: .semibold)
    
    static let headline = Font(size: ._16, weight: .semibold)
    
    static let bigBody = Font(size: ._16, weight: .regular)
    static let body = Font(size: ._13, weight: .regular)
    static let semiBody = Font(size: ._13, weight: .semibold)
    
    static let caption = Font(size: ._11, weight: .regular)
    static let caption1 = Font(size: ._12, weight: .regular)
    static let tips = Font(size: ._11, weight: .semibold)
    
    static let mediumTitle = Font(size: ._11, weight: .medium)
    static let mediumBody = Font(size: ._13, weight: .medium)
    static let mediumBigTitle = Font(size: ._16, weight: .medium)
    
    static let smallBody = Font(size: ._10, weight: .regular)
    
    static let premiumSubscribeTry = Font(size: ._15, weight: .bold)
//    static let sleepActionTitle = Font(size: ._15, weight: .medium)
//    static let sleepTimerDesc = Font(size: ._15, weight: .regular)
//    static let sleepTimer = Font(size: ._44, weight: .bold)
}

// fixme，重构完即要弃用的
extension UIFont {
    static func theme(_ size: Font.Size, _ weight: Font.Weight = .regular) -> UIFont {
        return Font(size: size, weight: weight).value
    }
}
