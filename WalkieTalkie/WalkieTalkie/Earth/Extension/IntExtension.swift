//
//  IntExtension.swift
//  Castbox
//
//  Created by ChenDong on 2017/8/15.
//  Copyright © 2017年 Guru. All rights reserved.
//

import UIKit

extension String {
    
    var intValue: Int {
        return int ?? 0
    }

    var int32: Int32? {
        return int?.int32
    }

    var uInt32: UInt32? {
        return int?.uInt32
    }

    var int64: Int64? {
        return int?.int64
    }
    
    var int64Value: Int64 {
        return int?.int64 ?? 0
    }
    
    var uIntValue: UInt {
        return intValue.uInt
    }

    var numberValue: NSNumber? {
        return intValue.numberValue
    }
}

extension Int {
    var string: String {
        return String(self)
    }
    var int32: Int32 {
        return Int32(self)
    }
    
    var uInt32: UInt32 {
        return UInt32(self)
    }
    
    var int64: Int64 {
        return Int64(self)
    }
    
    var numberValue: NSNumber {
        return NSNumber(value: self)
    }
    /// 返回根据屏幕缩放后的尺寸
    var scalValue: CGFloat {
        let scal = UIScreen.main.bounds.size.width / 375.0
        return scal * CGFloat(self)
    }
    /// 返回根据屏幕缩放后的尺寸
    var scalHValue: CGFloat {
        let scal = UIScreen.main.bounds.size.height / 667.0
        return scal * CGFloat(self)
    }
}

extension Double {

    /// Int64.
    var int64: Int64 {
        return Int64(self)
    }
}

extension UInt {
    var string: String {
        return String(self)
    }
    
    var int: Int {
        return Int(self)
    }
    
    var int32: Int32 {
        return Int32(self)
    }
    
    var uInt32: UInt32 {
        return UInt32(self)
    }
    
    var int64: Int64 {
        return Int64(self)
    }
    
    var numberValue: NSNumber {
        return NSNumber(value: self)
    }
}

extension Int64 {
    var string: String {
        return String(self)
    }
    
    var cgFloat: CGFloat {
        return CGFloat(self)
    }
    
    var numberValue: NSNumber {
        return NSNumber(value: self)
    }
}

extension Int32 {
    var int: Int {
        return Int(self)
    }
    
    var string: String {
        return String(self)
    }

}

extension UInt32 {
    var int: Int {
        return Int(self)
    }
    
    var string: String {
        return String(self)
    }

}

extension Optional where Wrapped == Int {
    
    var stringValue: String {
        switch self {
        case .some(let num):
            return String(num)
        default:
            return ""
        }
    }
}
// MARK: -  ps: height = 15.0.scalValue
public extension Double {
    /// 返回根据屏幕缩放后的尺寸
    var scalValue: CGFloat {
        let scal = UIScreen.main.bounds.size.width / 375.0
        return scal * CGFloat(self)
    }
}

// MARK: -  ps: height = 15.0.scalValue
public extension CGFloat {
    /// 返回根据屏幕缩放后的尺寸
    var scalValue: CGFloat {
        let scal = UIScreen.main.bounds.size.width / 375.0
        return scal * CGFloat(native)
    }
}
extension Double {
    
    func getTwoFloat() -> String {
        let d = self
        return String(format: "%.2f", d)
    }
    
}
extension Float {
    
    func getTwoFloat() -> String {
        let d = self
        return String(format: "%.2f", d)
    }
}

extension Int {
    
    var secondsAsHHMMSS: String {
       let seconds: Int = self % 60
       let minutes: Int = (self / 60) % 60
       let hours: Int = self / 3600
       return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
}

extension Int {
    
    var isSelfUid: Bool {
        guard let loggedInProfile = Settings.shared.amongChatUserProfile.value else {
            return false
        }
        
        return self == loggedInProfile.uid
    }
    
}
