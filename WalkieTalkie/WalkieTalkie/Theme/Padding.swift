//
//  Padding.swift
//  Castbox
//
//  Created by ChenDong on 2018/11/19.
//  Copyright © 2018 Guru. All rights reserved.
//

import UIKit
import SnapKit

// UI 元素之间的间距，规定了大部分情况的 margin 数值
enum Padding: CGFloat {
    case _3 = 3.0
    case _4 = 4.0
    case _5 = 5.0
    case _8 = 8.0
    case _10 = 10.0
    case _15 = 15.0
    case _16 = 16.0
    case _20 = 20.0
    case _25 = 25.0
    case _30 = 30.0
    
    // 普通cell的edges
    static let cellEdgeInsets = UIEdgeInsets(top: Padding._10.rawValue,
                                             left: Padding._15.rawValue,
                                             bottom: Padding._10.rawValue,
                                             right: Padding._15.rawValue)
    
    // discover cell的edges/ player的edges
    static let bigCellEdgeInsets = UIEdgeInsets(top: Padding._15.rawValue,
                                                     left: Padding._20.rawValue,
                                                     bottom: Padding._15.rawValue,
                                                     right: Padding._20.rawValue)
    
    // Listen cell的edges单独处理
    static let listenCellEdgeInsets = UIEdgeInsets(top: Padding._15.rawValue,
                                                   left: Padding._15.rawValue,
                                                   bottom: Padding._15.rawValue,
                                                   right: Padding._15.rawValue)
    
    // 分割线缩进
    static let separatorInsets = UIEdgeInsets(top: 0.0,
                                              left: Padding.cellEdgeInsets.left,
                                              bottom: 0.0,
                                              right: 0.0)
    
    // searchBar的缩进
    static let searchBarInsets = UIEdgeInsets(top: 0.0, left: -Padding._8.rawValue, bottom: 0.0, right: Padding._8.rawValue)
    
    // Subscription页面为了容纳小红点预留的Edges
    static let subscriptionEdgeInsets = UIEdgeInsets(top: 6.5, left: 6.5, bottom: 0.0, right: 6.5)
    
    static let playerFlexibleEdgeInsets = UIEdgeInsets(top: 6.0, left: 6.0, bottom: 6.0, right: 6.0)
    
    /* 容器和内容间的内边距, 比如评论的气泡和内容的内边距
            +---------------+
            |       |       |
            |  +---------+  |
            |--|         |  |
            |  +---------+  |
            |               |
            +---------------+
     */
    static let containerInsets = UIEdgeInsets(top: Padding._10.rawValue,
                                              left: Padding._10.rawValue,
                                              bottom: Padding._10.rawValue,
                                              right: Padding._10.rawValue)
    
    // 自定义导航条内边距
    static let navigationEdgeInsets = UIEdgeInsets(top: Padding._20.rawValue, left: Padding._20.rawValue, bottom: Padding._15.rawValue, right: Padding._20.rawValue)
    
    // 小红点到某个控件右上角的偏移量
    static let reddotOffset = CGPoint(x: -4, y: 4)
    
    // 图标和标题的水平间距
    static let imageTitleMarginH = Padding._15.rawValue
    // 图片和标题的纵向间距
    static let imageTitleMarginV = Padding._10.rawValue
    // icon和label水平间距，比如Date的icon和Date的文字中的间距
    static let imageLabelMarginH = Padding._5.rawValue
    
    /// 标题和标题配件的水平间距, 比如Discover页面的标题和更多按钮
    static let titleAccessoryMarginH = Padding._15.rawValue
    
    /**
     table样式标题和副标题的纵向间隔
     ```
            +---+  title
            |   |    |
            +---+  subtitle
     ```
     */
    static let tableTitleMarginV = Padding._10.rawValue
    
    /**
     评论样式描述和图片的纵向间隔
     ```
            +---+
            |   |   title
            +---+
              |
            description
     ```
     */
    static let commentTitleMarginV = Padding._10.rawValue
    
    /*
            +---+
            |   |
            +---+
              |1
            title
              |2
            subtitle
     */
    // 1. collection样式图片标题的纵向间隔
    static let collectionImageTitleMarginV = Padding._10.rawValue
    // 2. collection样式标题和副标题的纵向间隔
    static let collectionTitleMarginV = Padding._3.rawValue
    
    /* 标题和内容的纵向间隔, 比如Discover页面的各个cell标题和b内容间隔
        title
          |
        +------------------+
        |                  |
        |                  |
        +------------------+
     */
    static let titleMarginV = Padding._15.rawValue
    
    /*  头像和标题纵向间隔
     ---------------------
        +---+     |
        |   |   title
        +---+
     */
    static let avatarTitleOffsetV = Padding._5.rawValue
    
    // tableViewCell之间如果有间隔的话，他的纵向间隔
    static let tableCellMargin = Padding._15.rawValue
    
    // collectionViewCell之间如果有间隔的话，他的纵向间隔
    static let collectionCellMarginV = Padding._15.rawValue
    // collectionViewCell之间如果有间隔的话，他的横向间隔
    static let collectionCellMarginH = Padding._15.rawValue
    
    // 多个子控件在同一行时，他们的横向间隔, 尽量少用
    static let innerMarginH = Padding._15.rawValue
    // 多个子空间在同一列时，他们的纵向间隔, 尽量少用
    static let innerMarginV = Padding._15.rawValue
    
    // Alert左边右边间距
    static let alertMarginH = Padding._8.rawValue
    
    // Option按钮的offset
    static let optionOffset = CGPoint(x: -8.0, y: 8.0)

    // 底部按钮的offset, iPhoneX安全区域
    static let bottomOffset: CGFloat = {
        if #available(iOS 11.0, *) {
            if let offset = UIApplication.shared.keyWindow?.safeAreaInsets.bottom {
                return offset
            }
        }
        return 0.0
    }()
}

// Player页面
extension Padding {
    
    static var bottomPadding: CGFloat {
        switch UIScreen.main.bounds.width {
        case 0..<375.0:
            return 15.0
        default:
            return 30.0
        }
    }
    
    static var timerPadding: CGFloat {
        switch UIScreen.main.bounds.width {
        case 0..<375.0:
            return 40.0
        default:
            return 60.0
        }
    }
    
    static var panelPadding: CGFloat {
        switch UIScreen.main.bounds.width {
        case 0..<375.0:
            return 15.0
        default:
            return 30.0
        }
    }
}
