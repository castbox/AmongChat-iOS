//
//  Size.swift
//  Castbox
//
//  Created by lazy on 2018/11/26.
//  Copyright © 2018年 Guru. All rights reserved.
//

import Foundation
import SnapKit

enum Size: CGFloat {
    
    case _2 = 2.0
    case _10 = 10.0
    case _11 = 11.0
    case _16 = 16.0
    case _18 = 18.0
    case _24 = 24.0
    case _25 = 25.0
    case _28 = 28.0
    case _31 = 31.0
    case _32 = 32.0
    case _35 = 35.0
    case _36 = 36.0
    case _44 = 44.0
    case _48 = 48.0
    case _49 = 49.0
    case _50 = 50.0
    case _51 = 51.0
    case _55 = 55.0
    case _64 = 64.0
    case _75 = 75.0
    case _90 = 90.0
    case _100 = 100.0
    
    /*
        基础控件尺寸
     */
    /// cell 大图的尺寸
    static let cellBigCoverSize = CGSize(width: Size._100.rawValue, height: Size._100.rawValue)
    /// cell 小图的尺寸
    static let cellSmallCoverSize = CGSize(width: Size._64.rawValue, height: Size._64.rawValue)
    /// cell 小小图尺寸
    static let cellTinyCoverSize = CGSize(width: Size._48.rawValue, height: Size._48.rawValue)
    /// cell 极小图尺寸
    static let cellMicroCoverSize = CGSize(width: Size._36.rawValue, height: Size._36.rawValue)
    /// cell icon的尺寸, 用来示意cell的功能, 比如Profile页面cell前面的小图片
    static let cellIconSize = CGSize(width: Size._25.rawValue, height: Size._25.rawValue)
    /// 能交互的图标的尺寸，比如cell播放，cell下载，评论按钮
    static let interactiveSize = CGSize(width: Size._28.rawValue, height: Size._28.rawValue)
    /// Listen页Play 按钮的尺寸
    static let playButtonSize = CGSize(width: Size._36.rawValue, height: Size._36.rawValue)
    /// label 前方icon的尺寸
    static let labelIconSize = CGSize(width: Size._11.rawValue, height: Size._11.rawValue)
    /// 头像的尺寸
    static let avatarSize = CGSize(width: Size._48.rawValue, height: Size._48.rawValue)
    /// 评论中的头像的尺寸
    static let commentAvatarSize = CGSize(width: Size._32.rawValue, height: Size._32.rawValue)
    /// 头像小图尺寸
    static let smallAvatarSize = CGSize(width: Size._24.rawValue, height: Size._24.rawValue)
    /// 开关的尺寸
    static let switcherSize = CGSize(width: Size._48.rawValue, height: Size._31.rawValue)
    /// nextup中正在播放indicator尺寸
    static let indicatorSize = CGSize(width: Size._2.rawValue, height: Size._48.rawValue)
    /// 无文字小红点尺寸
    static let reddotSize = CGSize(width: Size._16.rawValue, height: Size._16.rawValue)
    /// 有文字小红点尺寸
    static let badgeSize = CGSize(width: Size._24.rawValue, height: Size._24.rawValue)
    /// option选择框size
    static let optionSize = CGSize(width: Size._18.rawValue, height: Size._18.rawValue)
    /// MBProgress loading indicator尺寸
    static let loadingSize = CGSize(width: Size._18.rawValue, height: Size._18.rawValue)
    /// shortcut 加号
    static let shortcutsdAddSize = CGSize(width: Size._10.rawValue, height: Size._10.rawValue)
    
    /*
        基础控件高度
     */
    /// 底部按钮高度
    static let bottomButtonHeight = Size._49.rawValue + Padding.bottomOffset
    /// textField高度
    static let textFieldHeight = Size._55.rawValue
    /// 键盘上方toolBar高度
    static let keyboardBarHeight = Size._36.rawValue
    /// toolBar高度
    static let toolbarHeight = Size._50.rawValue
    /// tableView的section header 高度
    static let sectionHeaderHeight = Size._24.rawValue
    /// 标准的button的高度
    static let buttonHeight = Size._35.rawValue
    /// 分割线留白
    static let separatorHeight = Size._10.rawValue
    /// 顶部bar高度 比如searchBar 高度
    static let topBarHeight = Size._44.rawValue
    /// Pop View 的 Cell 高度
    static let popCellHeight = Size._49.rawValue
    /// Alert cell height
    static let AlertCellHeight = Size._55.rawValue
    /// Episode/Channel cell的高度
    static let resourceCellHeight = Size._90.rawValue
    
    /*
        cell高度
     */
    // 只有Label的cell的高度, 比如设置页选择国家cell
    static let singleTextCellHeight = Size._55.rawValue
}

extension Size {
    
    static var topLayoutHeight: CGFloat {
        return Size._44.rawValue + UIApplication.shared.statusBarFrame.height
    }
}

// Player 页面
extension Size {
    
    // FixibleButton 尺寸
    static let playerFlexibleSize: CGSize = CGSize(width: Size._90.rawValue, height: Size._50.rawValue)
//    {
//        switch UIScreen.main.bounds.width {
//        case 0..<375.0:
//            return CGSize(width: Size._64.rawValue, height: Size._35.rawValue)
//        default:
//            return CGSize(width: Size._90.rawValue, height: Size._50.rawValue)
//        }
//    }
    // player cover尺寸, 进入Player页面第一眼看到的就是Cover，所以要针对不同的屏幕适配最合适的cover尺寸，用比例来做一来不准确，二来会不可避免的产生小数，导致像素不对齐，所以在这块使用枚举，有新的屏幕尺寸记得在这块添加
    // 如果有更好的方法欢迎替换
    static var playerCoverSize: CGSize {
        switch (UIScreen.main.bounds.width, UIScreen.main.bounds.height) {
        case (320.0, 480.0): // iPhone 4, 5
            return CGSize(width: 150.0, height: 150.0)
        case (375.0, 667.0): // iPhone 6, 7, 8
            return CGSize(width: 224.0, height: 224.0)
        case (414.0, 736.0): // iPhone 6, 7, 8 plus
            return CGSize(width: 293.0, height: 293.0)
        case (375.0, 812.0), (414.0, 896.0): // iPhoneX, XR, XS, Max
            let width = UIScreen.main.bounds.width - Padding.bigCellEdgeInsets.left - Padding.bigCellEdgeInsets.right
            return CGSize(width: width, height: width)
        default:
            let width = 448.0 * 0.5 * UIScreen.main.bounds.width / 375.0
            return CGSize(width: width, height: width)
        }
    }
    
    // player 播放按钮尺寸
    static var playerPlaySize: CGSize {
        switch UIScreen.main.bounds.width {
        case 0.0..<375.0:
            return CGSize(width: 60.0, height: 60.0)
        default:
            return CGSize(width: 80.0, height: 80.0)
        }
    }
    
    static var playerOperatorSize: CGSize {
        switch UIScreen.main.bounds.width {
        case 0.0..<375.0:
            return CGSize(width: UIScreen.main.bounds.width, height: 160.0)
        default:
            return CGSize(width: UIScreen.main.bounds.width, height: 205.0)
        }
    }
}


// MARK: - 小睡眠界面专用尺寸
extension Size {
    
    /// 选择面板图标直径
    static let boardCellImageDiam: CGFloat = 36
    
    static let boardLabelSize = CGSize(width: 74, height: 24)
    
    static let bannerButtonNormalRange: ClosedRange<CGFloat> = 36.0...40.0
    static let bannerButtonSelectedRange: ClosedRange<CGFloat> = 44.0...64.0
    
    
    /// 顶部返回按钮的大小
    static let bannerBackSize = CGSize(width: 28, height: 28)
}
