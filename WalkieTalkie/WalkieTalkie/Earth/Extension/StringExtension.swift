//
//  StringExtension.swift
//  Castbox
//
//  Created by JL on 2017/5/13.
//  Copyright © 2017年 Guru. All rights reserved.
//

import UIKit
import UIColor_Hex_Swift
//import GuruExtensions
import RxSwift

public extension String {
    
    func color() -> UIColor {
        if self.hasPrefix("#") {
            return UIColor(self)
        } else {
            return UIColor("#\(self)")
        }
    }
    
//    var md5: String {
//        guard let data = self.data(using: .utf8) else {
//            return self
//        }
//        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
//        _ = data.withUnsafeBytes { bytes in
//            return CC_MD5(bytes, CC_LONG(data.count), &digest)
//        }
//
//        return digest.map { String(format: "%02x", $0) }.joined()
//    }
    
    var nsstring: NSString {
        return NSString(string: self)
    }
}

extension String {
    
    func substring(with pattern: String) -> [String] {
        
        do {
            let text = self as NSString
            let exp = try NSRegularExpression(pattern: pattern, options: [])
            let results = exp.matches(in: self, options: [], range: NSMakeRange(0, text.length))
            return results
                .map({ $0.range })
                .compactMap({ (range) -> String? in
                    guard range.location + range.length <= text.length else { return nil }
                    return text.substring(with: range)
                })
        } catch let _ {
            return []
        }
    }
}

extension String {
    
    func heightWithConstrainedWidth(width: CGFloat, attributes: [NSAttributedString.Key: Any]) -> CGFloat {
        let constraintRect = CGSize(width: width, height: 999999)
        let boundingBox = self.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: attributes, context: nil)
        return boundingBox.height
    }
    
    func heightWithConstrainedWidth(width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: 999999)
        let boundingBox = self.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        return boundingBox.height
    }
    
//    func convert(textColor: UIColor, font: UIFont) -> UIImage? {
//        
//        let size = self.size(withAttributes: [NSAttributedString.Key.font: font.value])
//        
//        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
//        let context = UIGraphicsGetCurrentContext()
//        defer {
//            UIGraphicsEndImageContext()
//        }
//        
//        self.draw(in: CGRect(origin: .zero, size: size),
//                  withAttributes: [NSAttributedString.Key.foregroundColor: textColor,
//                                   NSAttributedString.Key.font: font.value])
//        
//        return UIGraphicsGetImageFromCurrentImageContext()
//    }
    
    func boundingRect(with constrainedSize: CGSize, font: UIFont, lineSpacing: CGFloat? = nil) -> CGSize {
        let attritube = NSMutableAttributedString(string: self)
        let range = NSRange(location: 0, length: attritube.length)
        attritube.addAttributes([NSAttributedString.Key.font: font], range: range)
        if lineSpacing != nil {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = lineSpacing!
            attritube.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: range)
        }
        
        let rect = attritube.boundingRect(with: constrainedSize, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        var size = rect.size
        
        if let currentLineSpacing = lineSpacing {
            let spacing = size.height - font.lineHeight
            if spacing <= currentLineSpacing && spacing > 0 {
                size = CGSize(width: size.width, height: font.lineHeight)
            }
        }
        
        return size
    }
    
    func boundingRect(with constrainedSize: CGSize, font: UIFont, lineSpacing: CGFloat? = nil, lines: Int) -> CGSize {
        if lines < 0 {
            return .zero
        }
        
        let size = boundingRect(with: constrainedSize, font: font, lineSpacing: lineSpacing)
        if lines == 0 {
            return size
        }
        
        let currentLineSpacing = (lineSpacing == nil) ? (font.lineHeight - font.pointSize) : lineSpacing!
        let maximumHeight = font.lineHeight * CGFloat(lines) + currentLineSpacing * CGFloat(lines - 1)
        if size.height >= maximumHeight {
            return CGSize(width: size.width, height: maximumHeight)
        }
        return size
    }
}

//extension Guru where Base == String {
//
//    typealias Handler = (String)->(String)
//
//    mutating func replace(with regularExpression: String, options: NSRegularExpression.Options = [.caseInsensitive], handler: Handler?) -> String {
//        do {
//            var string = self.base as NSString
//            let regularExpression = try NSRegularExpression(pattern: regularExpression, options: options)
//            let results = regularExpression.matches(in: self.base, options: [], range: NSMakeRange(0, (self.base as NSString).length))
//            results.reversed().forEach { (result) in
//                let substring = string.substring(with: result.range)
//                guard let replaceString = handler?(substring) else { return }
//                string = string.replacingCharacters(in: result.range, with: replaceString) as NSString
//            }
//            return string as String
//        } catch {
//            return self.base
//        }
//    }
//}

//extension Guru where Base == NSAttributedString {
//
//    func asyncHighlightedText(keyword: String, attributes: [NSAttributedString.Key: Any], result: @escaping (NSAttributedString)->()) {
//        DispatchQueue.global().async {
//            let attributedText = self.highlightedText(keyword: keyword, attributes: attributes)
//            DispatchQueue.main.async {
//                result(attributedText)
//            }
//        }
//    }
//
//    func highlightedText(keyword: String, attributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
//        if keyword.compare(self.base.string) == .orderedSame {
//            return self.base
//        } else {
//            let keywords = keyword.components(separatedBy: [" "])
//            let attributedText = NSMutableAttributedString(attributedString: self.base)
//            guard let rootRange = self.base.string.range(of: self.base.string) else { return attributedText }
//            keywords.forEach { (text) in
//                var occurance: Int = 0
//                var targetRange = Range(uncheckedBounds: (rootRange.lowerBound, rootRange.upperBound))
//                while let range = self.base.string.range(of: text, options: [.caseInsensitive], range: targetRange) {
//                    attributedText.addAttributes(attributes, range: NSRange(range, in: self.base.string))
//                    targetRange = Range(uncheckedBounds: (range.upperBound, rootRange.upperBound))
//                    occurance += 1
//                    if (occurance >= 3) { break }
//                }
//            }
//            return attributedText
//        }
//    }
//}


//extension Guru where Base == String {
//    
//    func asyncHighlightedText(keyword: String, attributes: [NSAttributedString.Key: Any], result: @escaping (NSAttributedString)->()) {
//        DispatchQueue.global().async {
//            let attributedText = self.highlightedText(keyword: keyword, attributes: attributes)
//            DispatchQueue.main.async {
//                result(attributedText)
//            }
//        }
//    }
//    
//    func highlightedText(keyword: String, attributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
//        if keyword.compare(self.base) == .orderedSame {
//            return NSAttributedString(string: self.base, attributes: attributes)
//        } else {
//            let keywords = keyword.components(separatedBy: [" "])
//            let attributedText = NSMutableAttributedString(string: self.base)
//            guard let rootRange = self.base.range(of: self.base) else { return attributedText }
//            keywords.forEach { (text) in
//                var occurance: Int = 0
//                var targetRange = Range(uncheckedBounds: (rootRange.lowerBound, rootRange.upperBound))
//                while let range = self.base.range(of: text, options: [.caseInsensitive], range: targetRange) {
//                    attributedText.addAttributes(attributes, range: NSRange(range, in: self.base))
//                    targetRange = Range(uncheckedBounds: (range.upperBound, rootRange.upperBound))
//                    occurance += 1
//                    if (occurance >= 3) { break }
//                }
//            }
//            return attributedText
//        }
//    }
//}

extension Optional where Wrapped == String {
    
    func validate(rules: [String.ValidationRule]) -> String.ValidationRule? {
        switch self {
        case .some(let wrapped):
            return wrapped.validate(rules: rules)
        case .none:
            guard rules.contains(.notEmpty) else { return nil }
            return .notEmpty
        }
    }
}

extension String {
    
    enum ValidationRule: Hashable {
        
        case notEmpty // 非空
        case max(Int) // 长度上限
        case min(Int) // 长度下限
        case noSpecialCharacterAtPrefix // 开头不包含特殊字符
        case custom(String) // 自定义正则
        case notEqualTo(Set<String>) // 不包含于一个集合
        case characterSet(CharacterSet) // 不只有空壳
        
        static func ==(_ lhs: ValidationRule, _ rhs: ValidationRule) -> Bool {
            switch (lhs, rhs) {
            case (.notEmpty, .notEmpty):
                return true
            case (.max, .max), (.min, .min):
                return true
            case (.custom(let s1), .custom(let s2)):
                return s1 == s2
            case (.notEqualTo, .notEqualTo):
                return true
            case (.characterSet, .characterSet):
                return true
            default:
                return false
            }
        }
    }
    
    func validate(rules: [ValidationRule]) -> ValidationRule? {
        for i in 0..<rules.count {
            let rule = rules[i]
            switch rule {
            case .notEmpty:
                guard !self.isEmpty else { return .notEmpty }
            case .max(let count):
                guard self.count <= count else { return rule }
            case .min(let count):
                guard self.count >= count else { return rule }
            case .noSpecialCharacterAtPrefix:
                let pattern = "^[!@#$%^&*()_+\\-=\\[\\]{};':\"\\|,.<>\\/?]+"
                guard let expression = try? NSRegularExpression(pattern: pattern, options: []) else { return rule }
                // 开头包含特殊字符，抛出错误
                guard expression.firstMatch(in: self, options: [], range: NSMakeRange(0, (self as NSString).length)) == nil else { return rule }
            case .custom(let str):
                guard let expression = try? NSRegularExpression(pattern: str, options: []) else { return rule }
                // 不match正则就抛出错误
                guard expression.firstMatch(in: self, options: [], range: NSMakeRange(0, (self as NSString).length)) != nil else { return rule }
            case .notEqualTo(let sets):
                if sets.contains(self) { return rule }
            case .characterSet(let set):
                if trimmingCharacters(in: set).isEmpty { return rule }
            }
        }
        return nil
    }
}

extension String {
    func mySubString(to index: Int) -> String {
        return String(self[..<self.index(self.startIndex, offsetBy: index)])
    }
    
    func mySubString(from index: Int) -> String {
        return String(self[self.index(self.startIndex, offsetBy: index)...])
    }
    /// add char at index
    mutating func addString(_ string: String, at index: Int) {
        guard count > index else {
            return
        }
        let ind = self.index(self.startIndex, offsetBy: index)
        insert(contentsOf: string, at: ind)
    }
}

extension String {
    func firstCharacterUpperCase() -> String? {
        guard !isEmpty else { return nil }
        let lowerCasedString = self.lowercased()
        return lowerCasedString.replacingCharacters(in: lowerCasedString.startIndex...lowerCasedString.startIndex, with: String(lowerCasedString[lowerCasedString.startIndex]).uppercased())
    }
}


extension Optional where Wrapped == String {
    
    var isValid: Bool {
        guard let string = self else {
            return false
        }
        return !string.isEmpty
    }
}

extension String {
    
    func jsonObject() -> [String: Any]? {

        guard let data = data(using: .utf8) else {
            return nil
        }
        guard let jsonData = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any] else {
            return nil
        }
        return jsonData
    }
}

extension String {
    
    func copyToPasteboardWithHaptic() {
        copyToPasteboard()
        HapticFeedback.Impact.success()
    }

}
