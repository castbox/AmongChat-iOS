//
//  JSBridge.PlayDuration.swift
//  Castbox
//
//  Created by lazy on 2018/9/29.
//  Copyright © 2018年 Guru. All rights reserved.
//

import Foundation
//import RxSwift
//import RxCocoa
//import SwiftyUserDefaults

//extension JSBridge {
//
//    class Support {
//
//        public static let shared = Support()
//
//        private let bag = DisposeBag()
//
//        var elapsedTime: Int64 {
//
//            let startTimestamp = Defaults[.startTimeKey]
//
//            let now = Int64(CFAbsoluteTimeGetCurrent() * 1000)
//            if !startTimestamp.isSameDay(other: now, hourOffset: 2) {
//                Defaults[.elapsedTimeKey] = 0
//            }
//
//            return Defaults[.elapsedTimeKey]
//        }
//
//        func startPlaying() {
//            // 1. 取出UserDefaults中的startTimestamp
//            let startTimestamp = Defaults[.startTimeKey]
//
//            // 2. 判断新旧startTimestamp, 如果新旧startTimestamp不是同一天(以凌晨2点计算)，重置value
//            let now = Int64(CFAbsoluteTimeGetCurrent() * 1000)
//            if !startTimestamp.isSameDay(other: now, hourOffset: 2) {
//                Defaults[.elapsedTimeKey] = 0
//            }
//
//            // 3. 更新UserDefaults中的startTimestamp
//            Defaults[.startTimeKey] = now
//        }
//
//        func stopPlaying() {
//            // 1. 取出UserDefaults中的startTimestamp
//            let startTimestamp = Defaults[.startTimeKey]
//
//            // 2. 判断startTimestamp和当前时间戳, 如果不是同一天(以凌晨2点计算), 重置value, 从凌晨2点开始计算播放时间
//            let now = Int64(CFAbsoluteTimeGetCurrent() * 1000)
//            var elapsedTime: Int64 = 0
//            if !startTimestamp.isSameDay(other: now, hourOffset: 2) {
//
//                Defaults[.elapsedTimeKey] = 0
//
//                if let locationDate = createDate(hour: 2) {
//                    let locationTimestamp = Int64(locationDate.timeIntervalSince1970 * 1000)
//                    elapsedTime = now - locationTimestamp
//                }
//            } else {
//                elapsedTime = now - startTimestamp
//            }
//
//            // 3. 更新UserDefauls中的value
//            let cachedElapsedTime = Defaults[.elapsedTimeKey]
//            Defaults[.elapsedTimeKey] = elapsedTime + cachedElapsedTime
//        }
//
//        init() {
//            weak var welf = self
//            NotificationCenter.default.rx
//                .notification(UIApplication.willTerminateNotification)
//                .subscribe(onNext: { (_) in
//                    guard let `self` = welf else { return }
//                    self.stopPlaying()
//                })
//                .disposed(by: bag)
//        }
//
//        // 创建基于当前时间 hour点的Date
//        private func createDate(hour: Int) -> Date? {
//            var com = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: Date())
//            com.hour = hour
//            com.minute = 0
//            com.second = 0
//            return Calendar.current.date(from: com)
//        }
//    }
//}
//
//extension DefaultsKeys {
//
//    static let elapsedTimeKey = DefaultsKey<Int64>("elapsedTimeKey")
//
//    static let startTimeKey = DefaultsKey<Int64>("startTimeKey")
//}
//
//extension UserDefaults {
//
//    subscript(key: DefaultsKey<Int64>) -> Int64 {
//        get {
//            return numberForKey(key._key)?.int64Value ?? 0
//        }
//        set {
//            set(key, NSNumber(value: newValue))
//        }
//    }
//}
//
//extension String {
//
//    func entryptionValue(_ saltingLength: Int = 4) -> String? {
//
//        func random(_ length: Int) -> String {
//            let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
//            let randomCharacters = (0..<length).compactMap { _ in characters.randomElement() }
//            return String(randomCharacters)
//        }
//
//        guard var entryptedString = self.data(using: .utf8)?.base64EncodedString() else { return nil }
//        // 移除base64加密后自动填充的'=', 增强保密性
//        entryptedString.removeLast(where: { $0 == "=" })
//
//        return "\(random(saltingLength))\(entryptedString)\(random(saltingLength))"
//    }
//
//    mutating func removeLast(where transform: (Character) -> (Bool)) {
//        var flag: Int = 1
//        while !self.suffix(flag).contains(where: { !transform($0) }) && flag <= count {
//            flag += 1
//        }
//        flag -= 1
//        self.removeLast(flag)
//    }
//}
//
//extension Int64 {
//
//    func isSameDay(other timestamp: Int64, hourOffset: Int) -> Bool {
//        let date1 = Date(timeIntervalSinceReferenceDate: TimeInterval(self) / 1000.0)
//        let date2 = Date(timeIntervalSinceReferenceDate: TimeInterval(timestamp) / 1000.0)
//
//        // 判断同时偏移一个hour后是否是同一天
//        guard let offsetDate1 = Calendar.current.date(byAdding: DateComponents(hour: -hourOffset), to: date1), let offsetDate2 = Calendar.current.date(byAdding: DateComponents(hour: -hourOffset), to: date2) else { return false }
//
//        return Calendar.current.isDate(offsetDate1, inSameDayAs: offsetDate2)
//    }
//}
