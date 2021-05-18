//
//  Globe.swift
//  Castbox
//
//  Created by ChenDong on 2018/2/26.
//  Copyright © 2018年 Guru. All rights reserved.
//

import UIKit
//import CastboxNetwork
//import CastboxDebuger
#if DEBUG
import DoraemonKit
#endif

/// 保证只在测试环境下才进行打印
public func cdPrint(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    #if DEBUG
    let isMain = Thread.isMainThread ? "main": "non-main"
    print("CUDDLE:\(isMain): ", terminator: "")
    for item in items {
        print(item, terminator: " ")
    }
    print("", terminator: terminator)
        
    for item in items {
        guard let string = item as? CustomStringConvertible else {
            return
        }
        DoraemonNSLogManager.sharedInstance()?.addNSLog(string.description)
    }
    #else
//    CocoaDebug.enable()
//    for item in items {
//        guard let string = item as? CustomStringConvertible else {
//            return
//        }
//        swiftLog(string.description, UIColor.green)
//        cocoaPrint(string.description)
//    }
    #endif
    
}

/// 在测试时可以显性提醒开发者错误信息
public func cdAssertFailure(_ message: String) {
    #if DEBUG
        assertionFailure(message)
    #endif
}


/// 把依赖 Castbox... pod 的类型通过这种方式暴露出来
/// https://stackoverflow.com/questions/33460330/how-to-import-a-swift-framework-globally/34595829?utm_medium=organic&utm_source=google_rich_qa&utm_campaign=google_rich_qa
//typealias Entity = CastboxNetwork.Entity
//typealias Request = CastboxNetwork.Request
//typealias Drive = CastboxNetwork.Drive
//typealias Network = CastboxNetwork.Network
//typealias ConsecutiveRequest = CastboxNetwork.ConsecutiveRequest
//typealias ConsecutiveEvent = CastboxNetwork.ConsecutiveEvent
//typealias DataError = CastboxNetwork.DataError
////typealias Repos = CastboxNetwork.Repos
//typealias Debug = CastboxDebuger.Debug
typealias CallBack = () -> Void

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

func mainQueueDispatchAsync(after: Double = 0, execute: @escaping (() -> Void)) {
    let mainQueue = DispatchQueue.main
    if after == 0 {
        if Thread.isMainThread {
            execute()
        }
        else {
            mainQueue.async(execute: execute)
        }
    }
    else {
        mainQueue.asyncAfter(deadline: .now() + after, execute: execute)
    }
}

func dispatchGlobalAsync(block: @escaping () -> Void) {
    DispatchQueue.global(qos: .default).async(execute: block)
}

extension UIView {
    static func springAnimate(duration: TimeInterval = 0.25,
                              delay: TimeInterval = 0,
                              usingSpringWithDamping dampingRatio: CGFloat = 0.8,
                              initialSpringVelocity velocity: CGFloat = 0.8,
                              options: UIView.AnimationOptions = [.beginFromCurrentState, .curveEaseIn],
                              animation: @escaping () -> Void,
                              completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: duration,
                       delay: delay,
                       usingSpringWithDamping: dampingRatio,
                       initialSpringVelocity: velocity,
                       options: options,
                       animations: animation,
                       completion: completion)
    }
}

/// 比较版本大小，返回是否需要更新
///
/// - Parameters:
///   - v1: 版本1- 新版本
///   - v2: 版本2- 当前版本
/// - Returns: true：v1>v2    false:v1<=v2
func compareAppVersions(v1: String, v2: String) -> Bool {
    if v1.isEmpty && v2.isEmpty || v1.isEmpty{
        return false
    }
    
    if v2.isEmpty {
        return true
    }
    
    let arry1 = v1.components(separatedBy: ".")
    let arry2 = v2.components(separatedBy: ".")
    //取count少的
    let minCount = arry1.count > arry2.count ? arry2.count : arry1.count
    
    var value1:Int = 0
    var value2:Int = 0
    
    for i in 0..<minCount {
        if !isPurnInt(string: arry1[i]) || !isPurnInt(string: arry2[i]){
            return false
        }
       
        value1 = Int(arry1[i])!
        value2 = Int(arry2[i])!
      
        // v1版本字段大于v2版本字段
        if value1 > value2 {
           // v1版本字段大于v2版本字段
           return true
        }else if value1 < value2{
           // v1版本字段小于v2版本字段
           return false
        }
        // v1版本=v2版本字段  继续循环
        
    }
    
    //字段多的版本高于字段少的版本
    if arry1.count > arry2.count {
        return true
    }else if arry1.count <= arry2.count {
        return false
    }
    
    return false
}

/// 判断是否是数字
///
/// - Parameter string: <#string description#>
/// - Returns: <#return value description#>
func isPurnInt(string: String) -> Bool {
    let scan: Scanner = Scanner(string: string)
    var val:Int = 0
    return scan.scanInt(&val) && scan.isAtEnd
}
