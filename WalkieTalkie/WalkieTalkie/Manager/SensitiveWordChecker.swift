//
//  SensitiveWordChecker.swift
//  Runner
//
//  Created by 袁仕崇 on 2020/3/9.
//  Copyright © 2020 Guru. All rights reserved.
//

import Foundation
import RxSwift
import SwiftyUserDefaults

class SensitiveWordChecker {
    
    private class Node {
        var chirldren = [String: Node]()
        var word = ""
    }
    
    typealias FilterResult = (isContain: Bool, filteredText: String)
    
    private lazy var root: Node = {
        return creatDFAModel()
    }()
    
    static let `default` = SensitiveWordChecker()
    
    private static let replaceCharMaxLength = 3
    
    init() {
        //read from cache
        _ = Request.seneitiveWords()
            .subscribe(onSuccess: { words in
                cdPrint("seneitiveWords: \(words)")
                Defaults[\.sensitiveWords] = words
            })
    }
    
    static func filter(text: String, with replaceChar: String = "*") -> String {
        return self.default.filter(text: text, with: replaceChar).filteredText
    }
    static func firstSensitiveWord(in text: String?) -> String? {
        guard let text = text else {
            return nil
        }
        return self.default.firstSensitiveWord(in: text)
    }
    
    func firstSensitiveWord(in text: String) -> String? {
        let lowercasedText = text.lowercased()
        let filterdStr = text
        var isCotain = false
        var i = 0
        while i < lowercasedText.count {
            var p = root
            var j = i
            while j < text.count, p.chirldren[lowercasedText[j]] != nil {
                p = p.chirldren[lowercasedText[j]]!
                j += 1
            }
            let substring = lowercasedText.subString(from: i, to: (j - 1))
            var isLastOrFirstChar: Bool {
                var lastIndex: Int {
                    if i - 1 > 0 {
                        return i - 1 //
                    }
                    return 0
                }
                var nextIndex: Int {
                    if j >= lowercasedText.count {
                        return lowercasedText.count - 1
                    } else {
                        return j
                    }
                }
                let char = lowercasedText[j]
                let previousChar = lowercasedText[lastIndex] //当前字符的上一个字符
                return (char == " " || nextIndex == (lowercasedText.count - 1)) && (previousChar == " " || lastIndex == 0)
            }
            if isLastOrFirstChar,
                p.word.lowercased() == substring,
                !p.word.isEmpty {
                isCotain = true
                let start = filterdStr.index(filterdStr.startIndex, offsetBy: i);
                let end = filterdStr.index(filterdStr.startIndex, offsetBy: j - 1);
                let word = filterdStr[start...end]
                return String(word)
            } else {
                i += 1
            }
        }
        return nil
    }
    
    func filter(text: String, with replaceChar: String = "*") -> FilterResult {
        var lowercasedText = text.lowercased()
        var filterdStr = text
        var isCotain = false
        var i = 0
        while i < lowercasedText.count {
            var p = root
            var j = i
            while j < text.count, p.chirldren[lowercasedText[j]] != nil {
                p = p.chirldren[lowercasedText[j]]!
                j += 1
            }
            let substring = lowercasedText.subString(from: i, to: (j - 1))
            var isLastChar: Bool {
                
                var lastIndex: Int {
                    if i - 1 > 0 {
                        return i - 1 //
                    }
                    return 0
                }
                var nextIndex: Int {
                    if j >= lowercasedText.count {
                        return lowercasedText.count - 1
                    } else {
                        return j
                    }
                }
                let char = lowercasedText[j]
                let previousChar = lowercasedText[lastIndex] //当前字符的上一个字符
                return (char == " " || nextIndex == (lowercasedText.count - 1)) && (previousChar == " " || lastIndex == 0)
            }
            
            if isLastChar,
                p.word.lowercased() == substring,
                !p.word.isEmpty {
                isCotain = true
                let start = filterdStr.index(filterdStr.startIndex, offsetBy: i);
                let end = filterdStr.index(filterdStr.startIndex, offsetBy: j - 1);
                filterdStr = filterdStr.replacingCharacters(in: start...end, with: "***")
                lowercasedText = filterdStr
                i = i + 3
            } else {
                i += 1
            }
        }
        return (isCotain, filterdStr)
    }
    
    /// 初始化敏感词库，构建 DFA 算法模型
    private func creatDFAModel() -> Node {
        let root = Node()
        let words = getSentiveWords()
        words.forEach { add($0, toRootNode: root) }
        return root
    }
    
    /// 添加敏感词到模型中
    /// - Parameter word: 敏感词
    /// - Parameter root: DFA 模型
    private func add(_ word: String, toRootNode root: Node) {
        var node = root
        for letter in word {
            let letterStr = String(letter)
            if node.chirldren[letterStr] == nil {
                node.chirldren[letterStr] = Node()
            }
            node = node.chirldren[letterStr]!
        }
        node.word = word
    }
    
    private func getSentiveWords() -> [String] {
        return Defaults[\.sensitiveWords] ?? []
    }
}


extension String {
    
    /// 按照下标截取字符串
    /// - Parameter from: 起始下标，从 0 开始，传入的不合法则默认为返回 " "
    /// - Parameter to: 结束下标，传入的不合法默认为返回 " "
    func subString(from: Int, to: Int) -> String {
        guard from >= 0,
            from < count,
            to >= 0,
            to < count,
            from <= to else {
                return ""
        }
        let s = index(startIndex, offsetBy: from)
        let e = index(startIndex, offsetBy: to)
        return String(self[s...e])
    }
    
    subscript (index: Int) -> String {
        return subString(from: index, to: index)
    }
}

extension RangeExpression where Bound == String.Index {
    func nsRange<S: StringProtocol>(in string: S) -> NSRange { .init(self, in: string) }
}

extension StringProtocol {
    func nsRange<S: StringProtocol>(of string: S, options: String.CompareOptions = [], range: Range<Index>? = nil, locale: Locale? = nil) -> NSRange? {
        self.range(of: string,
                   options: options,
                   range: range ?? startIndex..<endIndex,
                   locale: locale ?? .current)?
            .nsRange(in: self)
    }
    func nsRanges<S: StringProtocol>(of string: S, options: String.CompareOptions = [], range: Range<Index>? = nil, locale: Locale? = nil) -> [NSRange] {
        var start = range?.lowerBound ?? startIndex
        let end = range?.upperBound ?? endIndex
        var ranges: [NSRange] = []
        while start < end,
            let range = self.range(of: string,
                                   options: options,
                                   range: start..<end,
                                   locale: locale ?? .current) {
            ranges.append(range.nsRange(in: self))
            start = range.lowerBound < range.upperBound ? range.upperBound :
            index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return ranges
    }
}

