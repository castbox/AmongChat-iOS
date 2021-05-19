//
//  Constellation.swift
//  WalkieTalkie
//
//  Created by 袁仕崇 on 19/05/21.
//  Copyright © 2021 Guru Rain. All rights reserved.
//

import UIKit

extension Date {
    /**
     通过日期获取星座
     - parameter date: 日期
     - returns: 星座名称
     */
    func constellation() -> Constellation? {
        let date = self
        guard let calendar = NSCalendar(identifier: NSCalendar.Identifier.gregorian) else {
            return nil
        }
        let components = calendar.components([.month, .day], from: date)
        let month = components.month!
        let day = components.day!
        
        
        // 月以100倍之月作为一个数字计算出来
        let mmdd = month * 100 + day;
        var result: Constellation?
        
        if ((mmdd >= 321 && mmdd <= 331) ||
            (mmdd >= 401 && mmdd <= 420)) {
            result = .aries
        } else if ((mmdd >= 421 && mmdd <= 430) ||
            (mmdd >= 501 && mmdd <= 521)) {
            result = .taurus
        } else if ((mmdd >= 522 && mmdd <= 531) ||
            (mmdd >= 601 && mmdd <= 621)) {
            result = .gemini
        } else if ((mmdd >= 622 && mmdd <= 630) ||
            (mmdd >= 701 && mmdd <= 723)) {
            result = .cancer
        } else if ((mmdd >= 724 && mmdd <= 731) ||
            (mmdd >= 801 && mmdd <= 823)) {
            result = .leo
        } else if ((mmdd >= 824 && mmdd <= 831) ||
            (mmdd >= 901 && mmdd <= 923)) {
            result = .virgo
        } else if ((mmdd >= 924 && mmdd <= 930) ||
            (mmdd >= 1001 && mmdd <= 1023)) {
            result = .libra
        } else if ((mmdd >= 1024 && mmdd <= 1031) ||
            (mmdd >= 1101 && mmdd <= 1122)) {
            result = .scorpio
        } else if ((mmdd >= 1123 && mmdd <= 1130) ||
            (mmdd >= 1201 && mmdd <= 1222)) {
            result = .sagittarius
        } else if ((mmdd >= 1223 && mmdd <= 1231) ||
            (mmdd >= 101 && mmdd <= 119)) {
            result = .capricorn
        } else if ((mmdd >= 121 && mmdd <= 131) ||
            (mmdd >= 201 && mmdd <= 218)) {
            result = .aquarius
        } else if ((mmdd >= 219 && mmdd <= 229) ||
            (mmdd >= 301 && mmdd <= 320)) {
            //考虑到2月闰年有29天的
            result = .pisces
        }
        return result
    }
}
