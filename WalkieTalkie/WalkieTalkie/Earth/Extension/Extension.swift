//
//  Extension.swift
//  Castbox
//
//  Created by JL on 2017/4/28.
//  Copyright © 2017年 Guru. All rights reserved.
//

import UIKit
import RxSwift

var isRelease: Bool {
    #if RELEASE
    return true
    #else
    return false
    #endif
}

extension NSDictionary {
    func string(key: String) -> String {
        return self.value(forKey: key) as? String ?? ""
    }
    
    func numberString(key: String) -> String {
        return "\(self.value(forKey: key) as? NSNumber ?? 0)"
    }
}

extension Float {
    
    func timeString() -> String {
        
        let hours = Int(self) / 3600
        let minutes = (Int(self) / 60) % 60
        let seconds = Int(self) % 60
        
        var timeText = ""
        
        if hours > 0 {
            timeText += "\(hours):"
        }
        
        if minutes < 10 {
            timeText += "0"
        }
        timeText += "\(minutes):"
        
        if seconds < 10 {
            timeText += "0"
        }
        timeText += "\(seconds)"
        
        return timeText
    }
    
}


extension Double {
    var timeFormat:String {
        var durationText = "00:00"
        if self.isNaN || self <= 0 {
            return durationText
        }
        
        var duration = Int(self)
        
        let seconds = duration % 60
        
        duration /= 60
        let minutes = duration % 60
        
        duration /= 60
        let hours = duration
        if hours <= 0 {
            durationText = String(format: "%02d", minutes) + ":" + String(format: "%02d", seconds)
        } else {
            durationText = String(format: "%02d", hours) + ":" + String(format: "%02d", minutes) + ":" + String(format: "%02d", seconds)
        }
        
        return durationText
    }
}

extension Array {
    func nonnull<T>() -> [T] where Element == Optional<T> {
        return self.compactMap({ $0 })
    }
    
    @discardableResult
    mutating func appendElement(_ element: Element, ifNotExists filter: (Element) -> Bool) -> Element? {
        if contains(where: filter) == false {
            append(element)
            return element
        }
        return nil
    }
    
    @discardableResult
    mutating func removeElement(ifExists filter: (Element) -> Bool) -> Element? {
        if let index = firstIndex(where: filter) {
            return remove(at: index)
        }
        return nil
    }
}

extension Array {
    
    func first(_ k: Int) -> [Element] {
        if k < count {
            let range: Range<Int> = 0..<k
            return Array(self[range])
        } else {
            let range: Range<Int> = 0..<count
            return Array(self[range])
        }
    }
    
    func last(_ k: Int) -> [Element] {
        guard count > 0 else { return [] }
        guard count - k > 0 else { return self }
        if k < count {
            let range: Range<Int> = count - k..<count
            return Array(self[range])
        } else {
            let range: Range<Int> = count - 1..<count
            return Array(self[range])
        }
    }
}

extension Array {
    
    internal func safe(_ index: Int) -> Element? {
        if index >= 0, self.count > index {
            return self[index]
        } else {
            return nil
        }
    }
}


func P(_ items: Any...) {
    #if DEBUG
    debugPrint(items)
    #endif
}

extension Disposable {
    @discardableResult
    public func disposed(with com: CompositeDisposable) -> CompositeDisposable.DisposeKey? {
        return com.insert(self)
    }
}

