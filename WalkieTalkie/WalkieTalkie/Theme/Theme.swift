//
//  Theme.Color.swift
//  Castbox
//
//  Created by ChenDong on 2018/11/15.
//  Copyright © 2018年 Guru. All rights reserved.
//

import UIKit
import UIColor_Hex_Swift
import SwiftyUserDefaults

public struct Theme { }

protocol ThemeBase {
    
    
}

extension Theme {
    // 主题枚举
    enum Mode: Int, Codable {
        // 白色主题
        case light = 0
        // 黑色主题
        case dark
    }
}

// 所以主题颜色的枚举
extension Theme {
    static let mainBgColor = UIColor(hex6: 0x161616)
    
    static let mainTintColor = UIColor(hex6: 0xF55B23)
    
    static let mainPanelColor = UIColor(hex6: 0x28282A)
    
    static let alertTitleColor = UIColor.white.withAlphaComponent(0.87)
    static let alertBodyColor = UIColor(hex6: 0xFB9448).withAlphaComponent(0.87)
    static let alertInfoColor = UIColor.white.withAlphaComponent(0.54)
    
    static let cellTitleColor = UIColor.white.withAlphaComponent(0.87)
    static let cellBodyColor = UIColor.white.withAlphaComponent(0.54)
    static let cellFooterColor = UIColor.white.withAlphaComponent(0.32)
    
    static let panelBtnNormalColor = UIColor.white.withAlphaComponent(0.7)
    
    static let hintYellow = UIColor(hex6: 0xFFC371)

    
    enum Alpha: CGFloat {
        case almostTransparent = 0.18
        case translucence = 0.5
        case nearlyOpaque = 0.75
    }
    
    enum Color {
        case main
        case yellow
        case red
        
        case highlight // 搜索高亮
        case tagBlue // tag高亮的背景色
        case gray // 大部分按钮的tineColor
        
        case translucenceBlack // Player页面半透明黑色
        case translucenceWhite // Player页面半透明白色
        
        case backgroundWhite
        case backgroundGray
        case backgroundBlack
        case backgroundBlackAlpha(CGFloat)
        
        case contentWhite
        case contentBlack
        
        case textBlack
        case textBlackAlpha(CGFloat)
        case textWhite
        case textWhiteAlpha(CGFloat)
        
        case textGray
        case textLightGray
        
        case lineWhite
        case lineBlack
        
        case separatorLight
        case separatorDark
        
        case placeholderLight
        case placeholderDark
        
        case highlightLight
        case highlightDark
        
        case backgroundLightGray
        
        case alertTitle
        case alertDetail
        case starNumColor
        
        case maleColor
        case femaleColor
        case pkBackgroudColor
        case textBlue //notification header view title
        
        var value: UIColor {
            switch self {
            case .main:
                return UIColor(hex6: 0xFFD52E)
            case .yellow:
                return UIColor(hex6: 0xFFD009)
            case .red:
                return UIColor(hex6: 0xFB5858)
                
            case .gray:
                return UIColor(hex6: 0x8E8E93)
            case .starNumColor:
                return UIColor(hex6: 0x00C9CA)
            // 用于 app 内的背景色，经常用于 UIViewController.view, UITableView, UITableViewCell, UICollectionView, UICollectionCell, UIScrollView
            case .backgroundWhite:
                return UIColor(hex6: 0xFFFFFF)
            case .backgroundGray:
                return UIColor(hex6: 0xF7F7F7)
            case .backgroundBlack:
                return UIColor(hex6: 0x121212)
            case .backgroundBlackAlpha(let alpha):
                return UIColor(hex6: 0x000000, alpha: alpha)
                
            // 用于 app 内的内容背景色，目的在于与背景色区别开来。比如 UIImageView，UISearchBar，UITextField 的背景色
            case .contentWhite:
                return UIColor(hex6: 0xEEEEEE)
            case .contentBlack:
                return UIColor(hex6: 0x353535)
                
            // 用于 app 内的文本颜色
            case .textGray:
                return UIColor(hex6: 0x4A4A4A)
            case .textLightGray:
                return UIColor(hex6: 0xB2B2B2)
            case .textWhite:
                return UIColor(hex6: 0xFFFFFF)
            case .textWhiteAlpha(let alpha):
                return UIColor(hex6: 0xFFFFFF, alpha: alpha)
            case .textBlack:
                return UIColor(hex6: 0x000000)
            case .textBlackAlpha(let alpha):
                return UIColor(hex6: 0x000000, alpha: alpha)
                
            // 用于 app 内的分割线
            case .lineWhite:
                return UIColor(hex6: 0xEFEFF4)
            case .lineBlack:
                return UIColor(hex6: 0x2B2B2B)
                
            // 新版分割线
            case .separatorLight:
                return UIColor(hex6: 0xEFEFF4)
            case .separatorDark:
                return UIColor(hex6: 0x3F3F3F)
                
            // 占位图颜色
            case .placeholderLight:
                return UIColor(hex6: 0xcbcbcb)
            case .placeholderDark:
                return UIColor(hex6: 0x666666)
                
            case .highlightLight:
                return UIColor(hex6: 0xF1F1F2)
            case .highlightDark:
                return UIColor(hex6: 0x28282A)
                
            case .highlight:
                return UIColor(hex6: 0xFFC47B)
            case .translucenceBlack:
                return UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.3)
            case .translucenceWhite:
                return UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.25)
            case .tagBlue:
                return UIColor(hex6: 0x4AAFE3)
            case .backgroundLightGray:
                return UIColor(hex6: 0xF8F8F8)
            case .alertTitle:
                return UIColor(hex6: 0x030303)
            case .alertDetail:
                return UIColor(hex6: 0x030303, alpha: 0.54)
            case .maleColor:
                return UIColor(hex6: 0x536BF5)
            case .femaleColor:
                return UIColor(hex6: 0xe3619f)
            case .pkBackgroudColor:
                return UIColor(hex6: 0x272729)
            case .textBlue:
                return UIColor(hex6: 0x0076FF)
            }
        }
    }
}

extension Theme.Color {
    
    func counterpart(in mode: Theme.Mode) -> Theme.Color {
        
        var ret = self
        
        switch mode {
        case .light:
            return self
        case .dark:
            switch self {
            case .backgroundWhite:
                ret = .backgroundBlack
            case .contentWhite:
                ret = .contentBlack
            case .textBlack:
                ret = .textWhite
            case .textWhite:
                ret = .textBlack
            case .lineWhite:
                ret = .lineBlack
            case .separatorLight:
                ret = .separatorDark
            case .placeholderLight:
                ret = .placeholderDark
            case .highlightLight:
                ret = .highlightDark
            default:
                break
            }
        }
        return ret
    }
}

extension UIColor {
    class func theme(_ color: Theme.Color) -> UIColor {
        return color.value
    }
    
    func alpha(_ alpha: Theme.Alpha) -> UIColor {
        var red: CGFloat = -1.0
        var green: CGFloat = -1.0
        var blue: CGFloat = -1.0
        getRed(&red, green: &green, blue: &blue, alpha: nil)
        guard red >= 0.0, green >= 0.0, blue >= 0.0 else { return self }
        return UIColor(red: red, green: green, blue: blue, alpha: alpha.rawValue)
    }
    
    func alpha(_ value: CGFloat) -> UIColor {
        var red: CGFloat = -1.0
        var green: CGFloat = -1.0
        var blue: CGFloat = -1.0
        getRed(&red, green: &green, blue: &blue, alpha: nil)
        guard red >= 0.0, green >= 0.0, blue >= 0.0 else { return self }
        return UIColor(red: red, green: green, blue: blue, alpha: value)
    }
}


// MARK: - Theme Compatible
public struct ThemeHelper<Base> {
    public let base: Base
    public init(_ base: Base) {
        self.base = base
    }
}
protocol ThemeCompatible {}
extension ThemeCompatible {
    var theme: ThemeHelper<Self> {
        return ThemeHelper(self)
    }
}


extension Theme.Mode: DefaultsSerializable {
    static var _defaults: ThemeModeBridge { return ThemeModeBridge() }
    static var _defaultsArray: ThemeModeBridge { return ThemeModeBridge() }
}

class ThemeModeBridge: DefaultsBridge {
    func deserialize(_ object: Any) -> Theme.Mode? {
        guard let value = object as? Int else {
            return nil
        }
        return Theme.Mode(rawValue: value)
    }
    
    func save(key: String, value: Theme.Mode?, userDefaults: UserDefaults) {
        userDefaults.set(value?.rawValue, forKey: key)
    }
    
    func get(key: String, userDefaults: UserDefaults) -> Theme.Mode? {
        return Theme.Mode(rawValue: userDefaults.integer(forKey: key))
    }
}
