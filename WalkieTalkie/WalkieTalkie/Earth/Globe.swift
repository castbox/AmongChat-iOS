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
import CocoaDebug
#endif

/// 保证只在测试环境下才进行打印
public func cdPrint(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    func cocoaPrint<T>(file: String = #file, function: String = #function, line: Int = #line, _ message: T, color: UIColor = .white) {
        #if DEBUG
            swiftLog(file, function, line, message, color, false)
        #endif
    }
    
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
        cocoaPrint(string.description)
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
